import 'package:flutter/material.dart';
import 'game_variant.dart';
import '../logic/scoring_engine.dart';
import '../logic/bidding_engine.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../engine/game_state.dart';
import '../../ui/context/variant_ui_context.dart';

/// Widow Whist Variant
///
/// Features:
/// - Simultaneous bidding for the "widow" (extra hand of cards)
/// - High bidder gets widow and exchanges cards
/// - High bidder declares trump and plays solo against other 3 players
/// - 4-card widow (12 cards per player + 4 widow)
/// - Scoring based on tricks taken vs. bid
class WidowWhistVariant implements GameVariant {
  const WidowWhistVariant();

  @override
  String get name => 'Widow Whist';

  @override
  String get shortDescription => 'Bid for widow rights. Exchange and play.';

  @override
  String get description =>
      'Widow Whist features competitive bidding for the "widow" - a 4-card '
      'hand that goes to the high bidder. The winner exchanges cards with '
      'the widow, declares trump, and plays solo against the other three '
      'players. High risk, high reward!';

  @override
  IconData get icon => Icons.swap_horiz;

  // Bidding configuration
  @override
  bool get usesBidding => true;

  @override
  BiddingEngine? createBiddingEngine(Position dealer) {
    return WidowWhistBiddingEngine(dealer: dealer);
  }

  String get biddingRules => '''
**Bidding Rules:**
- All players bid simultaneously for the widow
- Bid minimum number of tricks you'll take (6-12)
- Highest bid wins the widow
- Winner plays solo against other 3 players
- Ties: Re-bid among tied players
- Minimum bid: 6 tricks
- Maximum bid: 12 tricks (all)
''';

  // Trump configuration
  @override
  TrumpSelectionMethod get trumpSelectionMethod =>
      TrumpSelectionMethod.bidWinner;

  @override
  int get tricksPerHand => 12; // After widow exchange, 12 cards each

  // Scoring configuration
  @override
  ScoringEngine createScoringEngine() {
    return const WidowWhistScoringEngine();
  }

  @override
  int get winningScore => 50; // First to 50 points

  String get scoringRules => '''
**Scoring Rules:**
- Make bid: +1 point per trick over 6
- Miss bid: -2 points per trick short
- Example: Bid 8, take 8 = +2 points (8-6)
- Example: Bid 8, take 6 = -4 points (2 short × 2)
- Example: Bid 12, take 12 = +6 points (12-6)
''';

  // Special features
  @override
  bool get hasSpecialCards => true;

  @override
  int get specialCardCount => 4; // 4-card widow

  @override
  String get specialCardsLabel => 'Widow';

  @override
  bool get allowsClaimingTricks => false;

  // Documentation
  String get quickReference => '''
**Widow Whist Quick Reference**

**Setup:** 12 cards per player + 4-card widow

**Bidding:** Simultaneous bid 6-12 tricks for widow

**Widow:** High bidder takes widow, discards 4 cards

**Trump:** High bidder declares trump

**Play:** High bidder vs. other 3 players (12 tricks)

**Scoring:** +1 per trick over 6, -2 per trick short

**Win:** First to 50 points
''';

  String get fullRules => '''
# Widow Whist

## Overview
Widow Whist is a competitive variant where players bid for the right to take
a special "widow" hand. The high bidder plays solo against the other three
players, making it a 1-vs-3 game.

## Setup
- 52-card standard deck
- 4 players (no fixed partnerships)
- Deal 12 cards to each player + 4 cards face-down to widow
- Total: 48 + 4 = 52 cards

## Bidding Phase
All players bid simultaneously:

1. **Bid Range:** 6 to 12 tricks
   - Bid 6: Minimum (you'll take at least half the tricks)
   - Bid 12: Maximum (you'll take all tricks)

2. **Simultaneous Bidding:**
   - All players select a bid card simultaneously
   - Highest bid wins the widow
   - Ties: Re-bid among tied players only

3. **Solo Play:**
   - High bidder becomes the "declarer"
   - Declarer plays alone against other 3
   - Other 3 players cooperate to defeat declarer

## Widow Exchange
After bidding:
1. High bidder reveals the 4-card widow
2. Adds widow to hand (16 cards total)
3. Selects and discards any 4 cards face-down
4. Declares trump suit
5. Back to 12 cards in hand

## Play Phase
- High bidder leads first trick
- Standard trick-taking: must follow suit if able
- Trump suit declared by high bidder
- Highest trump wins, or highest card in led suit
- 12 tricks total

## Scoring
**Making the Bid:**
- Score = (tricks taken - 6) points
- Bid 8, take 8: +2 points
- Bid 10, take 11: +5 points (still made 10)
- Bid 12, take 12: +6 points (maximum)

**Failing the Bid:**
- Score = -2 × (tricks short)
- Bid 8, take 7: -2 points (1 short)
- Bid 10, take 7: -6 points (3 short)
- High penalty for overbidding

**Opponents:**
- No direct scoring for opponents
- Defeating declarer prevents their points

## Strategy Tips
- Widow adds 4 unknown cards to your hand
- Conservative bidding reduces risk
- Trump declaration is crucial
- 3 opponents working together is strong
- Exchange wisely - balance suits

## Differences from Other Variants
- Solo play (1 vs 3) unlike partnerships
- Widow exchange changes your hand significantly
- No partnership cooperation for declarer
- Higher scoring variance
''';

