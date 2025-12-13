import 'package:flutter/material.dart';
import 'game_variant.dart';
import '../logic/scoring_engine.dart';
import '../logic/bidding_engine.dart';
import '../logic/bid_whist_bidding_engine.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../engine/game_state.dart';
import '../../ui/context/variant_ui_context.dart';

/// Bid Whist Variant
///
/// Features:
/// - Sequential bidding with number of tricks (3-7 books)
/// - 6-card kitty goes to high bidder
/// - Winner declares trump after bidding
/// - Uptown (Ace high) vs Downtown (Ace low, 2 high) modifier
/// - 7 points to win (or -7 for loss)
/// - Complex scoring based on bid level and success
class BidWhistVariant implements GameVariant {
  const BidWhistVariant();

  @override
  String get name => 'Bid Whist';

  @override
  String get shortDescription =>
      'Sequential bidding with kitty, trump declaration.';

  @override
  String get description =>
      'Bid Whist features sequential competitive bidding where players bid '
      'the number of books (tricks) they will take (3-6). The high bidder '
      'receives a 4-card kitty and declares trump. Uptown/Downtown modifier '
      'affects card rankings. Complex scoring rewards successful bids.';

  @override
  IconData get icon => Icons.style;

  // Bidding configuration
  @override
  bool get usesBidding => true;

  @override
  BiddingEngine? createBiddingEngine(Position dealer) {
    return BidWhistBiddingEngine(dealer: dealer);
  }

  @override
  String get biddingRules => '''
**Bidding Rules:**
- Bidding proceeds clockwise from dealer's left
- Each player bids number of books (3-6) or passes
- Each bid must be higher than the previous bid
- Bid includes Uptown (Ace high) or Downtown (Ace low, 2 high)
- High bidder wins and receives the 4-card kitty
- High bidder then declares trump suit (or no trump)
- Minimum bid: 3 books
- Maximum bid: 6 books (all 12 tricks)
''';

  // Trump configuration
  @override
  TrumpSelectionMethod get trumpSelectionMethod =>
      TrumpSelectionMethod.bidWinner;

  @override
  int get tricksPerHand => 12; // 12 cards per player after kitty exchange

  // Scoring configuration
  @override
  ScoringEngine createScoringEngine() {
    return const BidWhistScoringEngine();
  }

  @override
  int get winningScore => 7;

  @override
  String get scoringRules => '''
**Scoring Rules:**
- Making bid: Points equal to bid level (3-7)
- Failing bid: Lose points equal to bid level (-3 to -7)
- Boston (all 13 tricks): Double points
- No trump bid: Additional bonus points
- First to +7 points wins
- Reaching -7 points loses
''';

  // Special features
  @override
  bool get hasSpecialCards => true;

  @override
  int get specialCardCount =>
      4; // 4-card kitty (12 cards per player, 52-card deck)

  @override
  String get specialCardsLabel => 'Kitty';

  @override
  bool get allowsClaimingTricks => false;

  // Documentation
  @override
  String get quickReference => '''
**Bid Whist Quick Reference**

**Setup:** 12 cards per player + 4-card kitty

**Bidding:** Sequential, bid 3-6 books with Uptown/Downtown

**Kitty:** High bidder takes kitty, discards 4 cards

**Trump:** High bidder declares trump after seeing kitty

**Play:** Standard trick-taking, follow suit (12 tricks total)

**Scoring:** +/- bid level for make/fail, bonus for Boston

**Win:** First to 7 points (or opponent reaches -7)
''';

  @override
  String get fullRules => '''
# Bid Whist

## Overview
Bid Whist is a popular partnership trick-taking game with sequential competitive
bidding and a kitty system.

## Setup
- 52-card standard deck
- 4 players in fixed partnerships (N-S vs E-W)
- Deal 12 cards to each player + 4 cards to kitty (face down)

## Bidding Phase
Bidding proceeds clockwise starting from dealer's left:

1. **Bid Structure:** Number (3-7) + Mode (Uptown/Downtown) + optional No Trump
   - 3 Uptown: Bid to win 3 books with Ace high
   - 5 Downtown: Bid to win 5 books with Ace low (2 high)
   - 4 No Trump: Bid to win 4 books with no trump suit

2. **Bidding Rules:**
   - Each bid must be higher than previous (number takes precedence)
   - Players can pass (but may re-enter bidding)
   - Bidding continues until 3 consecutive passes

3. **Uptown vs Downtown:**
   - **Uptown:** Standard card rankings (A high, 2 low)
   - **Downtown:** Reversed rankings (2 high, 3 next, ... K, A low)
   - Affects both trump and plain suits

## Kitty Exchange
After bidding:
1. High bidder turns up the 4-card kitty
2. Adds kitty to hand (16 cards total)
3. Discards any 4 cards face down
4. Declares trump suit (or confirms no trump)

## Play Phase
- High bidder leads first trick
- Standard trick-taking: must follow suit if able
- Trump wins over plain suits (unless no trump)
- Highest card in led suit wins (if no trump played)
- Uptown/Downtown affects card rankings

## Scoring
**Making the Bid:**
- 3-6 books: Points equal to bid level (+3 to +6)
- 7 books (Boston): Double points (+14)
- No Trump bid: Additional +1 bonus

**Failing the Bid:**
- Lose points equal to bid level (-3 to -7)

**Game End:**
- First team to reach +7 points wins
- Team reaching -7 points loses immediately

## Strategy Tips
- Kitty adds significant potential to your hand
- Downtown bids reverse normal card values
- No trump requires very strong hand
- Partnership communication through play is key
- Conservative bidding early, aggressive when ahead

## Differences from Minnesota Whist
- Sequential bidding vs simultaneous
- Kitty exchange vs no exchange
- Trump declaration vs no trump
- Uptown/Downtown vs fixed rankings
- Books (sets of tricks) vs individual tricks
''';

