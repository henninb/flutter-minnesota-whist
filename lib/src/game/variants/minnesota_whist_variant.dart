import 'package:flutter/material.dart';

import 'game_variant.dart';
import 'minnesota_whist_bidding_adapter.dart';
import 'minnesota_whist_scoring_adapter.dart';
import '../logic/bidding_engine.dart';
import '../logic/scoring_engine.dart';
import '../models/game_models.dart';
import '../models/card.dart';
import '../engine/game_state.dart';
import '../../ui/context/variant_ui_context.dart';
import '../../ui/widgets/variants/minnesota_whist_bidding_widget.dart';

/// Minnesota Whist variant implementation
///
/// Minnesota Whist bidding rules:
/// - All 4 players simultaneously place a card face down
/// - Black card (spades/clubs) = High bid (want to win tricks)
/// - Red card (hearts/diamonds) = Low bid (want to lose tricks)
/// - Players reveal cards in order starting from dealer's left
/// - First black card revealed ends the revealing (others don't reveal)
/// - If all red, it's a "Low" (Nula) hand
/// - If any black, it's a "High" (Grand) hand
///
/// Scoring:
/// - High (Grand) Hand: Team that granded scores 1 point per trick over 6
/// - High Hand (opponent): Non-granding team scores 2 points per trick over 6
/// - Low (Nula) Hand: Team scores 1 point for every trick under 7
/// - All Low Hand: Team with more tricks loses 1 point per trick over 6
/// - Game is played to 13 points
class MinnesotaWhistVariant implements GameVariant {
  const MinnesotaWhistVariant();

  @override
  String get name => 'Minnesota Whist';

  @override
  String get shortDescription =>
      'Simultaneous bidding with black/red cards. No trump.';

  @override
  String get description =>
      'Minnesota Whist features simultaneous bidding where players select black cards for High or red cards for Low. No trump suit. Simple trick-taking to 13 points.';

  @override
  IconData get icon => Icons.style;

  @override
  bool get usesBidding => true;

  @override
  BiddingEngine? createBiddingEngine(Position dealer) {
    return MinnesotaWhistBiddingEngineAdapter(dealer: dealer);
  }

  @override
  TrumpSelectionMethod get trumpSelectionMethod => TrumpSelectionMethod.none;

  @override
  Suit? determineTrumpSuit(GameState state) {
    // Minnesota Whist has no trump
    return null;
  }

  @override
  ScoringEngine createScoringEngine() {
    return const MinnesotaWhistScoringEngineAdapter();
  }

  @override
  int get winningScore =>
      MinnesotaWhistScoringEngineAdapter.defaultWinningScore;

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
    return MinnesotaWhistBiddingWidget(context: context);
  }

  @override
  Widget? buildTrumpIndicator(TrumpIndicatorContext context) {
    // Minnesota Whist has no trump
    return null;
  }

  @override
  Widget? buildSpecialCardDisplay(SpecialCardContext context) {
    // Minnesota Whist has no special cards (no kitty or widow)
    return null;
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    final actions = <GameAction>[];

    // Minnesota Whist has straightforward game flow
    // Actions depend on the current phase
    switch (state.currentPhase) {
      case GamePhase.dealing:
        // No actions during dealing
        break;

      case GamePhase.bidding:
        // Bidding happens automatically when cards are placed
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
**Bidding**: Black card = High, Red card = Low
**Scoring High**: 1 pt/trick over 6 (x2 if failed)
**Scoring Low**: 1 pt/trick under 7
**Win**: First to 13 points
''';
  }

  @override
  String getBiddingRules() {
    return '''
# Bidding in Minnesota Whist

All 4 players simultaneously place one card face down:
• **Black card (♠ ♣)**: High bid - want to win tricks
• **Red card (♥ ♦)**: Low bid - want to lose tricks

Cards revealed in order from dealer's left:
• **First black card**: That player "granded" - HIGH hand, stop revealing
• **All red**: LOW hand - all cards revealed
''';
  }

  @override
  String getScoringRules() {
    return '''
# Scoring in Minnesota Whist

### High (Grand) Hand
• Granding team wins 7+ tricks: **1 point per trick over 6**
• Granding team wins < 7 tricks: Opponents score **2 points per trick over 6**

### Low (Nula) Hand
• Team with fewer tricks: **1 point per trick under 7**

### All Low Hand
• Team with more tricks: **Loses 1 point per trick over 6**

**Win Condition**: First team to 13 points
''';
  }

  @override
  String getRulesText() {
    return '''
# Minnesota Whist Rules

## Overview
Minnesota Whist is a trick-taking card game for 4 players in partnerships (North-South vs East-West).

## Bidding
- All 4 players simultaneously place one card face down as their bid
- **Black card** (♠ ♣): High bid - your team wants to win tricks
- **Red card** (♥ ♦): Low bid - your team wants to lose tricks
- Cards are revealed in order starting from dealer's left
- **First black card revealed**: That player "granded" - it's a HIGH hand, revealing stops
- **All red cards**: It's a LOW hand, all cards revealed

## Scoring
### High (Grand) Hand
- Granding team scores **1 point per trick over 6** if they take 7+ tricks
- Opponents score **2 points per trick over 6** if granding team takes fewer than 7 tricks

### Low (Nula) Hand
- Team with fewer tricks scores **1 point per trick under 7**
- Maximum 7 points for taking 0 tricks

### All Low Hand (all 4 players bid red)
- Team that takes more tricks **loses 1 point per trick over 6**
- Tied at 6-6: no points scored

## Winning
- First team to reach **13 points** wins
- If both teams reach 13 in same hand, highest score wins

## Play
- Standard trick-taking rules
- Must follow suit if possible
- Highest card in led suit wins the trick
- **No trump suit**
- Winner of trick leads next
''';
  }
}
