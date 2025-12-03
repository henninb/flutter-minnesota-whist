import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import '../logic/deal_utils.dart';
import '../logic/minnesota_whist_bidding_engine.dart';
import '../logic/bidding_ai.dart';
import '../logic/trick_engine.dart';
import '../logic/play_ai.dart';
import '../logic/trump_rules.dart';
import '../logic/minnesota_whist_scorer.dart';
import '../logic/claim_analyzer.dart';
import '../../services/game_persistence.dart';
import 'game_state.dart';

/// Game engine for Minnesota Whist
///
/// Orchestrates the entire game flow:
/// 1. Setup & Deal
/// 2. Bidding (simultaneous card placement - black=high, red=low)
/// 3. Trick Play (13 tricks)
/// 4. Scoring
/// 5. Repeat or Game Over (first to 13 points)
class GameEngine extends ChangeNotifier {
  GameEngine({GamePersistence? persistence})
      : _persistence = persistence,
        _state = const GameState();

  // ignore: unused_field
  final GamePersistence? _persistence;
  GameState _state;

  GameState get state => _state;

  /// Get the current winner of the trick in progress
  /// Returns null if no trick is in progress or trick is empty
  Position? getCurrentTrickWinner() {
    if (_state.currentTrick == null || _state.currentTrick!.isEmpty) {
      return null;
    }

    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);
    return trickEngine.getCurrentWinner(_state.currentTrick!);
  }

  // Timers for AI delays
  Timer? _aiTimer;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // GAME LIFECYCLE
  // ============================================================================

  /// Initialize game (load saved state if available)
  Future<void> initialize() async {
    // For now, just start fresh
    // TODO: Implement state persistence
    notifyListeners();
  }

  /// Start a new game
  void startNewGame() {
    _updateState(
      const GameState(
        gameStarted: true,
        currentPhase: GamePhase.setup,
        gameStatus: 'Tap Cut for Deal to determine dealer',
      ),
    );
    // Immediately show the cut for deal deck
    cutForDeal();
  }

  /// Perform cut for deal - show spread deck for player to tap
  void cutForDeal() {
    final deck = createDeck();

    // Initialize the spread deck and reset selection state
    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.cutForDeal,
        cutDeck: deck,
        cutCards: {},
        playerHasSelectedCutCard: false,
        gameStatus: 'Tap the deck to cut for dealer',
      ),
    );
  }

  /// Player selects a card from the spread deck
  void selectCutCard(int index) {
    if (_state.playerHasSelectedCutCard) {
      return; // Already selected
    }

    if (index < 0 || index >= _state.cutDeck.length) {
      return; // Invalid index
    }

    final deck = _state.cutDeck;
    final random = Random();

    // Player (South) selects their card
    final playerCard = deck[index];
    final cutCards = <Position, PlayingCard>{
      Position.south: playerCard,
    };
    final usedIndices = <int>{index};

    // AI players automatically select random cards (different from player's card)
    for (final position in [Position.north, Position.east, Position.west]) {
      int aiIndex;
      do {
        aiIndex = random.nextInt(deck.length);
      } while (usedIndices.contains(aiIndex));

      usedIndices.add(aiIndex);
      cutCards[position] = deck[aiIndex];
    }

    // Determine winner - highest card wins (Ace high, no joker)
    Position? highestPosition;
    int highestRank = -1;
    int highestSuit = 999; // Lower is better (spades=0 is best)

    for (final entry in cutCards.entries) {
      final card = entry.value;
      final position = entry.key;

      final rank = card.rank.index;
      final suit = card.suit.index;

      // Compare: higher rank wins, or if same rank, lower suit index wins (spades=0 best)
      if (rank > highestRank || (rank == highestRank && suit < highestSuit)) {
        highestRank = rank;
        highestSuit = suit;
        highestPosition = position;
      }
    }

    // Update state with results
    if (highestPosition != null) {
      final winnerName = _state.getName(highestPosition);
      final winningCard = cutCards[highestPosition]!;
      _updateState(
        _state.copyWith(
          cutCards: cutCards,
          playerHasSelectedCutCard: true,
          dealer: highestPosition,
          gameStatus:
              '$winnerName wins with ${winningCard.label} and will deal. Tap Deal to start.',
        ),
      );
    }
  }

  /// Deal cards
  void dealCards() {
    final deck = createDeck();
    final dealResult = dealHand(deck: deck, dealer: _state.dealer);

    // DEBUG: Log the deal
    _debugLog(
      '\n========== DEAL CARDS (Hand #${_state.handNumber + 1}) ==========',
    );
    _debugLog('Dealer: ${_state.dealer.name}');
    _debugLog('Deck size: ${deck.length}');

    // Log each hand
    for (final position in Position.values) {
      final hand = dealResult.hands[position]!;
      _debugLog('${position.name}: ${hand.length} cards');
    }

    // Count total cards
    final totalCards =
        dealResult.hands.values.fold(0, (sum, hand) => sum + hand.length);
    _debugLog('Total cards dealt: $totalCards (should be 52)');
    _debugLog('========================================\n');

    // Sort player's hand by suit for easier viewing
    final sortedPlayerHand = sortHandBySuit(dealResult.hands[Position.south]!);

    _debugLog('⏱️ [TIMING] About to update state with dealt cards...');

    // Update state with dealt cards and go directly to bidding
    _updateState(
      _state.copyWith(
        playerHand: sortedPlayerHand,
        partnerHand: dealResult.hands[Position.north],
        opponentEastHand: dealResult.hands[Position.east],
        opponentWestHand: dealResult.hands[Position.west],
        handNumber: _state.handNumber + 1,
        cutCards: {}, // Clear cut cards after dealing
      ),
    );

    _debugLog('⏱️ [TIMING] State updated, calling _startBidding()...');

    // Start bidding immediately (will set phase to bidding)
    _startBidding();

    _debugLog('⏱️ [TIMING] _startBidding() completed');
  }

  // ============================================================================
  // TEST HANDS (Debug/Testing Support)
  // ============================================================================

  /// Apply a test hand to the South player
  ///
  /// This is a debug/testing feature that replaces the player's current hand
  /// with a specific set of cards. The remaining cards are redistributed to
  /// other players.
  ///
  /// Can only be called during the bidding phase before the player has bid.
  void applyTestHand(List<PlayingCard> testHand) {
    if (_state.currentPhase != GamePhase.bidding) {
      _debugLog('⚠️ Cannot apply test hand - not in bidding phase');
      return;
    }

    if (testHand.length != 13) {
      _debugLog(
        '⚠️ Cannot apply test hand - must have exactly 13 cards (got ${testHand.length})',
      );
      return;
    }

    _debugLog('\n========== APPLYING TEST HAND ==========');
    _debugLog('Test hand: ${testHand.map((c) => c.label).join(', ')}');

    // Get all cards from all hands (52 total: 4 hands * 13)
    final allCards = <PlayingCard>[
      ..._state.playerHand,
      ..._state.partnerHand,
      ..._state.opponentEastHand,
      ..._state.opponentWestHand,
    ];

    _debugLog('Total cards before redistribution: ${allCards.length}');

    // VALIDATION: Verify test hand cards exist in the current deal
    final deck = createDeck();
    for (final testCard in testHand) {
      final existsInDeck = deck.any(
        (deckCard) => deckCard.rank == testCard.rank && deckCard.suit == testCard.suit,
      );
      if (!existsInDeck) {
        _debugLog('⚠️ ERROR: Test hand contains invalid card: ${testCard.label}');
        _debugLog('⚠️ Test hand rejected - all cards must be from standard deck');
        return;
      }
    }

    // VALIDATION: Check for duplicate cards in test hand
    final testHandSet = <String>{};
    for (final card in testHand) {
      final key = '${card.rank.name}_${card.suit.name}';
      if (testHandSet.contains(key)) {
        _debugLog('⚠️ ERROR: Test hand contains duplicate card: ${card.label}');
        _debugLog('⚠️ Test hand rejected - no duplicates allowed');
        return;
      }
      testHandSet.add(key);
    }

    // Remove test hand cards from available pool
    final availableCards = <PlayingCard>[];
    for (final card in allCards) {
      // Check if this card is in the test hand
      final isInTestHand = testHand.any(
        (testCard) => testCard.rank == card.rank && testCard.suit == card.suit,
      );
      if (!isInTestHand) {
        availableCards.add(card);
      }
    }

    _debugLog('Available cards after removing test hand: ${availableCards.length} (should be 39)');

    // Shuffle available cards
    availableCards.shuffle(Random());

    // Distribute to other players (13 cards each)
    final newPartnerHand = availableCards.sublist(0, 13);
    final newEastHand = availableCards.sublist(13, 26);
    final newWestHand = availableCards.sublist(26, 39);

    // Sort hands
    final sortedTestHand = sortHandBySuit(testHand);

    _debugLog('✅ Test hand applied successfully');
    _debugLog('========================================\n');

    // Update state with new hands
    _updateState(
      _state.copyWith(
        playerHand: sortedTestHand,
        partnerHand: newPartnerHand,
        opponentEastHand: newEastHand,
        opponentWestHand: newWestHand,
        gameStatus: 'Test hand applied - place your bid card',
      ),
    );
  }

  // ============================================================================
  // BIDDING PHASE
  // ============================================================================

  void _startBidding() {
    _debugLog('⏱️ [TIMING] _startBidding() called');
    _debugLog('Minnesota Whist: All players place bid cards simultaneously');

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.bidding,
        isBiddingPhase: true,
        bidHistory: [],
        gameStatus: 'Place your bid card (Black=High, Red=Low)',
        clearCurrentBidder: true,
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
        clearHandType: true,
      ),
    );

    _debugLog('⏱️ [TIMING] State updated to bidding phase');

    // Show bidding dialog for player to select card
    _updateState(_state.copyWith(showBiddingDialog: true));
    _debugLog('⏱️ [TIMING] showBiddingDialog set to true');
  }

  /// Player selects a bid card (Minnesota Whist - step 1)
  void selectBidCard(PlayingCard card) {
    _updateState(_state.copyWith(pendingBidCard: card));
    _debugLog('[BID CARD SELECTED] ${card.label}');
  }

  /// Player confirms their bid card selection (Minnesota Whist - step 2)
  void confirmBid() {
    if (_state.pendingBidCard == null) {
      _debugLog('[BID CONFIRMATION FAILED] No card selected');
      return;
    }

    submitPlayerBidCard(_state.pendingBidCard!);
  }

  /// Player submits a bid card (Minnesota Whist)
  void submitPlayerBidCard(PlayingCard bidCard) {
    final biddingEngine = MinnesotaWhistBiddingEngine(dealer: _state.dealer);

    // Validate bid card
    final validation = biddingEngine.validateBidCard(
      card: bidCard,
      bidder: Position.south,
      currentBids: _state.bidHistory,
    );

    if (!validation.isValid) {
      _debugLog('\n[BID CARD VALIDATION FAILED]');
      _debugLog('Player: ${_state.getName(Position.south)}');
      _debugLog('Attempted card: ${bidCard.label}');
      _debugLog('Reason: ${validation.errorMessage ?? 'Invalid bid card'}');

      _updateState(
        _state.copyWith(
          gameStatus: validation.errorMessage ?? 'Invalid bid card',
        ),
      );
      return;
    }

    // Create bid from card
    final bid = biddingEngine.createBidFromCard(bidCard, Position.south);
    final entry = BidEntry(bidder: Position.south, bid: bid);

    _debugLog('\n[PLAYER BID]');
    _debugLog('Card: ${bidCard.label}');
    _debugLog('Bid type: ${bid.bidType == BidType.high ? "HIGH (black)" : "LOW (red)"}');

    _addBidEntry(entry);
    _updateState(_state.copyWith(
      showBiddingDialog: false,
      pendingBidCard: null, // Clear the pending card
    ));

    // Collect AI bids simultaneously
    _collectAIBids();
  }

  /// Collect AI bid cards (Minnesota Whist - simultaneous bidding)
  void _collectAIBids() {
    _debugLog('\n[AI BIDDING] Collecting AI bid cards...');

    final biddingEngine = MinnesotaWhistBiddingEngine(dealer: _state.dealer);

    // AI players place their bid cards
    for (final position in [Position.north, Position.east, Position.west]) {
      final hand = _state.getHand(position);

      // AI chooses a bid card (will be implemented in bidding_ai.dart)
      // For now, use simple logic: choose lowest card in hand
      // TODO: Implement proper Minnesota Whist bidding AI
      final bidCard = BiddingAI.chooseBidCard(
        hand: hand,
        position: position,
      );

      final bid = biddingEngine.createBidFromCard(bidCard, position);
      final entry = BidEntry(bidder: position, bid: bid);

      _debugLog('[AI BID] ${_state.getName(position)}: ${bidCard.label} (${bid.bidType == BidType.high ? "HIGH" : "LOW"})');

      _addBidEntry(entry);
    }

    // All bids collected - determine winner
    _checkAuctionComplete();
  }

  void _addBidEntry(BidEntry entry) {
    final newHistory = [..._state.bidHistory, entry];

    _updateState(
      _state.copyWith(
        bidHistory: newHistory,
        pendingBidEntry: entry,
        gameStatus: '${_state.getName(entry.bidder)} placed bid card',
        clearAiThinkingPosition: true,
      ),
    );
  }

  void _checkAuctionComplete() {
    final biddingEngine = MinnesotaWhistBiddingEngine(dealer: _state.dealer);

    if (!biddingEngine.isComplete(_state.bidHistory)) {
      _debugLog('[AUCTION] Not complete - waiting for more bids (${_state.bidHistory.length}/4)');
      return;
    }

    // Auction complete - determine result
    final result = biddingEngine.determineWinner(_state.bidHistory);

    _debugLog('[AUCTION] Complete - determining winner');

    if (result.status == AuctionStatus.won) {
      _updateState(
        _state.copyWith(
          isBiddingPhase: false,
          winningBid: result.winningBid,
          contractor: result.winner,
          handType: result.handType,
          allBidLow: result.allBidLow,
          gameStatus: result.message,
          clearCurrentBidder: true,
        ),
      );

      // Skip kitty exchange - go directly to play in Minnesota Whist
      Future.delayed(const Duration(milliseconds: 1500), _startPlay);
    }
  }

  // ============================================================================
  // Minnesota Whist - No kitty exchange phase (removed)

  // ============================================================================
  // PLAY PHASE
  // ============================================================================

  void _startPlay() {
    // Minnesota Whist: No trump in standard version
    const trumpSuit = null;
    final leader = _state.contractor!; // Contractor (grander) leads

    // DEBUG: Verify all hands before play starts
    _debugLog('\n========== START PLAY PHASE ==========');
    _debugLog('Contractor: ${_state.getName(leader)} (${leader.name})');
    _debugLog('Hand type: ${_state.handType == BidType.high ? "HIGH (Grand)" : "LOW (Nula)"}');
    _debugLog('All bid low: ${_state.allBidLow}');
    _debugLog('\nHand verification:');
    var totalCards = 0;
    for (final position in Position.values) {
      final hand = _state.getHand(position);
      totalCards += hand.length;
      _debugLog('${_state.getName(position)}: ${hand.length} cards');
    }
    _debugLog('Total cards: $totalCards (should be 52)');
    if (totalCards != 52) {
      _debugLog('⚠️ WARNING: Card count mismatch!');
    }
    _debugLog('========================================\n');

    // Sort player's hand by suit
    final sortedPlayerHand = sortHandBySuit(_state.playerHand);

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.play,
        isPlayPhase: true,
        trumpSuit: trumpSuit,
        playerHand: sortedPlayerHand,
        currentTrick: Trick(plays: [], leader: leader, trumpSuit: trumpSuit),
        completedTricks: [],
        tricksWonNS: 0,
        tricksWonEW: 0,
        currentPlayer: leader,
        gameStatus: '${_state.getName(leader)} leads',
        clearSelectedCardIndices: true,
      ),
    );

    // Update claim status at start of play
    _updateClaimStatus();

    // If AI leads, schedule AI play
    if (leader != Position.south) {
      _scheduleAIPlay();
    }
  }

  /// Player plays a card
  void playCard(int cardIndex) {
    if (_state.currentPlayer != Position.south) return;
    if (_state.currentTrick == null) return;

    final card = _state.playerHand[cardIndex];
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // DEBUG: Log card play
    _debugLog(
      '[PLAY] ${_state.getName(Position.south)} plays ${card.label} (${card.suit.name}) (hand size before: ${_state.playerHand.length})',
    );

    // Play the card
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: Position.south,
      playerHand: _state.playerHand,
    );

    if (result.status == TrickStatus.error) {
      _updateState(_state.copyWith(gameStatus: result.message));
      return;
    }

    // Remove card from hand
    final newHand = List<PlayingCard>.from(_state.playerHand);
    newHand.removeAt(cardIndex);

    _debugLog(
      '[PLAY] ${_state.getName(Position.south)} hand size after: ${newHand.length}',
    );

    _updateState(
      _state.copyWith(
        playerHand: newHand,
        currentTrick: result.trick,
        gameStatus: result.message,
        clearSelectedCardIndices: true,
      ),
    );

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      // Advance to next player
      _advanceToNextPlayer();
    }
  }

  void _advanceToNextPlayer() {
    final nextPlayer = _state.currentPlayer!.next;
    _updateState(
      _state.copyWith(
        currentPlayer: nextPlayer,
        gameStatus: '${_state.getName(nextPlayer)}\'s turn',
      ),
    );

    if (nextPlayer != Position.south) {
      _scheduleAIPlay();
    }
  }

  /// Update the claim status - check if player can claim all remaining tricks
  void _updateClaimStatus() {
    // Only during play phase
    if (!_state.isPlayPhase || _state.playerHand.isEmpty) {
      if (_state.canPlayerClaimRemainingTricks) {
        _updateState(_state.copyWith(canPlayerClaimRemainingTricks: false));
      }
      return;
    }

    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final analyzer = ClaimAnalyzer(
      playerHand: _state.playerHand,
      otherHands: {
        Position.north: _state.partnerHand,
        Position.east: _state.opponentEastHand,
        Position.west: _state.opponentWestHand,
      },
      trumpRules: trumpRules,
      completedTricks: _state.completedTricks,
      currentTrick: _state.currentTrick,
      currentPlayer: _state.currentPlayer,
    );

    final canClaim = analyzer.canClaimRemainingTricks();

    if (canClaim != _state.canPlayerClaimRemainingTricks) {
      _updateState(_state.copyWith(canPlayerClaimRemainingTricks: canClaim));
      if (canClaim) {
        _debugLog('✨ Player can now claim all remaining tricks!');
      }
    }
  }

  /// Claim remaining tricks - auto-play through them with animations
  Future<void> claimRemainingTricks() async {
    if (!_state.canPlayerClaimRemainingTricks) {
      _updateState(
        _state.copyWith(
          gameStatus: 'Cannot claim - not guaranteed to win all tricks',
        ),
      );
      return;
    }

    // Validate game state before starting claim
    final totalCardsRemaining =
        _state.playerHand.length +
        _state.partnerHand.length +
        _state.opponentEastHand.length +
        _state.opponentWestHand.length;

    final tricksRemaining = 13 - _state.completedTricks.length;
    final currentTrickCards = _state.currentTrick?.plays.length ?? 0;
    final cardsNeeded = (tricksRemaining * 4) - currentTrickCards;

    if (totalCardsRemaining != cardsNeeded) {
      _debugLog('⚠️ ERROR: Invalid game state before claim');
      _debugLog('  Total cards remaining: $totalCardsRemaining');
      _debugLog('  Cards needed: $cardsNeeded');
      _debugLog('  Tricks remaining: $tricksRemaining');
      _debugLog('  Current trick cards: $currentTrickCards');
      _updateState(
        _state.copyWith(
          gameStatus: 'Cannot claim - invalid game state detected',
          canPlayerClaimRemainingTricks: false,
        ),
      );
      return;
    }

    // Immediately hide the claim button to prevent multiple clicks
    _updateState(_state.copyWith(canPlayerClaimRemainingTricks: false));

    _debugLog('\n========== CLAIMING REMAINING TRICKS ==========');
    _debugLog('Player claims they will win all remaining tricks');
    _debugLog('Cards in hand: ${_state.playerHand.length}');
    _debugLog('Starting from trick ${_state.completedTricks.length + 1}');
    _debugLog('Validated: $totalCardsRemaining cards for $cardsNeeded slots');

    // Safety: track iterations to prevent infinite loops
    int outerLoopIterations = 0;
    const maxOuterIterations = 50; // Should never need more than ~15

    // Auto-play through remaining tricks until we have 10
    while (_state.completedTricks.length < 13) {
      outerLoopIterations++;
      if (outerLoopIterations > maxOuterIterations) {
        _debugLog('⚠️ ERROR: Claim exceeded max iterations. Aborting.');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error during claim - please continue manually',
          ),
        );
        return;
      }

      // Safety check: ensure we still have cards to play
      final totalCardsRemaining =
          _state.playerHand.length +
          _state.partnerHand.length +
          _state.opponentEastHand.length +
          _state.opponentWestHand.length;

      if (totalCardsRemaining == 0 && _state.completedTricks.length < 13) {
        _debugLog(
            '⚠️ ERROR: No cards remaining but only ${_state.completedTricks.length} tricks completed',);
        _updateState(
          _state.copyWith(
            gameStatus: 'Error during claim - cards exhausted early',
          ),
        );
        return;
      }

      // If current trick is not complete, finish it
      if (_state.currentTrick != null && !_state.currentTrick!.isComplete) {
        final success = await _autoPlayCurrentTrick();
        if (!success) {
          _debugLog('⚠️ ERROR: Failed to complete trick during claim');
          _debugLog('⚠️ Re-enabling manual play for recovery');
          // Re-evaluate claim status to potentially re-enable button or allow manual play
          _updateClaimStatus();
          return;
        }
      } else if (_state.completedTricks.length < 13) {
        // Start a new trick
        // Determine who leads (winner of last trick or current leader)
        Position leader;
        if (_state.completedTricks.isEmpty) {
          leader = _state.currentPlayer ?? _state.contractor!;
        } else {
          // Get winner of last trick
          final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
          final trickEngine = TrickEngine(trumpRules: trumpRules);
          final winner = trickEngine.getCurrentWinner(_state.completedTricks.last);

          // Safety check: winner should never be null for a completed trick
          if (winner == null) {
            _debugLog('⚠️ ERROR: Cannot determine winner of last trick during claim');
            _debugLog('⚠️ Re-enabling manual play for recovery');
            _updateState(
              _state.copyWith(
                gameStatus: 'Error: Cannot determine trick winner - continue manually',
              ),
            );
            _updateClaimStatus();
            return;
          }

          leader = winner;
        }

        _debugLog(
            'Starting trick ${_state.completedTricks.length + 1}, ${_state.getName(leader)} leads',);

        _updateState(
          _state.copyWith(
            currentTrick: Trick(
              plays: [],
              leader: leader,
              trumpSuit: _state.trumpSuit,
            ),
            currentPlayer: leader,
          ),
        );

        final success = await _autoPlayCurrentTrick();
        if (!success) {
          _debugLog('⚠️ ERROR: Failed to complete trick during claim');
          _debugLog('⚠️ Re-enabling manual play for recovery');
          // Re-evaluate claim status to potentially re-enable button or allow manual play
          _updateClaimStatus();
          return;
        }
      }
    }

    _debugLog('✅ Claim complete - all 10 tricks played');
    _debugLog('===============================================\n');
  }

  /// Auto-play the current trick (called during claim)
  /// Returns true if successful, false if error occurred
  Future<bool> _autoPlayCurrentTrick() async {
    // DEBUG: Log hand sizes at start of trick
    _debugLog(
        '  Hand sizes: South=${_state.playerHand.length}, North=${_state.partnerHand.length}, '
        'East=${_state.opponentEastHand.length}, West=${_state.opponentWestHand.length}');

    // Safety: track iterations to prevent infinite loops within a trick
    int innerLoopIterations = 0;
    const maxInnerIterations = 10; // Should only need 4 (one per player)

    while (_state.currentTrick != null && !_state.currentTrick!.isComplete) {
      innerLoopIterations++;
      if (innerLoopIterations > maxInnerIterations) {
        _debugLog('⚠️ ERROR: Trick auto-play exceeded max iterations');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error during trick auto-play',
          ),
        );
        return false;
      }

      // Safety: check current player is valid
      if (_state.currentPlayer == null) {
        _debugLog('⚠️ ERROR: Current player is null during auto-play');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error: Invalid game state during claim',
          ),
        );
        return false;
      }

      final position = _state.currentPlayer!;
      final hand = _state.getHand(position);

      // Safety: check hand is not empty
      if (hand.isEmpty) {
        _debugLog(
            '⚠️ ERROR: ${_state.getName(position)} has no cards but trick not complete',);
        _updateState(
          _state.copyWith(
            gameStatus: 'Error: Player has no cards during claim',
          ),
        );
        return false;
      }

      final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
      final trickEngine = TrickEngine(trumpRules: trumpRules);

      // Choose card to play
      final card = PlayAI.chooseCard(
        hand: hand,
        currentTrick: _state.currentTrick!,
        trumpRules: trumpRules,
        position: position,
        partner: position.partner,
        trickEngine: trickEngine,
      );

      _debugLog(
          '  ${_state.getName(position)} plays ${card.label} (${hand.length} cards in hand)',);

      // Play the card
      final result = trickEngine.playCard(
        currentTrick: _state.currentTrick!,
        card: card,
        player: position,
        playerHand: hand,
      );

      // Safety: check for play errors
      if (result.status == TrickStatus.error) {
        _debugLog('⚠️ ERROR: ${result.message}');
        _updateState(
          _state.copyWith(
            gameStatus: 'Error playing card: ${result.message}',
          ),
        );
        return false;
      }

      // Remove card from hand
      final newHand = List<PlayingCard>.from(hand);
      final wasRemoved = newHand.remove(card);

      // Safety: verify card was actually in the hand
      if (!wasRemoved) {
        _debugLog(
            '⚠️ ERROR: Card ${card.label} not found in ${_state.getName(position)} hand',);
        _updateState(
          _state.copyWith(
            gameStatus: 'Error: Card not found in hand',
          ),
        );
        return false;
      }

      // Update the appropriate hand
      switch (position) {
        case Position.north:
          _updateState(_state.copyWith(partnerHand: newHand));
          break;
        case Position.east:
          _updateState(_state.copyWith(opponentEastHand: newHand));
          break;
        case Position.west:
          _updateState(_state.copyWith(opponentWestHand: newHand));
          break;
        case Position.south:
          _updateState(_state.copyWith(playerHand: newHand));
          break;
      }

      _updateState(
        _state.copyWith(
          currentTrick: result.trick,
          gameStatus:
              'Auto-playing: ${_state.getName(position)} plays ${card.label}',
        ),
      );

      // Brief delay for animation
      await Future.delayed(const Duration(milliseconds: 400));

      if (result.status == TrickStatus.complete) {
        // Trick complete - update state
        if (result.winner == null) {
          _debugLog('⚠️ ERROR: Trick complete but winner is null');
          _updateState(
            _state.copyWith(
              gameStatus: 'Error: Cannot determine trick winner',
            ),
          );
          return false;
        }

        final winner = result.winner!;
        final newCompleted = [..._state.completedTricks, result.trick];

        _debugLog('  Trick ${newCompleted.length} won by ${_state.getName(winner)}');
        _debugLog(
            '  Hand sizes after trick: South=${_state.playerHand.length}, North=${_state.partnerHand.length}, '
            'East=${_state.opponentEastHand.length}, West=${_state.opponentWestHand.length}');

        // Safety: verify we don't exceed 10 tricks
        if (newCompleted.length > 10) {
          _debugLog('⚠️ ERROR: Exceeded 10 tricks!');
          _updateState(
            _state.copyWith(
              gameStatus: 'Error: Too many tricks completed',
            ),
          );
          return false;
        }

        final winnerTeam = winner.team;
        var newTricksNS = _state.tricksWonNS;
        var newTricksEW = _state.tricksWonEW;

        if (winnerTeam == Team.northSouth) {
          newTricksNS++;
        } else {
          newTricksEW++;
        }

        _updateState(
          _state.copyWith(
            completedTricks: newCompleted,
            tricksWonNS: newTricksNS,
            tricksWonEW: newTricksEW,
            gameStatus: '${_state.getName(winner)} wins trick',
          ),
        );

        // Delay before next trick
        await Future.delayed(const Duration(milliseconds: 600));

        // Check if all tricks complete
        if (newCompleted.length == 13) {
          _debugLog('All 13 tricks complete - scoring hand');
          _verifyAllCardsUnique(newCompleted);
          await Future.delayed(const Duration(milliseconds: 1000));
          _scoreHand();
          return true;
        }

        // Safety: Check if winner has cards before starting next trick
        final winnerHand = _state.getHand(winner);
        if (winnerHand.isEmpty) {
          _debugLog(
              '⚠️ ERROR: Trick winner ${_state.getName(winner)} has no cards to lead next trick',);
          _updateState(
            _state.copyWith(
              gameStatus:
                  'Error: Trick winner has no cards - game state corrupted',
            ),
          );
          return false;
        }

        // Start next trick with winner leading
        _updateState(
          _state.copyWith(
            currentTrick: Trick(
              plays: [],
              leader: winner,
              trumpSuit: _state.trumpSuit,
            ),
            currentPlayer: winner,
          ),
        );

        // Exit this trick's loop - outer loop will call us again for next trick
        return true;
      } else {
        // Advance to next player
        _updateState(
          _state.copyWith(
            currentPlayer: _state.currentPlayer!.next,
          ),
        );
      }
    }

    // Loop exited normally (trick complete)
    return true;
  }

  void _scheduleAIPlay() {
    _updateState(_state.copyWith(aiThinkingPosition: _state.currentPlayer));

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 600), _executeAIPlay);
  }

  void _executeAIPlay() {
    final position = _state.currentPlayer;
    if (position == null || position == Position.south) return;
    if (_state.currentTrick == null) return;

    final hand = _state.getHand(position);
    final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
    final trickEngine = TrickEngine(trumpRules: trumpRules);

    // DEBUG: Log hand size before
    _debugLog(
      '[PLAY] ${_state.getName(position)} hand size before: ${hand.length}',
    );

    // AI chooses card
    final card = PlayAI.chooseCard(
      hand: hand,
      currentTrick: _state.currentTrick!,
      trumpRules: trumpRules,
      position: position,
      partner: position.partner,
      trickEngine: trickEngine,
    );

    // DEBUG: Log card play
    final suitInfo = '(${card.suit.name})';
    _debugLog(
      '[PLAY] ${_state.getName(position)} plays ${card.label} $suitInfo',
    );

    // Play the card
    final result = trickEngine.playCard(
      currentTrick: _state.currentTrick!,
      card: card,
      player: position,
      playerHand: hand,
    );

    // Remove card from hand
    final newHand = List<PlayingCard>.from(hand);
    newHand.remove(card);

    _debugLog(
      '[PLAY] ${_state.getName(position)} hand size after: ${newHand.length}',
    );

    switch (position) {
      case Position.north:
        _updateState(_state.copyWith(partnerHand: newHand));
        break;
      case Position.east:
        _updateState(_state.copyWith(opponentEastHand: newHand));
        break;
      case Position.west:
        _updateState(_state.copyWith(opponentWestHand: newHand));
        break;
      case Position.south:
        break;
    }

    _updateState(
      _state.copyWith(
        currentTrick: result.trick,
        gameStatus: result.message,
        clearAiThinkingPosition: true,
      ),
    );

    if (result.status == TrickStatus.complete) {
      _handleTrickComplete(result.trick, result.winner!);
    } else {
      _advanceToNextPlayer();
    }
  }

  void _handleTrickComplete(Trick trick, Position winner) {
    // DEBUG: Log trick completion
    _debugLog(
      '\n---------- TRICK ${_state.completedTricks.length + 1} COMPLETE ----------',
    );
    _debugLog('Winner: ${_state.getName(winner)} (${winner.name})');
    final ledSuit = trick.ledSuit;
    if (ledSuit != null) {
      _debugLog('Led suit: ${ledSuit.name}');
    }
    _debugLog('Cards played:');
    for (final play in trick.plays) {
      final suitInfo = '(${play.card.suit.name})';
      _debugLog(
        '  ${_state.getName(play.player)}: ${play.card.label} $suitInfo',
      );
    }

    // Add trick to completed tricks
    final newCompleted = [..._state.completedTricks, trick];

    // Update tricks won
    final winnerTeam = winner.team;
    var newTricksNS = _state.tricksWonNS;
    var newTricksEW = _state.tricksWonEW;

    if (winnerTeam == Team.northSouth) {
      newTricksNS++;
    } else {
      newTricksEW++;
    }

    _debugLog('Team ${winnerTeam.name} wins trick');
    _debugLog('Score: N-S: $newTricksNS, E-W: $newTricksEW');
    _debugLog('${_state.getName(winner)} will lead next trick');
    _debugLog('----------------------------------------\n');

    _updateState(
      _state.copyWith(
        completedTricks: newCompleted,
        tricksWonNS: newTricksNS,
        tricksWonEW: newTricksEW,
        gameStatus: '${_state.getName(winner)} wins trick',
      ),
    );

    // Update claim status after trick completion
    _updateClaimStatus();

    // Check if all tricks played
    if (newCompleted.length == 13) {
      // DEBUG: Verify all cards are unique
      _verifyAllCardsUnique(newCompleted);

      // Last trick - give extra time to see the cards before scoring
      Future.delayed(const Duration(milliseconds: 3000), _scoreHand);
    } else {
      // Start next trick with winner leading
      Future.delayed(const Duration(milliseconds: 2500), () {
        _startNextTrick(winner);
      });
    }
  }

  /// Verify that all 40 cards played are unique (no duplicates)
  void _verifyAllCardsUnique(List<Trick> completedTricks) {
    _debugLog('\n========== VERIFYING ALL CARDS PLAYED ==========');

    // Collect all cards played
    final allCardsPlayed = <PlayingCard>[];
    for (final trick in completedTricks) {
      for (final play in trick.plays) {
        allCardsPlayed.add(play.card);
      }
    }

    _debugLog('Total cards played: ${allCardsPlayed.length} (should be 52)');

    // Check for duplicates
    final cardCounts = <String, int>{};
    final duplicates = <String, int>{};

    for (final card in allCardsPlayed) {
      final label = card.label;
      cardCounts[label] = (cardCounts[label] ?? 0) + 1;

      if (cardCounts[label]! > 1) {
        duplicates[label] = cardCounts[label]!;
      }
    }

    if (duplicates.isEmpty) {
      _debugLog('✅ All 40 cards are unique - no duplicates found!');
    } else {
      _debugLog('⚠️⚠️⚠️ DUPLICATE CARDS FOUND! ⚠️⚠️⚠️');
      for (final entry in duplicates.entries) {
        _debugLog('  ${entry.key} appeared ${entry.value} times');
      }

      // Show which tricks had the duplicates
      _debugLog('\nDetailed breakdown by trick:');
      for (int i = 0; i < completedTricks.length; i++) {
        final trick = completedTricks[i];
        _debugLog('Trick ${i + 1}:');
        for (final play in trick.plays) {
          final isDuplicate = duplicates.containsKey(play.card.label);
          _debugLog(
            '  ${_state.getName(play.player)}: ${play.card.label}${isDuplicate ? ' ⚠️ DUPLICATE' : ''}',
          );
        }
      }
    }

    _debugLog('================================================\n');
  }

  void _startNextTrick(Position leader) {
    _updateState(
      _state.copyWith(
        currentTrick: Trick(
          plays: [],
          leader: leader,
          trumpSuit: _state.trumpSuit,
        ),
        currentPlayer: leader,
        gameStatus: '${_state.getName(leader)} leads',
        clearSelectedCardIndices: true,
      ),
    );

    // Update claim status at start of new trick
    _updateClaimStatus();

    if (leader != Position.south) {
      _scheduleAIPlay();
    }
  }

  // ============================================================================
  // SCORING
  // ============================================================================

  void _scoreHand() {
    if (_state.contractor == null || _state.handType == null) return;

    final grandingTeam = _state.contractor!.team;
    final tricksWonByGrandingTeam = _state.getTricksWon(grandingTeam);

    final handScore = MinnesotaWhistScorer.scoreHand(
      handType: _state.handType!,
      grandingTeam: grandingTeam,
      tricksWonByGrandingTeam: tricksWonByGrandingTeam,
      allBidLow: _state.allBidLow,
    );

    // Apply scores
    final newScoreNS = _state.teamNorthSouthScore + handScore.teamNSPoints;
    final newScoreEW = _state.teamEastWestScore + handScore.teamEWPoints;

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.scoring,
        isPlayPhase: false,
        teamNorthSouthScore: newScoreNS,
        teamEastWestScore: newScoreEW,
        gameStatus: handScore.description,
      ),
    );

    // Show score animation (for positive scores only)
    if (handScore.teamNSPoints > 0) {
      _updateState(
        _state.copyWith(
          scoreAnimation: ScoreAnimation(
            points: handScore.teamNSPoints,
            team: Team.northSouth,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

      Timer(const Duration(seconds: 2), () {
        _updateState(
          _state.copyWith(clearScoreAnimation: true),
        );
      });
    } else if (handScore.teamEWPoints > 0) {
      _updateState(
        _state.copyWith(
          scoreAnimation: ScoreAnimation(
            points: handScore.teamEWPoints,
            team: Team.eastWest,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

      Timer(const Duration(seconds: 2), () {
        _updateState(
          _state.copyWith(clearScoreAnimation: true),
        );
      });
    }

    // Check game over
    final gameOverStatus = MinnesotaWhistScorer.checkGameOver(
      teamNSScore: newScoreNS,
      teamEWScore: newScoreEW,
    );

    if (gameOverStatus != null) {
      // Delay before showing game over to let user see final trick and score
      Future.delayed(const Duration(milliseconds: 3000), () {
        _handleGameOver(gameOverStatus, newScoreNS, newScoreEW);
      });
    }
    // Otherwise, stay in scoring phase - user must click "Next Hand" to continue
  }

  /// Start the next hand (public for UI button)
  void startNextHand() {
    final nextDealer = getNextDealer(_state.dealer);

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.setup,
        dealer: nextDealer,
        playerHand: [],
        partnerHand: [],
        opponentEastHand: [],
        opponentWestHand: [],
        bidHistory: [],
        completedTricks: [],
        tricksWonNS: 0,
        tricksWonEW: 0,
        gameStatus: 'Tap Deal for next hand',
        clearCurrentBidder: true,
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
        clearHandType: true,
        clearTrumpSuit: true,
        clearCurrentTrick: true,
        clearCurrentPlayer: true,
        clearPendingBidEntry: true,
      ),
    );
  }

  void _handleGameOver(
    GameOverStatus status,
    int finalScoreNS,
    int finalScoreEW,
  ) {
    final winningTeam = status == GameOverStatus.teamNSWins
        ? Team.northSouth
        : Team.eastWest;

    final playerWon = winningTeam == Team.northSouth;

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.gameOver,
        showGameOverDialog: true,
        gameOverData: GameOverData(
          winningTeam: winningTeam,
          finalScoreNS: finalScoreNS,
          finalScoreEW: finalScoreEW,
          status: status,
          gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
          gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
        ),
        gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
        gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
        gameStatus: MinnesotaWhistScorer.getGameOverMessage(
          status,
          finalScoreNS,
          finalScoreEW,
        ),
      ),
    );
  }

  /// Dismiss game over dialog and reset for new game
  void dismissGameOverDialog() {
    _updateState(
      _state.copyWith(
        showGameOverDialog: false,
        clearGameOverData: true,
      ),
    );

    // Reset to setup
    _updateState(
      GameState(
        gameStarted: true,
        currentPhase: GamePhase.setup,
        dealer: Position.west,
        gamesWon: _state.gamesWon,
        gamesLost: _state.gamesLost,
        gameStatus: 'Tap Deal to start',
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _updateState(GameState newState) {
    // Log phase transitions
    if (_state.currentPhase != newState.currentPhase) {
      _debugLog(
        '\n[PHASE TRANSITION] ${_state.currentPhase.name} -> ${newState.currentPhase.name}',
      );
      if (newState.gameStatus.isNotEmpty) {
        _debugLog('Status: ${newState.gameStatus}');
      }
    }

    _state = newState;
    notifyListeners();
  }
}
