import 'package:flutter/material.dart';
import 'game_variant.dart';
import '../logic/scoring_engine.dart';
import '../logic/bidding_engine.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../engine/game_state.dart';
import '../../ui/context/variant_ui_context.dart';

/// Oh Hell Variant (also known as Oh Pshaw, Nomination Whist)
///
/// Features:
/// - Sequential bidding where players bid exact number of tricks they'll take
/// - Trump determined by turned-up card or no trump in final round
/// - Scoring rewards exact predictions (bonus for making bid exactly)
/// - Number of cards dealt decreases/increases each hand
/// - Can't bid total that equals number of tricks available (dealer restriction)
class OhHellVariant implements GameVariant {
  const OhHellVariant();

  @override
  String get name => 'Oh Hell';

  @override
  String get shortDescription =>
      'Bid exact number of tricks. Precision scoring.';

  @override
  String get description =>
      'Oh Hell is a trick-taking game where players must bid exactly how many '
      'tricks they will take. The dealer faces a restriction: the total of all '
      'bids cannot equal the number of tricks available. Points are awarded for '
      'making your bid exactly, with penalties for over or under.';

  @override
  IconData get icon => Icons.psychology;

  // Bidding configuration
  @override
  bool get usesBidding => true;

  @override
  BiddingEngine? createBiddingEngine(Position dealer) {
    return OhHellBiddingEngine(dealer: dealer);
  }

  String get biddingRules => '''
**Bidding Rules:**
- Bidding proceeds clockwise from dealer's left
- Each player bids exact number of tricks they'll take (0 to hand size)
- Dealer cannot bid such that total bids equal number of tricks
- Example: 13 tricks available, 3 players bid 10 total, dealer can't bid 3
- Bids are recorded and visible to all players
''';

  // Trump configuration
  @override
  TrumpSelectionMethod get trumpSelectionMethod =>
      TrumpSelectionMethod.randomCard;

  @override
  int get tricksPerHand => 13; // Standard full hand

  // Scoring configuration
  @override
  ScoringEngine createScoringEngine() {
    return const OhHellScoringEngine();
  }

  @override
  int get winningScore => 100; // First to 100 points

  String get scoringRules => '''
**Scoring Rules:**
- Make bid exactly: 10 points + bid amount
- Miss bid (over or under): 0 points
- Example: Bid 3, take 3 = 13 points
- Example: Bid 0, take 0 = 10 points (nil bonus)
- Example: Bid 5, take 4 or 6 = 0 points
''';

  // Special features
  @override
  bool get hasSpecialCards => false;

  @override
  int get specialCardCount => 0;

  @override
  String get specialCardsLabel => '';

  @override
  bool get allowsClaimingTricks => false;

  // Documentation
  String get quickReference => '''
**Oh Hell Quick Reference**

**Setup:** 13 cards per player (can vary by round)

**Bidding:** Sequential, bid 0-13 tricks exactly

**Dealer Rule:** Total bids ≠ number of tricks

**Trump:** Card turned up after deal (or no trump)

**Play:** Standard trick-taking, follow suit

**Scoring:** 10 + bid for exact, 0 for miss

**Win:** First to 100 points
''';

  String get fullRules => '''
# Oh Hell

## Overview
Oh Hell (also called Oh Pshaw, Nomination Whist, or Blackout) is a trick-taking
game focused on precision bidding. Players must predict exactly how many tricks
they will take, with no margin for error.

## Setup
- 52-card standard deck
- 4 players (can be played with 3-7 players)
- Deal 13 cards to each player
- Turn up next card to determine trump (last card if deck exhausted)

## Bidding Phase
Bidding proceeds clockwise starting from dealer's left:

1. **Bid Range:** 0 to number of cards in hand
   - Bid 0: You will take no tricks (nil bid)
   - Bid 5: You will take exactly 5 tricks
   - Bid 13: You will take all tricks

2. **Dealer Restriction:**
   - The dealer bids last
   - Dealer cannot bid such that total bids = total tricks
   - This ensures at least one player will fail their bid
   - Example: 13 tricks, first 3 players bid 10 total, dealer can't bid 3

3. **Bid Recording:**
   - All bids are recorded and visible
   - Players can see running total before dealer bids

## Play Phase
- Player to dealer's left leads first trick
- Standard trick-taking: must follow suit if able
- Trump suit determined by turned-up card
- If no cards left for trump (last hand), play no trump
- Highest trump wins, or highest card in led suit

## Scoring
**Making Bid Exactly:**
- Score = 10 points + bid amount
- Bid 0, take 0: 10 points
- Bid 3, take 3: 13 points
- Bid 7, take 7: 17 points

**Missing Bid:**
- Take more or fewer tricks than bid: 0 points
- No partial credit for being close

## Strategy Tips
- Conservative bidding is often wise
- Watch the running total before dealer bids
- Nil bids (0) are valuable but risky
- Trump strength heavily influences bid
- Partnership communication through play

## Variations (Not Implemented)
- Progressive: Hand size changes each round (1-13-1)
- Knockout: Eliminations for repeated failures
- Bonus scoring: Extra points for difficult bids
''';

  // Trump determination
  @override
  Suit? determineTrumpSuit(GameState state) {
    // Trump determined by turned card during deal
    return state.trumpSuit;
  }

  // UI Methods
  @override
  Widget? buildBiddingWidget(dynamic context) {
    return null;
  }

  @override
  Widget? buildTrumpIndicator(dynamic context) {
    return null;
  }

  @override
  Widget? buildSpecialCardDisplay(dynamic context) {
    return null;
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    return [];
  }

  @override
  String getRulesText() {
    return fullRules;
  }

  @override
  String getQuickReference() {
    return quickReference;
  }

