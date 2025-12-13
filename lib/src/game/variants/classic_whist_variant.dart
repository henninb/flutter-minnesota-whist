import 'package:flutter/material.dart';

import 'game_variant.dart';
import '../logic/bidding_engine.dart';
import '../logic/scoring_engine.dart';
import '../models/game_models.dart';
import '../models/card.dart';
import '../engine/game_state.dart';
import '../../ui/context/variant_ui_context.dart';

/// Classic Whist variant implementation
///
/// Classic Whist (also called simply "Whist") is the traditional form of Whist
/// that was extremely popular in the 18th and 19th centuries and served as the
/// foundation for modern games like Bridge.
///
/// Key Rules:
/// - No bidding phase - Trump is determined by the last card dealt
/// - The dealer's last card is turned face-up to determine trump suit
/// - Standard trick-taking with must-follow-suit rules
/// - Scoring uses the "book" system: first 6 tricks = 0 points
/// - Each "odd trick" (tricks 7-13) scores 1 point
/// - Typically played to 5, 7, or 9 points
/// - No special cards or widow
class ClassicWhistVariant implements GameVariant {
  const ClassicWhistVariant();

  @override
  String get name => 'Classic Whist';

  @override
  String get shortDescription =>
      'Traditional Whist with trump determined by last dealt card.';

  @override
  String get description =>
      'Classic Whist is the traditional form of Whist. Trump is determined by turning the last card dealt. Simple "book" scoring: first 6 tricks score nothing, each trick over 6 scores 1 point. First to 7 points wins.';

  @override
  IconData get icon => Icons.history_edu;

  @override
  bool get usesBidding => false;

  @override
  BiddingEngine? createBiddingEngine(Position dealer) {
    // Classic Whist has no bidding phase
    return null;
  }

  @override
  TrumpSelectionMethod get trumpSelectionMethod =>
      TrumpSelectionMethod.lastCard;

  @override
  Suit? determineTrumpSuit(GameState state) {
    // Trump is determined by the last card dealt (stored in state)
    // The game engine will handle storing the turned card's suit
    return state.trumpSuit;
  }

  @override
  ScoringEngine createScoringEngine() {
    return const ClassicWhistScoringEngine();
  }

  @override
  int get winningScore => 7; // Traditional target is 7 points

  @override
  bool get allowsClaimingTricks => false;

  @override
  int get tricksPerHand => 13;

  @override
  bool get hasSpecialCards => false;

  @override
  int get specialCardCount => 0;

  @override
  String get specialCardsLabel => '';

  @override
  Widget? buildBiddingWidget(BiddingWidgetContext context) {
    // Classic Whist has no bidding
    return null;
  }

  @override
  Widget? buildTrumpIndicator(TrumpIndicatorContext context) {
    // Could create a custom trump indicator showing the turned card
    // For now, use default trump display
    return null;
  }

  @override
  Widget? buildSpecialCardDisplay(SpecialCardContext context) {
    // Classic Whist has no special cards
    return null;
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    final actions = <GameAction>[];

    // Classic Whist has straightforward game flow
    switch (state.currentPhase) {
      case GamePhase.dealing:
        // No actions during dealing
        break;

      case GamePhase.bidding:
        // No bidding in Classic Whist - this phase should be skipped
        break;

      case GamePhase.play:
        // No special actions during play
        break;

      case GamePhase.scoring:
        actions.add(
          GameAction(
            label: 'Next Hand',
            icon: Icons.arrow_forward,
            onTap: () {
              // This will be handled by the game controller
            },
          ),
        );
        break;

      case GamePhase.gameOver:
        actions.add(
          GameAction(
            label: 'New Game',
            icon: Icons.replay,
            onTap: () {
              // This will be handled by the game controller
            },
          ),
        );
        break;

      default:
        // No actions for other phases
        break;
    }

    return actions;
  }

  @override
  String getQuickReference() {
    return '''
**Trump**: Last card dealt (turned face-up)
**Scoring**: First 6 tricks = book (0 pts), tricks 7-13 = 1 pt each
**Win**: First to 7 points
''';
  }

  @override
  String getBiddingRules() {
    return '''
# Bidding in Classic Whist

Classic Whist has **no bidding phase**.

Trump is determined randomly by the last card dealt:
• The dealer's final card is turned face-up
• The suit of this card becomes trump for the entire hand
• The dealer picks up the trump card before the first trick
''';
  }

  @override
  String getScoringRules() {
    return '''
# Scoring in Classic Whist

Classic Whist uses the traditional "book" scoring system:

### The Book
• The first **6 tricks** won by a partnership = their "book"
• The book scores **0 points** (baseline)

### Odd Tricks
• Each trick won **beyond 6** is called an "odd trick"
• Each odd trick scores **1 point**

### Examples
• Win 7 tricks: 7 - 6 = **1 point**
• Win 9 tricks: 9 - 6 = **3 points**
• Win all 13 tricks: 13 - 6 = **7 points**
• Win 6 or fewer: **0 points**

**Win Condition**: First team to **7 points** wins
''';
  }