  // Trump determination
  @override
  Suit? determineTrumpSuit(GameState state) {
    // Trump is declared by bid winner after kitty exchange
    // Stored in state by game engine
    return state.trumpSuit;
  }

  // UI Methods
  @override
  Widget? buildBiddingWidget(dynamic context) {
    // TODO: Implement Bid Whist bidding UI
    return null;
  }

  @override
  Widget? buildTrumpIndicator(dynamic context) {
    // Use default trump indicator
    return null;
  }

  @override
  Widget? buildSpecialCardDisplay(dynamic context) {
    // TODO: Implement kitty display
    return null;
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    // TODO: Return proper GameAction list
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

/// Scoring engine for Bid Whist
class BidWhistScoringEngine implements ScoringEngine {
  const BidWhistScoringEngine();

  @override
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  }) {
    // Extract parameters
    final bidLevel = additionalParams?['bidLevel'] as int? ?? 3;
    final isNoTrump = additionalParams?['isNoTrump'] as bool? ?? false;
    final tricksWon = tricksWonByContractingTeam ?? 0;

    // Calculate books won (a book is 6 tricks + extras)
    // In Bid Whist with 12 tricks, you need 6 + bid to make your contract
    // Max bid is 6 books (6 + 6 = 12 tricks, all of them)
    final booksWon = tricksWon > 6 ? tricksWon - 6 : 0;
    final madeBid = booksWon >= bidLevel;

    int points = 0;
    final explanations = <String>[];

    if (madeBid) {
      // Made the bid
      if (tricksWon == 12) {
        // Boston (all tricks)
        points = bidLevel * 2;
        explanations.add('🎯 Boston! All 12 tricks = $points points (doubled)');
      } else {
        points = bidLevel;
        explanations.add('✓ Made $bidLevel book bid = +$bidLevel points');
      }

      // No trump bonus
      if (isNoTrump) {
        points += 1;
        explanations.add('⭐ No Trump bonus = +1 point');
      }
    } else {
      // Failed the bid
      points = -bidLevel;
      explanations.add('✗ Failed $bidLevel book bid = $points points');
      explanations.add('   Won $booksWon books, needed $bidLevel');
    }

    // Determine which team gets points
    final nsPoints = contractingTeam == Team.northSouth ? points : 0;
    final ewPoints = contractingTeam == Team.eastWest ? points : 0;

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
    final targetScore = winningScore ?? 7;
    // Win by reaching +7
    if (teamNSScore >= targetScore) {
      return GameOverStatus.teamNSWins;
    }
    if (teamEWScore >= targetScore) {
      return GameOverStatus.teamEWWins;
    }

    // Lose by reaching -7
    if (teamNSScore <= -targetScore) {
      return GameOverStatus.teamEWWins;
    }
    if (teamEWScore <= -targetScore) {
      return GameOverStatus.teamNSWins;
    }

    return null; // Game continues
  }

  @override
  String getGameOverMessage(
    GameOverStatus status,
    int finalScoreNS,
    int finalScoreEW,
  ) {
    switch (status) {
      case GameOverStatus.teamNSWins:
        if (finalScoreEW <= -7) {
          return 'North-South wins! East-West reached -7 points.';
        }
        return 'North-South wins! Reached $finalScoreNS points.';
      case GameOverStatus.teamEWWins:
        if (finalScoreNS <= -7) {
          return 'East-West wins! North-South reached -7 points.';
        }
        return 'East-West wins! Reached $finalScoreEW points.';
      case GameOverStatus.draw:
        return 'Draw! Both teams reached 7 points.';
    }
  }

  @override
  String getScoringExplanation() {
    return '''
**Bid Whist Scoring System**

A "book" in Bid Whist is 6 tricks plus the bid level.
- Bid 3 = need to win 9 tricks (6 + 3)
- Bid 4 = need to win 10 tricks (6 + 4)
- Bid 5 = need to win 11 tricks (6 + 5)
- Bid 6 = need to win 12 tricks (6 + 6)
- Bid 7 = need to win 13 tricks (all)

**Scoring:**
- Make bid: +bid level points (3-7)
- Fail bid: -bid level points (-3 to -7)
- Boston (all 13 tricks): Double points
- No Trump bid: +1 bonus point

**Examples:**
- Bid 4, win 10 tricks: +4 points
- Bid 5, win 9 tricks: -5 points (only 3 books)
- Bid 7, win 13 tricks: +14 points (Boston!)
- Bid 4 No Trump, win 11 tricks: +5 points (4 + 1 bonus)
''';
  }

  @override
  String getScoreDescription(HandScore score) {
    return score.description;
  }
}