  @override
  String getBiddingRules() {
    return biddingRules;
  }

  @override
  String getScoringRules() {
    return scoringRules;
  }
}

/// Bidding engine for Oh Hell
class OhHellBiddingEngine extends BiddingEngine {
  const OhHellBiddingEngine({required super.dealer});

  @override
  bool isComplete(List<BidEntry> bids) {
    // Complete when all 4 players have bid
    return bids.length == 4;
  }

  @override
  BidValidation validateBid({
    required dynamic bid,
    required Position bidder,
    required List<BidEntry> currentBids,
  }) {
    if (bid is! int) {
      return BidValidation.invalid('Bid must be a number');
    }

    // Bid must be 0-13
    if (bid < 0 || bid > 13) {
      return BidValidation.invalid('Bid must be between 0 and 13');
    }

    // Check dealer restriction
    if (currentBids.length == 3 && bidder == dealer) {
      // Dealer is last to bid - check restriction
      final totalSoFar = currentBids.fold<int>(
        0,
        (sum, entry) => sum + (entry.bid as int),
      );

      if (totalSoFar + bid == 13) {
        return BidValidation.invalid(
          'Dealer cannot bid $bid (total would equal 13 tricks)',
        );
      }
    }

    return BidValidation.valid();
  }

  @override
  AuctionResult determineWinner(List<BidEntry> bids) {
    // In Oh Hell, there's no "winner" of the bidding
    // Everyone plays and tries to make their own bid
    // We'll just return incomplete if not all bids placed
    if (bids.isEmpty || bids.length < 4) {
      return AuctionResult.incomplete(
        message: 'Waiting for all players to bid',
      );
    }

    // Return a simple result - no real winner in Oh Hell
    // Create a dummy bid for the first player
    final firstBid = Bid(
      bidType: BidType.high,
      bidder: dealer.next,
      bidCard: PlayingCard(rank: Rank.ace, suit: Suit.spades),
    );

    return AuctionResult.winner(
      winningBid: firstBid,
      message: 'Bidding complete - play begins',
    );
  }

  @override
  Position? getNextBidder(List<BidEntry> bids) {
    if (isComplete(bids)) return null;

    if (bids.isEmpty) {
      return dealer.next;
    }

    return bids.last.bidder.next;
  }
}

/// Scoring engine for Oh Hell
class OhHellScoringEngine implements ScoringEngine {
  const OhHellScoringEngine();

  @override
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  }) {
    // Oh Hell scores individuals, not teams
    // We need individual bid and trick data
    final playerBids = additionalParams?['playerBids'] as Map<Position, int>?;
    final playerTricks =
        additionalParams?['playerTricks'] as Map<Position, int>?;

    if (playerBids == null || playerTricks == null) {
      return HandScore(
        teamNSPoints: 0,
        teamEWPoints: 0,
        description: 'Missing bid or trick data',
      );
    }

    int nsPoints = 0;
    int ewPoints = 0;
    final explanations = <String>[];

    // Score each player
    for (final position in Position.values) {
      final bid = playerBids[position] ?? 0;
      final tricks = playerTricks[position] ?? 0;

      int points = 0;
      if (bid == tricks) {
        // Made bid exactly
        points = 10 + bid;
        explanations.add(
          '${position.name}: Bid $bid, took $tricks = +$points points ✓',
        );
      } else {
        // Missed bid
        explanations.add(
          '${position.name}: Bid $bid, took $tricks = 0 points ✗',
        );
      }

      // Add to team total
      if (position == Position.north || position == Position.south) {
        nsPoints += points;
      } else {
        ewPoints += points;
      }
    }

    return HandScore(
      teamNSPoints: nsPoints,
      teamEWPoints: ewPoints,
      description: explanations.join('\n'),
    );
  }

  @override
  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int? winningScore,
  }) {
    final targetScore = winningScore ?? 100;

    if (teamNSScore >= targetScore && teamEWScore >= targetScore) {
      return teamNSScore > teamEWScore
          ? GameOverStatus.teamNSWins
          : GameOverStatus.teamEWWins;
    }

    if (teamNSScore >= targetScore) {
      return GameOverStatus.teamNSWins;
    }

    if (teamEWScore >= targetScore) {
      return GameOverStatus.teamEWWins;
    }

    return null;
  }

  @override
  String getGameOverMessage(
    GameOverStatus status,
    int finalScoreNS,
    int finalScoreEW,
  ) {
    switch (status) {
      case GameOverStatus.teamNSWins:
        return 'North-South wins! Final score: $finalScoreNS-$finalScoreEW';
      case GameOverStatus.teamEWWins:
        return 'East-West wins! Final score: $finalScoreEW-$finalScoreNS';
      case GameOverStatus.draw:
        return 'Draw! Both teams reached 100 points: $finalScoreNS-$finalScoreEW';
    }
  }

  String getScoringExplanation() {
    return '''
**Oh Hell Scoring System**

The key to Oh Hell is bidding exactly what you'll take.

**Making Your Bid:**
- Score = 10 points + your bid
- Bid 0, take 0: 10 points (nil bonus)
- Bid 5, take 5: 15 points
- Bid 10, take 10: 20 points

**Missing Your Bid:**
- Take more or less than bid: 0 points
- No partial credit

**Examples:**
- Bid 3, take 3: 13 points ✓
- Bid 3, take 2: 0 points ✗
- Bid 3, take 4: 0 points ✗
- Bid 0, take 0: 10 points ✓ (nil bonus)

**Strategy:**
- Conservative bids are safer
- Nil (0) bids give 10 points but are risky
- Higher bids give more points but harder to hit exactly
''';
  }

  @override
  String getScoreDescription(HandScore score) {
    return score.description;
  }
}