  // Trump determination
  @override
  Suit? determineTrumpSuit(GameState state) {
    // Trump declared by bid winner after widow exchange
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

/// Bidding engine for Widow Whist
class WidowWhistBiddingEngine extends BiddingEngine {
  const WidowWhistBiddingEngine({required super.dealer});

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
    if (bid is! Bid) {
      return BidValidation.invalid('Bid must be a card');
    }

    // In Widow Whist, we encode the trick count in the card rank
    // Ace = 6 tricks, King = 12 tricks, etc.
    final tricks = _getTrickCount(bid);

    if (tricks < 6 || tricks > 12) {
      return BidValidation.invalid('Bid must be between 6 and 12 tricks');
    }

    return BidValidation.valid();
  }

  @override
  AuctionResult determineWinner(List<BidEntry> bids) {
    if (bids.isEmpty || bids.length < 4) {
      return AuctionResult.incomplete(
        message: 'Waiting for all players to bid',
      );
    }

    // Find highest bid
    BidEntry? highestBidEntry;
    int highestTricks = 0;

    for (final entry in bids) {
      final tricks = _getTrickCount(entry.bid);
      if (tricks > highestTricks) {
        highestTricks = tricks;
        highestBidEntry = entry;
      }
    }

    if (highestBidEntry == null) {
      return AuctionResult.incomplete(message: 'No valid bids');
    }

    return AuctionResult.winner(
      winningBid: highestBidEntry.bid,
      message: '${highestBidEntry.bidder.name} wins with $highestTricks tricks',
    );
  }

  /// Get trick count from bid (encoded in rank)
  int _getTrickCount(Bid bid) {
    // Encode: Ace=6, Two=7, Three=8, ..., King=12
    final rank = bid.bidCard.rank;
    return rank.index + 6; // ace.index=0, so 0+6=6
  }

  @override
  Position? getNextBidder(List<BidEntry> bids) {
    // Widow Whist uses simultaneous bidding, so no next bidder
    return null;
  }

  /// Create a bid for a specific trick count
  static Bid createTrickBid(Position bidder, int tricks) {
    // Encode tricks in rank: 6->ace, 7->two, 8->three, ..., 12->king
    final rankIndex = tricks - 6;
    final rank = Rank.values[rankIndex];

    return Bid(
      bidType: BidType.high,
      bidder: bidder,
      bidCard: PlayingCard(rank: rank, suit: Suit.spades),
    );
  }
}

/// Scoring engine for Widow Whist
class WidowWhistScoringEngine implements ScoringEngine {
  const WidowWhistScoringEngine();

  @override
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  }) {
    // Extract declarer's bid and tricks
    final declarerBid = additionalParams?['declarerBid'] as int? ?? 6;
    final declarerTricks = additionalParams?['declarerTricks'] as int? ?? 0;
    final declarerPosition = additionalParams?['declarer'] as Position?;

    int declarerPoints = 0;
    final explanations = <String>[];

    if (declarerTricks >= declarerBid) {
      // Made the bid
      declarerPoints = declarerTricks - 6;
      explanations.add(
        '✓ Declarer made bid: $declarerBid tricks, took $declarerTricks = +$declarerPoints points',
      );
    } else {
      // Failed the bid
      final tricksShort = declarerBid - declarerTricks;
      declarerPoints = -2 * tricksShort;
      explanations.add(
        '✗ Declarer failed bid: $declarerBid tricks, took $declarerTricks = $declarerPoints points ($tricksShort short)',
      );
    }

    // In Widow Whist, it's 1 vs 3, so we need to know which team the declarer is on
    // For simplicity, we'll give points to declarer's team
    final isNorthSouth = declarerPosition == Position.north ||
        declarerPosition == Position.south;

    return HandScore(
      teamNSPoints: isNorthSouth ? declarerPoints : 0,
      teamEWPoints: isNorthSouth ? 0 : declarerPoints,
      description: explanations.join('\n'),
    );
  }

  @override
  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int? winningScore,
  }) {
    final targetScore = winningScore ?? 50;

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
        return 'Draw! Both teams reached 50 points: $finalScoreNS-$finalScoreEW';
    }
  }

  String getScoringExplanation() {
    return '''
**Widow Whist Scoring System**

The declarer (high bidder) scores based on tricks taken vs. bid.

**Making Your Bid:**
- Score = tricks taken - 6
- Bid 6, take 6: 0 points (minimum)
- Bid 8, take 9: 3 points
- Bid 12, take 12: 6 points (maximum)

**Failing Your Bid:**
- Score = -2 × tricks short
- Bid 8, take 7: -2 points (1 short)
- Bid 10, take 7: -6 points (3 short)

**Strategy:**
- Conservative bids are safer
- Widow can help or hurt
- 3 opponents working together is tough
- Going for 12 is high risk/reward
''';
  }

  @override
  String getScoreDescription(HandScore score) {
    return score.description;
  }
}
