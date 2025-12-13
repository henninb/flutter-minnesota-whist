import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';
import '../logic/deal_utils.dart';
import '../logic/bidding_engine.dart';
import '../logic/minnesota_whist_bidding_engine.dart' as mn_whist;
import '../logic/bid_whist_bidding_engine.dart';
import '../variants/widow_whist_variant.dart';
import '../logic/bidding_ai.dart';
import '../logic/trick_engine.dart';
import '../logic/play_ai.dart';
import '../logic/trump_rules.dart';
import '../logic/claim_analyzer.dart';
import '../logic/scoring_engine.dart';
import '../variants/variant_type.dart';
import '../variants/game_variant.dart';
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

  /// Start a new game with the specified variant
  void startNewGame({VariantType? variant}) {
    final selectedVariant = variant ?? VariantType.minnesotaWhist;
    _debugLog(
      '🎮 [GameEngine] Starting new game with variant: $selectedVariant',
    );
    _updateState(
      GameState(
        gameStarted: true,
        currentPhase: GamePhase.setup,
        gameStatus: 'Tap Cut for Deal to determine dealer',
        variantType: selectedVariant,
      ),
    );
    _debugLog(
      '🎮 [GameEngine] GameState variantType after update: ${_state.variantType}',
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

    // Deal with or without kitty based on variant
    final DealResult dealResult;
    if (_state.variant.hasSpecialCards && _state.variant.specialCardCount > 0) {
      dealResult = dealHandWithKitty(
        deck: deck,
        dealer: _state.dealer,
        kittySize: _state.variant.specialCardCount,
      );
      _debugLog(
        '\n========== DEAL CARDS WITH KITTY (Hand #${_state.handNumber + 1}) ==========',
      );
    } else {
      dealResult = dealHand(deck: deck, dealer: _state.dealer);
      _debugLog(
        '\n========== DEAL CARDS (Hand #${_state.handNumber + 1}) ==========',
      );
    }

    _debugLog('Dealer: ${_state.dealer.name}');
    _debugLog('Deck size: ${deck.length}');

    // Log each hand
    for (final position in Position.values) {
      final hand = dealResult.hands[position]!;
      _debugLog('${position.name}: ${hand.length} cards');
    }

    // Log kitty if present
    if (dealResult.kitty != null) {
      _debugLog('Kitty: ${dealResult.kitty!.length} cards');
    }

    // Count total cards
    final totalCards =
        dealResult.hands.values.fold(0, (sum, hand) => sum + hand.length) +
            (dealResult.kitty?.length ?? 0);
    _debugLog('Total cards dealt: $totalCards (should be 52)');
    _debugLog('========================================\n');

    // Sort player's hand by suit for easier viewing
    final sortedPlayerHand = sortHandBySuit(dealResult.hands[Position.south]!);

    _debugLog('⏱️ [TIMING] About to update state with dealt cards...');

    // Determine trump suit based on variant's trump selection method
    Suit? trumpSuit;
    if (_state.variant.trumpSelectionMethod == TrumpSelectionMethod.lastCard) {
      // Last card dealt to the dealer determines trump
      final dealerHand = dealResult.hands[_state.dealer]!;
      final lastCard = dealerHand.last;
      trumpSuit = lastCard.suit;
      _debugLog(
        '🎮 [TRUMP] Last card dealt: $lastCard, trump suit: $trumpSuit',
      );
    } else if (_state.variant.trumpSelectionMethod ==
        TrumpSelectionMethod.randomCard) {
      // Random card from remaining deck (Oh Hell style)
      // For simplicity, just pick a random suit
      final suits = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
      trumpSuit = suits[Random().nextInt(suits.length)];
      _debugLog('🎮 [TRUMP] Random trump selected: $trumpSuit');
    }

    // Update state with dealt cards (and kitty if present)
    _updateState(
      _state.copyWith(
        playerHand: sortedPlayerHand,
        partnerHand: dealResult.hands[Position.north],
        opponentEastHand: dealResult.hands[Position.east],
        opponentWestHand: dealResult.hands[Position.west],
        kitty: dealResult.kitty ?? [], // Store kitty for Bid Whist
        handNumber: _state.handNumber + 1,
        cutCards: {}, // Clear cut cards after dealing
        trumpSuit: trumpSuit, // Set trump for Classic Whist
      ),
    );

    _debugLog('⏱️ [TIMING] State updated, checking if variant uses bidding...');
    _debugLog('🎮 [VARIANT CHECK] Current variant: ${_state.variant.name}');
    _debugLog('🎮 [VARIANT CHECK] Uses bidding: ${_state.variant.usesBidding}');
    _debugLog(
      '🎮 [VARIANT CHECK] Winning score: ${_state.variant.winningScore}',
    );

    // Check if the variant uses bidding
    if (_state.variant.usesBidding) {
      _debugLog('⏱️ [TIMING] Variant uses bidding, calling _startBidding()...');
      // Start bidding immediately (will set phase to bidding)
      _startBidding();
      _debugLog('⏱️ [TIMING] _startBidding() completed');
    } else {
      _debugLog(
        '⏱️ [TIMING] Variant does not use bidding, starting play phase...',
      );
      // Skip bidding and go straight to play
      _startPlayWithoutBidding();
    }
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
        (deckCard) =>
            deckCard.rank == testCard.rank && deckCard.suit == testCard.suit,
      );
      if (!existsInDeck) {
        _debugLog(
          '⚠️ ERROR: Test hand contains invalid card: ${testCard.label}',
        );
        _debugLog(
          '⚠️ Test hand rejected - all cards must be from standard deck',
        );
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

    _debugLog(
      'Available cards after removing test hand: ${availableCards.length} (should be 39)',
    );

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

    // Branch based on variant type
    if (_state.variantType == VariantType.bidWhist) {
      _debugLog('🎮 [BID WHIST] Starting sequential bidding');
      _startBidWhistBidding();
    } else if (_state.variantType == VariantType.ohHell) {
      _debugLog('🎮 [OH HELL] Starting sequential bidding');
      _startOhHellBidding();
    } else if (_state.variantType == VariantType.widowWhist) {
      _debugLog('🎮 [WIDOW WHIST] All players bid for widow simultaneously');
      _startMinnesotaWhistBidding(); // Use same simultaneous bidding UI
    } else {
      _debugLog(
        '🎮 [MINNESOTA WHIST] All players place bid cards simultaneously',
      );
      _startMinnesotaWhistBidding();
    }
  }

  void _startMinnesotaWhistBidding() {
    // Determine game status message based on variant
    String statusMessage;
    if (_state.variantType == VariantType.widowWhist) {
      statusMessage = 'Bid for the widow (6-12 tricks)';
    } else {
      statusMessage = 'Place your bid card (Black=High, Red=Low)';
    }

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.bidding,
        isBiddingPhase: true,
        bidHistory: [],
        gameStatus: statusMessage,
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

  void _startBidWhistBidding() {
    // First bidder is to dealer's left
    final firstBidder = _state.dealer.next;

    _debugLog('🎮 [BID WHIST] First bidder: ${firstBidder.name}');

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.bidding,
        isBiddingPhase: true,
        bidHistory: [],
        currentBidder: firstBidder,
        gameStatus:
            'Bidding in progress - ${_state.getName(firstBidder)}\'s turn',
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
        clearHandType: true,
      ),
    );

    // If first bidder is AI, trigger AI bid
    if (firstBidder != Position.south) {
      Future.delayed(
        const Duration(milliseconds: 1000),
        () => _processBidWhistAIBid(firstBidder),
      );
    } else {
      // Player's turn - show dialog
      _updateState(_state.copyWith(showBiddingDialog: true));
      _debugLog('🎮 [BID WHIST] Showing bidding dialog for player');
    }
  }

  /// Player selects a bid card (Minnesota Whist - step 1)
  void selectBidCard(PlayingCard card) {
    _updateState(_state.copyWith(pendingBidCard: card));
    _debugLog('[BID CARD SELECTED] ${card.label}');
  }

  /// Player places a Bid Whist bid (sequential bidding)
  void placeBidWhistBid(int books, bool isUptown) {
    if (_state.currentBidder != Position.south) {
      _debugLog('ERROR: Not player\'s turn to bid');
      return;
    }

    _debugLog(
      '[BID WHIST] Player bid: $books books, ${isUptown ? "Uptown" : "Downtown"}',
    );

    // Create bid using BidWhistBiddingEngine helper
    final bid = BidWhistBiddingEngine.createBookBid(
      Position.south,
      books,
      isUptown: isUptown,
    );

    final entry = BidEntry(bidder: Position.south, bid: bid);
    _addBidEntry(entry);

    // Check if bidding is complete, otherwise advance to next bidder
    _checkBidWhistAuctionProgress();
  }

  /// Player passes in Bid Whist
  void placeBidWhistPass() {
    if (_state.currentBidder != Position.south) {
      _debugLog('ERROR: Not player\'s turn to bid');
      return;
    }

    _debugLog('[BID WHIST] Player passed');

    // Create pass bid using BidWhistBiddingEngine helper
    final bid = BidWhistBiddingEngine.createPassBid(Position.south);

    final entry = BidEntry(bidder: Position.south, bid: bid);
    _addBidEntry(entry);

    // Check if bidding is complete, otherwise advance to next bidder
    _checkBidWhistAuctionProgress();
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
    final biddingEngine =
        mn_whist.MinnesotaWhistBiddingEngine(dealer: _state.dealer);

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
    _debugLog(
      'Bid type: ${bid.bidType == BidType.high ? "HIGH (black)" : "LOW (red)"}',
    );

    _addBidEntry(entry);
    _updateState(
      _state.copyWith(
        showBiddingDialog: false,
        pendingBidCard: null, // Clear the pending card
      ),
    );

    // Collect AI bids simultaneously
    _collectAIBids();
  }

  /// Collect AI bid cards (Minnesota Whist - simultaneous bidding)
  void _collectAIBids() {
    _debugLog('\n[AI BIDDING] Collecting AI bid cards...');

    final biddingEngine =
        mn_whist.MinnesotaWhistBiddingEngine(dealer: _state.dealer);

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

      _debugLog(
        '[AI BID] ${_state.getName(position)}: ${bidCard.label} (${bid.bidType == BidType.high ? "HIGH" : "LOW"})',
      );

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
    final biddingEngine =
        mn_whist.MinnesotaWhistBiddingEngine(dealer: _state.dealer);

    if (!biddingEngine.isComplete(_state.bidHistory)) {
      _debugLog(
        '[AUCTION] Not complete - waiting for more bids (${_state.bidHistory.length}/4)',
      );
      return;
    }

    // Auction complete - determine result
    final result = biddingEngine.determineWinner(_state.bidHistory);

    _debugLog('[AUCTION] Complete - determining winner');

    if (result.status == mn_whist.AuctionStatus.won) {
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

      // Check if variant needs kitty exchange (Bid Whist)
      if (_state.variant.hasSpecialCards && _state.kitty.isNotEmpty) {
        _debugLog('🎮 [KITTY] Variant uses kitty, starting exchange phase');
        Future.delayed(const Duration(milliseconds: 1500), _startKittyExchange);
      } else {
        _debugLog('🎮 [PLAY] No kitty, going directly to play phase');
        Future.delayed(const Duration(milliseconds: 1500), _startPlay);
      }
    }
  }

  /// Check Bid Whist sequential auction progress
  void _checkBidWhistAuctionProgress() {
    final biddingEngine = BidWhistBiddingEngine(dealer: _state.dealer);

    // Check if auction is complete
    if (biddingEngine.isComplete(_state.bidHistory)) {
      _debugLog('[BID WHIST AUCTION] Complete - determining winner');
      final result = biddingEngine.determineWinner(_state.bidHistory);

      if (result.status == AuctionStatus.won) {
        _updateState(
          _state.copyWith(
            isBiddingPhase: false,
            showBiddingDialog: false,
            winningBid: result.winningBid,
            contractor: result.winner,
            handType: result.handType,
            gameStatus: result.message,
            clearCurrentBidder: true,
          ),
        );

        // Check if variant needs kitty exchange (Bid Whist)
        if (_state.variant.hasSpecialCards && _state.kitty.isNotEmpty) {
          _debugLog('🎮 [KITTY] Starting exchange phase');
          Future.delayed(
            const Duration(milliseconds: 1500),
            _startKittyExchange,
          );
        } else {
          _debugLog('🎮 [PLAY] Going directly to play phase');
          Future.delayed(const Duration(milliseconds: 1500), _startPlay);
        }
      }
      return;
    }

    // Not complete - advance to next bidder
    final nextBidder = biddingEngine.getNextBidder(_state.bidHistory);

    if (nextBidder == null) {
      _debugLog('[BID WHIST] ERROR: No next bidder but auction not complete');
      return;
    }

    _debugLog('[BID WHIST] Advancing to next bidder: ${nextBidder.name}');

    _updateState(
      _state.copyWith(
        currentBidder: nextBidder,
        showBiddingDialog: false, // Close current dialog
      ),
    );

    // If next bidder is AI, trigger AI bid
    if (nextBidder != Position.south) {
      Future.delayed(
        const Duration(milliseconds: 1000),
        () => _processBidWhistAIBid(nextBidder),
      );
    } else {
      // Player's turn - show dialog
      _updateState(_state.copyWith(showBiddingDialog: true));
    }
  }

  /// Process AI bid for Bid Whist sequential bidding
  void _processBidWhistAIBid(Position position) {
    _debugLog('[BID WHIST AI] Processing bid for ${position.name}');

    // Simple AI: just pass for now
    // TODO: Implement proper Bid Whist AI bidding logic
    // Will need to use: BidWhistBiddingEngine(dealer: _state.dealer) and _state.getHand(position)
    final bid = BidWhistBiddingEngine.createPassBid(position);
    final entry = BidEntry(bidder: position, bid: bid);

    _debugLog('[BID WHIST AI] ${_state.getName(position)} passed');
    _addBidEntry(entry);

    // Continue the auction
    _checkBidWhistAuctionProgress();
  }

  // ============================================================================
  // OH HELL BIDDING
  // ============================================================================

  void _startOhHellBidding() {
    // First bidder is to dealer's left
    final firstBidder = _state.dealer.next;

    _debugLog('🎮 [OH HELL] First bidder: ${firstBidder.name}');

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.bidding,
        isBiddingPhase: true,
        bidHistory: [],
        currentBidder: firstBidder,
        gameStatus:
            'Bidding in progress - ${_state.getName(firstBidder)}\'s turn',
        clearCurrentHighBid: true,
        clearWinningBid: true,
        clearContractor: true,
        clearHandType: true,
      ),
    );

    // If first bidder is AI, trigger AI bid
    if (firstBidder != Position.south) {
      Future.delayed(
        const Duration(milliseconds: 1000),
        () => _processOhHellAIBid(firstBidder),
      );
    } else {
      // Player's turn - show dialog
      _updateState(_state.copyWith(showBiddingDialog: true));
      _debugLog('🎮 [OH HELL] Showing bidding dialog for player');
    }
  }

  void placeOhHellBid(int tricks) {
    if (_state.currentBidder != Position.south) {
      _debugLog('ERROR: Not player\'s turn to bid');
      return;
    }

    _debugLog('[OH HELL] Player bid: $tricks tricks');

    // Wrap integer bid in a Bid object for storage
    // Use rank to encode the trick count (ace=1, king=13, etc.)
    final Rank rank;
    if (tricks == 0) {
      rank = Rank.two; // Use two for 0 bid
    } else if (tricks <= 13) {
      rank = Rank.values[tricks - 1]; // 1->ace, 2->two, etc
    } else {
      rank = Rank.ace;
    }

    final bid = Bid(
      bidType: BidType.high,
      bidder: Position.south,
      bidCard: PlayingCard(rank: rank, suit: Suit.clubs),
    );

    final entry = BidEntry(bidder: Position.south, bid: bid);
    _addBidEntry(entry);

    // Check if bidding is complete, otherwise advance to next bidder
    _checkOhHellAuctionProgress();
  }

  void _checkOhHellAuctionProgress() {
    // Check if auction is complete (all 4 players bid)
    if (_state.bidHistory.length >= 4) {
      _debugLog('[OH HELL AUCTION] Complete - starting play');

      // In Oh Hell, first player (to dealer's left) leads
      final leader = _state.dealer.next;

      _updateState(
        _state.copyWith(
          isBiddingPhase: false,
          showBiddingDialog: false,
          gameStatus: 'All bids placed - play begins',
          clearCurrentBidder: true,
          contractor:
              leader, // Set leader as contractor for _startPlay compatibility
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), _startPlay);
      return;
    }

    // Not complete - advance to next bidder
    final nextBidder = _state.bidHistory.last.bidder.next;

    _debugLog('[OH HELL] Advancing to next bidder: ${nextBidder.name}');

    _updateState(
      _state.copyWith(
        currentBidder: nextBidder,
        showBiddingDialog: false, // Close current dialog
      ),
    );

    // If next bidder is AI, trigger AI bid
    if (nextBidder != Position.south) {
      Future.delayed(
        const Duration(milliseconds: 1000),
        () => _processOhHellAIBid(nextBidder),
      );
    } else {
      // Player's turn - show dialog
      _updateState(_state.copyWith(showBiddingDialog: true));
    }
  }

  void _processOhHellAIBid(Position position) {
    _debugLog('[OH HELL AI] Processing bid for ${position.name}');

    // Simple AI: bid conservatively based on hand strength
    // TODO: Implement proper Oh Hell AI bidding logic
    final hand = _state.getHand(position);
    final tricks = (hand.length * 0.3).round(); // Bid ~30% of hand size

    _debugLog('[OH HELL AI] ${_state.getName(position)} bid $tricks');

    // Wrap integer bid in a Bid object for storage
    final Rank rank;
    if (tricks == 0) {
      rank = Rank.two; // Use two for 0 bid
    } else if (tricks <= 13) {
      rank = Rank.values[tricks - 1]; // 1->ace, 2->two, etc
    } else {
      rank = Rank.ace;
    }

    final bid = Bid(
      bidType: BidType.high,
      bidder: position,
      bidCard: PlayingCard(rank: rank, suit: Suit.clubs),
    );

    final entry = BidEntry(bidder: position, bid: bid);
    _addBidEntry(entry);

    // Continue the auction
    _checkOhHellAuctionProgress();
  }

  // ============================================================================
  // KITTY EXCHANGE & TRUMP DECLARATION (Bid Whist)
  // ============================================================================

  void _startKittyExchange() {
    _debugLog('\n========== KITTY EXCHANGE ==========');
    // For now, auto-perform for all players (TODO: Add UI for human player)
    _performKittyExchange();
  }

  void _performKittyExchange() {
    _debugLog('Auto-performing kitty exchange for ${_state.contractor?.name}');
    // TODO: Implement proper kitty exchange with UI
    // For now, just move to trump declaration
    _startTrumpDeclaration();
  }

  void _startTrumpDeclaration() {
    _debugLog('\n========== TRUMP DECLARATION ==========');
    // Auto-select trump (TODO: Add UI for human player)
    _autoDeclareTrump();
  }

  void _autoDeclareTrump() {
    // Simple: pick spades for now
    final trumpSuit = Suit.spades;
    _debugLog('Auto-declared trump: $trumpSuit');

    _updateState(
      _state.copyWith(
        trumpSuit: trumpSuit,
      ),
    );

    // Start play phase
    Future.delayed(const Duration(milliseconds: 500), _startPlay);
  }

  // ============================================================================
  // WIDOW WHIST BIDDING
  // ============================================================================

  void placeWidowWhistBid(int tricks) {
    _debugLog('[WIDOW WHIST] Player bid: $tricks tricks');

    // Create bid using Widow Whist encoding (Ace=6, King=12)
    final bid = WidowWhistBiddingEngine.createTrickBid(Position.south, tricks);
    final entry = BidEntry(bidder: Position.south, bid: bid);

    _addBidEntry(entry);
    _updateState(_state.copyWith(showBiddingDialog: false));

    // Collect AI bids for Widow Whist
    _collectWidowWhistAIBids();
  }

  /// Collect AI bids for Widow Whist (simultaneous trick bidding)
  void _collectWidowWhistAIBids() {
    _debugLog('\n[WIDOW WHIST AI BIDDING] Collecting AI bids...');

    // AI players place their bids (6-12 tricks)
    for (final position in [Position.north, Position.east, Position.west]) {
      final hand = _state.getHand(position);

      // Simple AI: count high cards and estimate tricks
      // TODO: Implement proper Widow Whist bidding AI
      int highCardCount = 0;
      for (final card in hand) {
        if (card.rank.index >= Rank.jack.index) {
          highCardCount++;
        }
      }

      // Bid based on high cards: 6 + (highCards / 2)
      // This gives: 0-1 high cards = 6 tricks, 2-3 = 7, 4-5 = 8, etc.
      final bidTricks = (6 + (highCardCount / 2)).round().clamp(6, 12);

      final bid = WidowWhistBiddingEngine.createTrickBid(position, bidTricks);
      final entry = BidEntry(bidder: position, bid: bid);

      _debugLog(
        '[AI BID] ${_state.getName(position)}: $bidTricks tricks ($highCardCount high cards)',
      );

      _addBidEntry(entry);
    }

    // All bids collected - determine winner
    _checkWidowWhistAuctionComplete();
  }

  /// Check if Widow Whist auction is complete and determine winner
  void _checkWidowWhistAuctionComplete() {
    final biddingEngine = WidowWhistBiddingEngine(dealer: _state.dealer);

    if (!biddingEngine.isComplete(_state.bidHistory)) {
      _debugLog(
        '[WIDOW WHIST AUCTION] Not complete - waiting for more bids (${_state.bidHistory.length}/4)',
      );
      return;
    }

    // Auction complete - determine result
    final result = biddingEngine.determineWinner(_state.bidHistory);

    _debugLog('[WIDOW WHIST AUCTION] Complete - determining winner');

    if (result.status == AuctionStatus.won) {
      final winningBid = result.winningBid as Bid;
      final trickCount =
          winningBid.bidCard.rank.index + 6; // Decode trick count

      _updateState(
        _state.copyWith(
          isBiddingPhase: false,
          winningBid: result.winningBid,
          contractor: result.winner,
          gameStatus:
              '${_state.getName(result.winner!)} won the widow with $trickCount tricks',
          clearCurrentBidder: true,
        ),
      );

      // Winner gets the widow and must exchange cards
      _debugLog('🎮 [WIDOW WHIST] Starting widow exchange phase');
      Future.delayed(const Duration(milliseconds: 1500), _startWidowExchange);
    }
  }

  /// Start widow exchange phase
  void _startWidowExchange() {
    _debugLog(
      '[WIDOW EXCHANGE] Starting exchange for ${_state.getName(_state.contractor!)}',
    );

    // Give widow to contractor by updating their hand in state
    final contractorHand = _state.getHand(_state.contractor!);
    final fullHand = [...contractorHand, ..._state.kitty];

    _debugLog(
      '[WIDOW EXCHANGE] Contractor now has ${fullHand.length} cards (12 + 4 widow)',
    );

    // Update contractor's hand to include widow
    if (_state.contractor == Position.south) {
      _updateState(
        _state.copyWith(
          currentPhase: GamePhase.kittyExchange,
          playerHand: sortHandBySuit(fullHand),
          gameStatus: 'Select 4 cards to discard and choose trump',
        ),
      );
    } else if (_state.contractor == Position.north) {
      _updateState(
        _state.copyWith(
          currentPhase: GamePhase.kittyExchange,
          partnerHand: sortHandBySuit(fullHand),
          gameStatus:
              '${_state.getName(_state.contractor!)} examining widow...',
        ),
      );
    } else if (_state.contractor == Position.east) {
      _updateState(
        _state.copyWith(
          currentPhase: GamePhase.kittyExchange,
          opponentEastHand: sortHandBySuit(fullHand),
          gameStatus:
              '${_state.getName(_state.contractor!)} examining widow...',
        ),
      );
    } else if (_state.contractor == Position.west) {
      _updateState(
        _state.copyWith(
          currentPhase: GamePhase.kittyExchange,
          opponentWestHand: sortHandBySuit(fullHand),
          gameStatus:
              '${_state.getName(_state.contractor!)} examining widow...',
        ),
      );
    }

    // TODO: Show widow exchange dialog for player
    // For now, auto-perform exchange for all players
    _autoPerformWidowExchange();
  }

  /// Auto-perform widow exchange (temporary until UI is implemented)
  void _autoPerformWidowExchange() {
    // Contractor's hand already includes widow (16 cards)
    final contractorHand = _state.getHand(_state.contractor!);

    if (contractorHand.length != 16) {
      _debugLog(
        '⚠️ ERROR: Contractor hand should have 16 cards, has ${contractorHand.length}',
      );
    }

    // Simple strategy: discard lowest cards
    final sortedByValue = contractorHand.toList()
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));
    final discards = sortedByValue.take(4).toList();

    // Choose trump: suit with most cards in remaining hand
    final remainingHand =
        contractorHand.where((c) => !discards.contains(c)).toList();
    final suitCounts = <Suit, int>{};
    for (final card in remainingHand) {
      suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
    }
    final trumpSuit =
        suitCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    _debugLog(
      '[WIDOW EXCHANGE] Auto-discarding: ${discards.map((c) => c.label).join(', ')}',
    );
    _debugLog('[WIDOW EXCHANGE] Auto-selecting trump: $trumpSuit');

    performWidowExchange(discards, trumpSuit);
    // Note: performWidowExchange will call _startPlay(), so we don't call it here
  }

  // ============================================================================
  // WIDOW EXCHANGE (Widow Whist)
  // ============================================================================

  void performWidowExchange(List<PlayingCard> discards, Suit trumpSuit) {
    if (_state.contractor == null) {
      _debugLog('ERROR: No contractor for widow exchange');
      return;
    }

    _debugLog('[WIDOW EXCHANGE] Discarding ${discards.length} cards');
    _debugLog('[WIDOW EXCHANGE] Trump declared: $trumpSuit');

    // Remove discarded cards from contractor's hand
    final contractorHand = _state.getHand(_state.contractor!).toList();
    _debugLog(
      '[WIDOW EXCHANGE] Contractor hand size before discard: ${contractorHand.length}',
    );

    for (final card in discards) {
      final removed = contractorHand.remove(card);
      if (!removed) {
        _debugLog(
          '⚠️ ERROR: Could not remove ${card.label} from contractor hand - card not found!',
        );
      }
    }

    _debugLog(
      '[WIDOW EXCHANGE] Contractor hand size after discard: ${contractorHand.length}',
    );

    // Update state with new hand and trump
    final sortedHand = sortHandBySuit(contractorHand);

    if (_state.contractor == Position.south) {
      _updateState(
        _state.copyWith(
          playerHand: sortedHand,
          trumpSuit: trumpSuit,
          kitty: [], // Clear widow
        ),
      );
    } else if (_state.contractor == Position.north) {
      _updateState(
        _state.copyWith(
          partnerHand: sortedHand,
          trumpSuit: trumpSuit,
          kitty: [], // Clear widow
        ),
      );
    } else if (_state.contractor == Position.east) {
      _updateState(
        _state.copyWith(
          opponentEastHand: sortedHand,
          trumpSuit: trumpSuit,
          kitty: [], // Clear widow
        ),
      );
    } else if (_state.contractor == Position.west) {
      _updateState(
        _state.copyWith(
          opponentWestHand: sortedHand,
          trumpSuit: trumpSuit,
          kitty: [], // Clear widow
        ),
      );
    }

    // Start play
    Future.delayed(const Duration(milliseconds: 500), _startPlay);
  }

  // ============================================================================
  // PLAY PHASE
  // ============================================================================

  /// Start play phase without bidding (for variants like Classic Whist)
  void _startPlayWithoutBidding() {
    // For Classic Whist: Trump determined by last card dealt (if applicable)
    // Leader is player to dealer's left
    final leader = _state.dealer.next;

    _debugLog('\n========== START PLAY PHASE (No Bidding) ==========');
    _debugLog('Variant: ${_state.variant.name}');
    _debugLog(
      'Leader: ${_state.getName(leader)} (${leader.name}) [dealer\'s left]',
    );
    _debugLog('Trump: ${_state.trumpSuit ?? "None"}');

    // Sort player's hand by suit
    final sortedPlayerHand = sortHandBySuit(_state.playerHand);

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.play,
        isPlayPhase: true,
        playerHand: sortedPlayerHand,
        currentTrick:
            Trick(plays: [], leader: leader, trumpSuit: _state.trumpSuit),
        completedTricks: [],
        tricksWonNS: 0,
        tricksWonEW: 0,
        currentPlayer: leader,
        gameStatus: '${_state.getName(leader)} leads',
        clearSelectedCardIndices: true,
      ),
    );

    _debugLog('========================================\n');

    // If AI leads, schedule AI play
    if (leader != Position.south) {
      _scheduleAIPlay();
    }
  }

  void _startPlay() {
    // Minnesota Whist: No trump in standard version
    const trumpSuit = null;
    final leader = _state.contractor!; // Contractor (grander) leads

    // DEBUG: Verify all hands before play starts
    _debugLog('\n========== START PLAY PHASE ==========');
    _debugLog('Contractor: ${_state.getName(leader)} (${leader.name})');
    _debugLog(
      'Hand type: ${_state.handType == BidType.high ? "HIGH (Grand)" : "LOW (Nula)"}',
    );
    _debugLog('All bid low: ${_state.allBidLow}');
    _debugLog('\nHand verification:');
    var totalCards = 0;
    for (final position in Position.values) {
      final hand = _state.getHand(position);
      totalCards += hand.length;
      _debugLog('${_state.getName(position)}: ${hand.length} cards');
    }
    final expectedCards = _state.variant.tricksPerHand * 4;
    _debugLog(
      'Total cards: $totalCards (should be $expectedCards for ${_state.variant.tricksPerHand} tricks)',
    );
    if (totalCards != expectedCards) {
      _debugLog(
        '⚠️ WARNING: Card count mismatch! Expected $expectedCards, got $totalCards',
      );
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
    final totalCardsRemaining = _state.playerHand.length +
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

    // Auto-play through remaining tricks until hand is complete
    final tricksPerHand = _state.variant.tricksPerHand;
    while (_state.completedTricks.length < tricksPerHand) {
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
      final totalCardsRemaining = _state.playerHand.length +
          _state.partnerHand.length +
          _state.opponentEastHand.length +
          _state.opponentWestHand.length;

      if (totalCardsRemaining == 0 &&
          _state.completedTricks.length < tricksPerHand) {
        _debugLog(
          '⚠️ ERROR: No cards remaining but only ${_state.completedTricks.length} tricks completed (expected $tricksPerHand)',
        );
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
      } else if (_state.completedTricks.length < tricksPerHand) {
        // Start a new trick
        // Determine who leads (winner of last trick or current leader)
        Position leader;
        if (_state.completedTricks.isEmpty) {
          leader = _state.currentPlayer ?? _state.contractor!;
        } else {
          // Get winner of last trick
          final trumpRules = TrumpRules(trumpSuit: _state.trumpSuit);
          final trickEngine = TrickEngine(trumpRules: trumpRules);
          final winner =
              trickEngine.getCurrentWinner(_state.completedTricks.last);

          // Safety check: winner should never be null for a completed trick
          if (winner == null) {
            _debugLog(
              '⚠️ ERROR: Cannot determine winner of last trick during claim',
            );
            _debugLog('⚠️ Re-enabling manual play for recovery');
            _updateState(
              _state.copyWith(
                gameStatus:
                    'Error: Cannot determine trick winner - continue manually',
              ),
            );
            _updateClaimStatus();
            return;
          }

          leader = winner;
        }

        _debugLog(
          'Starting trick ${_state.completedTricks.length + 1}, ${_state.getName(leader)} leads',
        );

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
          '⚠️ ERROR: ${_state.getName(position)} has no cards but trick not complete',
        );
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
        '  ${_state.getName(position)} plays ${card.label} (${hand.length} cards in hand)',
      );

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
          '⚠️ ERROR: Card ${card.label} not found in ${_state.getName(position)} hand',
        );
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

        _debugLog(
          '  Trick ${newCompleted.length} won by ${_state.getName(winner)}',
        );
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
        final tricksPerHand = _state.variant.tricksPerHand;
        if (newCompleted.length == tricksPerHand) {
          _debugLog('All $tricksPerHand tricks complete - scoring hand');
          _verifyAllCardsUnique(newCompleted);
          await Future.delayed(const Duration(milliseconds: 1000));
          _scoreHand();
          return true;
        }

        // Safety: Check if winner has cards before starting next trick
        final winnerHand = _state.getHand(winner);
        if (winnerHand.isEmpty) {
          _debugLog(
            '⚠️ ERROR: Trick winner ${_state.getName(winner)} has no cards to lead next trick',
          );
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
    final tricksPerHand = _state.variant.tricksPerHand;
    if (newCompleted.length == tricksPerHand) {
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
    _debugLog('\n========== SCORING HAND ==========');
    _debugLog('🎮 [VARIANT CHECK] Current variant: ${_state.variant.name}');
    _debugLog(
      '🎮 [VARIANT CHECK] Winning score: ${_state.variant.winningScore}',
    );

    // Get the scoring engine from the current variant
    final scoringEngine = _state.variant.createScoringEngine();
    _debugLog(
      '🎮 [SCORING] Using scoring engine: ${scoringEngine.runtimeType}',
    );

    // For variants with bidding (like Minnesota Whist)
    final grandingTeam = _state.contractor?.team;
    final tricksWonByGrandingTeam =
        grandingTeam != null ? _state.getTricksWon(grandingTeam) : null;

    // Get tricks for both teams (needed for variants without contractors)
    final nsTeamTricks = _state.getTricksWon(Team.northSouth);
    final ewTeamTricks = _state.getTricksWon(Team.eastWest);
    _debugLog(
      '🎮 [SCORING] NS tricks: $nsTeamTricks, EW tricks: $ewTeamTricks',
    );

    // For Oh Hell, extract individual player bids and tricks
    final playerBids = <Position, int>{};
    final playerTricks = <Position, int>{};

    if (_state.variantType == VariantType.ohHell) {
      // Extract bids from bid history (encoded in Bid objects)
      for (final entry in _state.bidHistory) {
        final bid = entry.bid;
        // Decode the trick count from the rank
        int tricks;
        if (bid.bidCard.rank == Rank.two) {
          tricks = 0; // two = 0 bid
        } else {
          tricks = bid.bidCard.rank.index + 1; // ace=1, two=2, etc
        }
        playerBids[entry.bidder] = tricks;
      }

      // Count individual tricks won by each player
      for (final position in Position.values) {
        int tricksWon = 0;
        for (final trick in _state.completedTricks) {
          if (trick.winner == position) {
            tricksWon++;
          }
        }
        playerTricks[position] = tricksWon;
      }

      _debugLog('🎮 [OH HELL] Player bids: $playerBids');
      _debugLog('🎮 [OH HELL] Player tricks: $playerTricks');
    }

    // For Widow Whist, extract declarer bid and tricks
    int? declarerBid;
    int? declarerTricks;
    Position? declarer;

    if (_state.variantType == VariantType.widowWhist) {
      declarer = _state.contractor;
      if (declarer != null) {
        // Extract declarer's bid from winning bid
        final winningBid = _state.winningBid;
        if (winningBid != null) {
          // Decode bid: Ace=6, Two=7, ..., King=12
          declarerBid = winningBid.bidCard.rank.index + 6;
        }

        // Count declarer's tricks
        int tricksCount = 0;
        for (final trick in _state.completedTricks) {
          if (trick.winner == declarer) {
            tricksCount++;
          }
        }
        declarerTricks = tricksCount;

        _debugLog('🎮 [WIDOW WHIST] Declarer: ${declarer.name}');
        _debugLog(
          '🎮 [WIDOW WHIST] Bid: $declarerBid, Tricks: $declarerTricks',
        );
      }
    }

    final handScore = scoringEngine.scoreHand(
      handType: _state.handType,
      contractingTeam: grandingTeam,
      tricksWonByContractingTeam: tricksWonByGrandingTeam,
      additionalParams: {
        'allBidLow': _state.allBidLow,
        'northSouthTricks': nsTeamTricks,
        'eastWestTricks': ewTeamTricks,
        'playerBids': playerBids,
        'playerTricks': playerTricks,
        'declarerBid': declarerBid,
        'declarerTricks': declarerTricks,
        'declarer': declarer,
      },
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

    // Check game over using variant's scoring engine
    final gameOverStatus = scoringEngine.checkGameOver(
      teamNSScore: newScoreNS,
      teamEWScore: newScoreEW,
      winningScore: _state.variant.winningScore,
    );

    if (gameOverStatus != null) {
      // Delay before showing game over to let user see final trick and score
      Future.delayed(const Duration(milliseconds: 3000), () {
        _handleGameOver(scoringEngine, gameOverStatus, newScoreNS, newScoreEW);
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
    ScoringEngine scoringEngine,
    GameOverStatus status,
    int finalScoreNS,
    int finalScoreEW,
  ) {
    final winningTeam = status == GameOverStatus.teamNSWins
        ? Team.northSouth
        : (status == GameOverStatus.teamEWWins ? Team.eastWest : null);

    final playerWon = winningTeam == Team.northSouth;

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.gameOver,
        showGameOverDialog: true,
        gameOverData: GameOverData(
          winningTeam: winningTeam ?? Team.northSouth, // Fallback for draw
          finalScoreNS: finalScoreNS,
          finalScoreEW: finalScoreEW,
          status: status,
          gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
          gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
        ),
        gamesWon: playerWon ? _state.gamesWon + 1 : _state.gamesWon,
        gamesLost: playerWon ? _state.gamesLost : _state.gamesLost + 1,
        gameStatus: scoringEngine.getGameOverMessage(
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
