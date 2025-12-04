import 'package:flutter/material.dart';
import '../engine/game_state.dart';
import '../logic/bidding_engine.dart';
import '../logic/scoring_engine.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../../ui/context/variant_ui_context.dart';

/// Trump selection methods
enum TrumpSelectionMethod {
  none, // No trump (e.g., Minnesota Whist)
  lastCard, // Last card dealt (e.g., Classic Whist)
  bidWinner, // Bid winner declares (e.g., Bid Whist)
  randomCard, // Random card from deck (e.g., Oh Hell)
  dealerChoice, // Dealer chooses
}

/// Abstract base class for all whist variants
///
/// Each variant implements this interface to define:
/// - Game rules (bidding, trump, scoring)
/// - UI components (bidding widgets, indicators)
/// - Available actions
abstract class GameVariant {
  // ==================== METADATA ====================

  /// Display name of the variant
  String get name;

  /// Short description for variant selector (1-2 lines)
  String get shortDescription;

  /// Detailed description
  String get description;

  /// Icon for variant selector
  IconData get icon;

  // ==================== GAME LOGIC ====================

  /// Whether this variant uses a bidding phase
  bool get usesBidding;

  /// Create the bidding engine for this variant
  /// Returns null if usesBidding is false
  BiddingEngine? createBiddingEngine(Position dealer);

  /// How trump is selected in this variant
  TrumpSelectionMethod get trumpSelectionMethod;

  /// Determine trump suit based on current game state
  /// Returns null if no trump or trump not yet determined
  Suit? determineTrumpSuit(GameState state);

  /// Create the scoring engine for this variant
  ScoringEngine createScoringEngine();

  /// Points needed to win the game
  int get winningScore;

  /// Whether players can claim remaining tricks
  bool get allowsClaimingTricks;

  /// Number of tricks per hand (usually 13 for 52-card deck)
  int get tricksPerHand;

  /// Whether this variant uses special cards (kitty, widow, etc.)
  bool get hasSpecialCards;

  /// Number of special cards (kitty/widow size)
  int get specialCardCount => 0;

  /// Label for special cards area
  String get specialCardsLabel => '';

  // ==================== UI PROVIDERS ====================

  /// Build the bidding interface for this variant
  /// Returns null if variant doesn't use bidding
  Widget? buildBiddingWidget(BiddingWidgetContext context);

  /// Build the trump indicator widget
  /// Returns null if variant doesn't use trump or trump isn't revealed
  Widget? buildTrumpIndicator(TrumpIndicatorContext context);

  /// Build special card displays (kitty, widow, etc.)
  /// Returns null if variant doesn't have special card areas
  Widget? buildSpecialCardDisplay(SpecialCardContext context);

  /// Get available player actions for current game state
  /// Used to dynamically build action buttons
  List<GameAction> getAvailableActions(GameState state);

  // ==================== HELP & DOCUMENTATION ====================

  /// Get full rules text for help dialog
  String getRulesText();

  /// Get quick reference text (shown during gameplay)
  String getQuickReference();

  /// Get bidding rules specifically
  String getBiddingRules() {
    if (!usesBidding) return 'This variant does not use bidding.';
    return 'Bidding rules not specified.';
  }

  /// Get scoring rules specifically
  String getScoringRules() {
    return 'Scoring rules not specified.';
  }
}