  @override
  String getRulesText() {
    return '''
# Classic Whist Rules

## Overview
Classic Whist is the traditional form of Whist, a trick-taking card game for 4 players in partnerships (North-South vs East-West). It was extremely popular in the 18th and 19th centuries and is the ancestor of Bridge.

## Setup and Dealing
- Standard 52-card deck, dealt completely (13 cards per player)
- The dealer's **last card is turned face-up** to determine trump
- The suit of this card becomes the **trump suit** for the hand
- The dealer picks up the trump card before the first trick

## Trump
- Trump is determined randomly by the last card dealt
- No bidding or player choice in trump selection
- Trump cards beat all non-trump cards regardless of rank

## Play
- Player to dealer's left leads first
- Standard trick-taking rules:
  - Must follow suit if possible
  - If unable to follow suit, may play any card (trump or discard)
  - Highest card of led suit wins (unless trumped)
  - Highest trump played wins the trick
- Winner of trick leads to next trick
- Continue until all 13 tricks are played

## Scoring - The "Book" System
Classic Whist uses a unique baseline scoring system:

### The Book
- The first **6 tricks** won by a partnership are called their "book"
- Making your book scores **0 points**
- Only tricks won beyond 6 count for points

### Odd Tricks
- Tricks 7 through 13 are called "odd tricks"
- Each odd trick scores **1 point** for the partnership
- Maximum of 7 points possible in one hand (winning all 13 tricks)

### Examples
- Partnership wins 9 tricks: 9 - 6 = **3 points**
- Partnership wins 6 tricks or fewer: **0 points**
- Partnership wins all 13 tricks: 13 - 6 = **7 points** (instant win!)

## Winning
- First partnership to reach **7 points** wins the game
- Alternative targets of 5 or 9 points are sometimes used
- If both partnerships reach 7 in the same hand, highest score wins

## Strategy
- Trump management is crucial since trump is random
- Card counting and memory are essential skills
- Partners must communicate through their card play
- Leading from your longest/strongest suit is often best
- "Second hand low, third hand high" is a classic maxim

## Differences from Minnesota Whist
- **No bidding**: Trump is random, not chosen by players
- **Different scoring**: Book system vs Grand/Nula scoring
- **Lower target**: 7 points vs 13 points
- **More traditional**: Classic Whist is the original game
''';
  }
}

/// Scoring engine for Classic Whist
///
/// Implements the traditional "book" scoring system where:
/// - First 6 tricks = the "book" (0 points)
/// - Each trick over 6 = 1 point (called "odd tricks")
class ClassicWhistScoringEngine implements ScoringEngine {
  const ClassicWhistScoringEngine();

  static const int bookSize = 6;
  static const int pointsPerOddTrick = 1;

  @override
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  }) {
    // Classic Whist doesn't use bidding - tricks are passed directly
    final northSouthTricks = additionalParams?['northSouthTricks'] as int? ?? 0;
    final eastWestTricks = additionalParams?['eastWestTricks'] as int? ?? 0;

    // Calculate odd tricks (tricks beyond the book of 6)
    final nsOddTricks =
        northSouthTricks > bookSize ? northSouthTricks - bookSize : 0;
    final ewOddTricks =
        eastWestTricks > bookSize ? eastWestTricks - bookSize : 0;

    // Each odd trick scores 1 point
    final nsPoints = nsOddTricks * pointsPerOddTrick;
    final ewPoints = ewOddTricks * pointsPerOddTrick;

    // Generate explanation
    final explanations = <String>[];

    if (nsPoints > 0) {
      explanations.add(
          'North-South: $northSouthTricks tricks - $bookSize (book) = '
          '$nsOddTricks odd tricks × $pointsPerOddTrick pt = $nsPoints points');
    } else {
      explanations.add(
        'North-South: $northSouthTricks tricks (book or less) = 0 points',
      );
    }

    if (ewPoints > 0) {
      explanations.add('East-West: $eastWestTricks tricks - $bookSize (book) = '
          '$ewOddTricks odd tricks × $pointsPerOddTrick pt = $ewPoints points');
    } else {
      explanations.add(
        'East-West: $eastWestTricks tricks (book or less) = 0 points',
      );
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
    final target = winningScore ?? 7; // Default winning score is 7

    if (teamNSScore >= target && teamEWScore >= target) {
      // Both reached target - highest wins
      if (teamNSScore > teamEWScore) {
        return GameOverStatus.teamNSWins;
      } else if (teamEWScore > teamNSScore) {
        return GameOverStatus.teamEWWins;
      } else {
        return GameOverStatus.draw;
      }
    } else if (teamNSScore >= target) {
      return GameOverStatus.teamNSWins;
    } else if (teamEWScore >= target) {
      return GameOverStatus.teamEWWins;
    }

    return null; // Game continues
  }

  @override
  String getGameOverMessage(GameOverStatus status, int scoreNS, int scoreEW) {
    switch (status) {
      case GameOverStatus.teamNSWins:
        return 'Game Over! North-South wins $scoreNS to $scoreEW!';
      case GameOverStatus.teamEWWins:
        return 'Game Over! East-West wins $scoreEW to $scoreNS!';
      case GameOverStatus.draw:
        return 'Game Over! Draw at $scoreNS to $scoreEW!';
    }
  }

  @override
  String getScoreDescription(HandScore score) {
    return score.description;
  }

  @override
  String explainScoring() {
    return '''
Classic Whist uses the "book" scoring system:
- First $bookSize tricks won = the "book" (0 points)
- Each trick beyond $bookSize = $pointsPerOddTrick point ("odd trick")

Examples:
- 7 tricks: 7 - 6 = 1 point
- 9 tricks: 9 - 6 = 3 points
- 13 tricks: 13 - 6 = 7 points
- 6 or fewer tricks: 0 points
''';
  }
}
