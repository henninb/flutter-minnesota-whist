# Complete Abstraction Layer - Code Examples

This document provides complete, copy-paste-ready code examples for the core abstraction layer. These are the foundation files that all variants will build upon.

---

## 1. Game Variant Base Class

**File:** `lib/src/game/variants/game_variant.dart`

```dart
import 'package:flutter/material.dart';
import '../engine/game_state.dart';
import '../logic/bidding_engine.dart';
import '../logic/scoring_engine.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../../ui/context/variant_ui_context.dart';

/// Trump selection methods
enum TrumpSelectionMethod {
  none,           // No trump (e.g., Minnesota Whist)
  lastCard,       // Last card dealt (e.g., Classic Whist)
  bidWinner,      // Bid winner declares (e.g., Bid Whist)
  randomCard,     // Random card from deck (e.g., Oh Hell)
  dealerChoice,   // Dealer chooses
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
```

---

## 2. Bidding Engine Base Class

**File:** `lib/src/game/logic/bidding_engine.dart`

```dart
import '../models/game_models.dart';
import '../models/card.dart';

/// Abstract base class for variant-specific bidding engines
abstract class BiddingEngine {
  const BiddingEngine({required this.dealer});

  /// The dealer for this hand
  final Position dealer;

  /// Check if bidding is complete
  bool isComplete(List<BidEntry> bids);

  /// Determine the auction result/winner
  AuctionResult determineWinner(List<BidEntry> bids);

  /// Get the next player who should bid
  /// Returns null if bidding is complete
  Position? getNextBidder(List<BidEntry> bids);

  /// Validate a bid
  /// Subclasses override to implement variant-specific validation
  BidValidation validateBid({
    required dynamic bid,
    required Position bidder,
    required List<BidEntry> currentBids,
  });
}

/// Result of bid validation
class BidValidation {
  const BidValidation._({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  factory BidValidation.valid() => const BidValidation._(isValid: true);

  factory BidValidation.invalid(String message) =>
      BidValidation._(isValid: false, errorMessage: message);
}

/// Base auction result class
/// Can be extended by variants for additional data
class AuctionResult {
  const AuctionResult._({
    required this.status,
    this.winningBid,
    this.handType,
    required this.message,
    this.additionalData,
  });

  final AuctionStatus status;
  final Bid? winningBid;
  final BidType? handType;
  final String message;
  final Map<String, dynamic>? additionalData;

  Position? get winner => winningBid?.bidder;
  Team? get winningTeam => winner?.team;

  factory AuctionResult.winner({
    required Bid winningBid,
    BidType? handType,
    required String message,
    Map<String, dynamic>? additionalData,
  }) =>
      AuctionResult._(
        status: AuctionStatus.won,
        winningBid: winningBid,
        handType: handType,
        message: message,
        additionalData: additionalData,
      );

  factory AuctionResult.incomplete({required String message}) =>
      AuctionResult._(
        status: AuctionStatus.incomplete,
        message: message,
      );

  factory AuctionResult.allPass({required String message}) =>
      AuctionResult._(
        status: AuctionStatus.allPass,
        message: message,
      );
}

enum AuctionStatus {
  incomplete, // Still waiting for bids
  won,        // Auction complete with a winner
  allPass,    // All players passed (redeal in some variants)
}
```

---

## 3. Scoring Engine Base Class

**File:** `lib/src/game/logic/scoring_engine.dart`

```dart
import '../models/game_models.dart';

/// Abstract base class for variant-specific scoring engines
abstract class ScoringEngine {
  const ScoringEngine();

  /// Score a completed hand
  ///
  /// Returns HandScore with points for each team
  /// additionalParams allows variants to pass variant-specific data
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  });

  /// Check if game is over and determine winner
  /// Returns null if game should continue
  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int? winningScore,
  });

  /// Get game over message
  String getGameOverMessage(
    GameOverStatus status,
    int scoreNS,
    int scoreEW,
  );

  /// Get description of how points were scored
  /// Used for player feedback
  String getScoreDescription(HandScore score);
}

/// Result of scoring a hand
class HandScore {
  const HandScore({
    required this.teamNSPoints,
    required this.teamEWPoints,
    required this.description,
    this.additionalData,
  });

  final int teamNSPoints;
  final int teamEWPoints;
  final String description;
  final Map<String, dynamic>? additionalData;

  @override
  String toString() => description;
}

/// Game over status
enum GameOverStatus {
  teamNSWins,
  teamEWWins,
  draw, // For variants that allow draws
}
```

---

## 4. UI Context Classes

**File:** `lib/src/ui/context/variant_ui_context.dart`

```dart
import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';

/// Context for building bidding widgets
class BiddingWidgetContext {
  const BiddingWidgetContext({
    required this.playerHand,
    required this.currentBids,
    required this.currentBidder,
    required this.onBidSubmitted,
    required this.gameState,
  });

  final List<PlayingCard> playerHand;
  final List<BidEntry> currentBids;
  final Position currentBidder;
  final Function(dynamic bid) onBidSubmitted;
  final GameState gameState;
}

/// Context for building trump indicators
class TrumpIndicatorContext {
  const TrumpIndicatorContext({
    required this.trumpSuit,
    required this.isRevealed,
    this.declarer,
    required this.gameState,
  });

  final Suit? trumpSuit;
  final bool isRevealed;
  final Position? declarer;
  final GameState gameState;
}

/// Context for special card displays (kitty, widow)
class SpecialCardContext {
  const SpecialCardContext({
    required this.cards,
    required this.isRevealed,
    required this.label,
    this.onCardsSelected,
    required this.gameState,
  });

  final List<PlayingCard> cards;
  final bool isRevealed;
  final String label;
  final Function(List<PlayingCard>)? onCardsSelected;
  final GameState gameState;
}

/// Represents an action the player can take
class GameAction {
  const GameAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.disabledReason,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? disabledReason;
}
```

---

## 5. Variant Type Enum with Factory

**File:** `lib/src/game/variants/variant_type.dart`

```dart
import 'game_variant.dart';
import 'minnesota_whist_variant.dart';
import 'classic_whist_variant.dart';
import 'bid_whist_variant.dart';
import 'oh_hell_variant.dart';
import 'widow_whist_variant.dart';

/// Enumeration of all supported whist variants
enum VariantType {
  minnesotaWhist,
  classicWhist,
  bidWhist,
  ohHell,
  widowWhist,
}

extension VariantTypeExtension on VariantType {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case VariantType.minnesotaWhist:
        return 'Minnesota Whist';
      case VariantType.classicWhist:
        return 'Classic Whist';
      case VariantType.bidWhist:
        return 'Bid Whist';
      case VariantType.ohHell:
        return 'Oh Hell';
      case VariantType.widowWhist:
        return 'Widow Whist';
    }
  }

  /// Short description for variant selector
  String get shortDescription {
    switch (this) {
      case VariantType.minnesotaWhist:
        return 'Simultaneous bidding with black/red cards. No trump.';
      case VariantType.classicWhist:
        return 'Traditional whist with fixed trump and simple scoring.';
      case VariantType.bidWhist:
        return 'Sequential bidding with kitty, trump declaration.';
      case VariantType.ohHell:
        return 'Bid exact number of tricks. Precision scoring.';
      case VariantType.widowWhist:
        return 'Bid for widow rights. Exchange and play.';
    }
  }

  /// Factory method to create variant instance
  GameVariant createVariant() {
    switch (this) {
      case VariantType.minnesotaWhist:
        return MinnesotaWhistVariant();
      case VariantType.classicWhist:
        return ClassicWhistVariant();
      case VariantType.bidWhist:
        return BidWhistVariant();
      case VariantType.ohHell:
        return OhHellVariant();
      case VariantType.widowWhist:
        return WidowWhistVariant();
    }
  }

  /// Get variant from name (for serialization)
  static VariantType fromName(String name) {
    return VariantType.values.firstWhere(
      (v) => v.name == name,
      orElse: () => VariantType.minnesotaWhist,
    );
  }
}
```

---

## 6. Updated GameState

**File:** `lib/src/game/engine/game_state.dart` (additions only)

```dart
// Add these fields to existing GameState class:

class GameState {
  // ... existing fields ...

  // Variant support
  final VariantType variantType;

  // UI-related fields for variants
  final List<PlayingCard>? specialCards;        // Kitty, widow, etc.
  final String? specialCardsLabel;              // "Kitty", "Widow"
  final bool? specialCardsRevealed;
  final bool? trumpRevealed;

  // Computed property
  GameVariant get variant => variantType.createVariant();

  const GameState({
    // ... existing parameters ...
    this.variantType = VariantType.minnesotaWhist,
    this.specialCards,
    this.specialCardsLabel,
    this.specialCardsRevealed,
    this.trumpRevealed,
  });

  GameState copyWith({
    // ... existing parameters ...
    VariantType? variantType,
    List<PlayingCard>? specialCards,
    String? specialCardsLabel,
    bool? specialCardsRevealed,
    bool? trumpRevealed,
    bool clearSpecialCards = false,
  }) {
    return GameState(
      // ... existing fields ...
      variantType: variantType ?? this.variantType,
      specialCards: clearSpecialCards ? null : (specialCards ?? this.specialCards),
      specialCardsLabel: specialCardsLabel ?? this.specialCardsLabel,
      specialCardsRevealed: specialCardsRevealed ?? this.specialCardsRevealed,
      trumpRevealed: trumpRevealed ?? this.trumpRevealed,
    );
  }
}
```

---

## 7. Example Variant Implementation - Minnesota Whist

**File:** `lib/src/game/variants/minnesota_whist_variant.dart`

```dart
import 'package:flutter/material.dart';
import 'game_variant.dart';
import '../engine/game_state.dart';
import '../logic/bidding_engine.dart';
import '../logic/scoring_engine.dart';
import '../logic/minnesota_whist_bidding_engine.dart';
import '../logic/minnesota_whist_scorer.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../../ui/context/variant_ui_context.dart';
import '../../ui/widgets/variants/minnesota_bidding_widget.dart';

class MinnesotaWhistVariant extends GameVariant {
  // ==================== METADATA ====================

  @override
  String get name => 'Minnesota Whist';

  @override
  String get shortDescription =>
      'Simultaneous bidding with black/red cards. No trump. First to 13 points wins.';

  @override
  String get description =>
      'Players simultaneously place bid cards (black=HIGH, red=LOW). '
      'Cards revealed in order from dealer\'s left. First black card stops revealing. '
      'No trump suit. Simple trick-taking.';

  @override
  IconData get icon => Icons.filter_vintage;

  // ==================== GAME LOGIC ====================

  @override
  bool get usesBidding => true;

  @override
  BiddingEngine? createBiddingEngine(Position dealer) {
    return MinnesotaWhistBiddingEngine(dealer: dealer);
  }

  @override
  TrumpSelectionMethod get trumpSelectionMethod => TrumpSelectionMethod.none;

  @override
  Suit? determineTrumpSuit(GameState state) => null; // No trump

  @override
  ScoringEngine createScoringEngine() {
    return MinnesotaWhistScoringEngine();
  }

  @override
  int get winningScore => 13;

  @override
  bool get allowsClaimingTricks => true;

  @override
  int get tricksPerHand => 13;

  @override
  bool get hasSpecialCards => false;

  // ==================== UI PROVIDERS ====================

  @override
  Widget? buildBiddingWidget(BiddingWidgetContext context) {
    return MinnesotaBiddingWidget(context: context);
  }

  @override
  Widget? buildTrumpIndicator(TrumpIndicatorContext context) {
    // Minnesota Whist has no trump
    return null;
  }

  @override
  Widget? buildSpecialCardDisplay(SpecialCardContext context) {
    // Minnesota Whist has no kitty/widow
    return null;
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    // Minnesota Whist has no special variant-specific actions
    return [];
  }

  // ==================== HELP & DOCUMENTATION ====================

  @override
  String getRulesText() {
    return '''
Minnesota Whist Rules

OBJECTIVE:
First team to reach 13 points wins

BIDDING:
1. All 4 players simultaneously place one card face-down
2. Black card (♠♣) = HIGH bid (want to win tricks)
3. Red card (♥♦) = LOW bid (want to lose tricks)
4. Cards revealed starting from dealer's left
5. First black card ends revealing - that player "granded"
6. If all red cards, it's a LOW hand (special scoring)

PLAY:
- No trump suit
- Grander (or first player if all low) leads first
- Follow suit if possible
- Highest card of led suit wins trick
- Winner leads next trick

SCORING:
High (Grand) Hand:
  - Granding team wins 7+ tricks: +1 point per trick over 6
  - Granding team wins <7 tricks: Opponents get +2 per trick over 6

Low (Nula) Hand:
  - Granding team wins ≤6 tricks: +1 point per trick under 7
  - Granding team wins 7+ tricks: Opponents get +1 per trick under 7

All Red (no one granded):
  - Team that wins more tricks loses 1 point per trick over 6

STRATEGY:
- Use your lowest card of chosen color to preserve hand strength
- High bidders (black) try to take control
- Low bidders (red) try to dump high cards
    ''';
  }

  @override
  String getQuickReference() {
    return 'No trump • BLACK=High, RED=Low • Grander leads • First to 13 wins';
  }

  @override
  String getBiddingRules() {
    return '''
Simultaneous card bidding:
• Black (♠♣) = HIGH - want to win tricks
• Red (♥♦) = LOW - want to lose tricks
• Reveal from dealer's left
• First black card wins (grander)
• All red = special LOW hand

Tip: Bid with your lowest card of chosen color!
    ''';
  }

  @override
  String getScoringRules() {
    return '''
HIGH hand: 1 pt/trick over 6 (or 2× if fail)
LOW hand: 1 pt/trick under 7 (or 1× if fail)
All RED: -1 pt/trick over 6 for winning team
First to 13 points wins!
    ''';
  }
}
```

---

## 8. Example Minimal Variant - Classic Whist

**File:** `lib/src/game/variants/classic_whist_variant.dart`

```dart
import 'package:flutter/material.dart';
import 'game_variant.dart';
import '../engine/game_state.dart';
import '../logic/bidding_engine.dart';
import '../logic/scoring_engine.dart';
import '../logic/classic_whist_scorer.dart';
import '../models/card.dart';
import '../models/game_models.dart';
import '../../ui/context/variant_ui_context.dart';
import '../../ui/widgets/trump_indicator.dart';

class ClassicWhistVariant extends GameVariant {
  // ==================== METADATA ====================

  @override
  String get name => 'Classic Whist';

  @override
  String get shortDescription =>
      'Traditional whist. Last card determines trump. Simple scoring.';

  @override
  String get description =>
      'Traditional trick-taking game. Trump suit determined by last card dealt. '
      'Simple scoring: 1 point per trick over 6.';

  @override
  IconData get icon => Icons.history;

  // ==================== GAME LOGIC ====================

  @override
  bool get usesBidding => false; // No bidding in classic whist

  @override
  BiddingEngine? createBiddingEngine(Position dealer) => null;

  @override
  TrumpSelectionMethod get trumpSelectionMethod => TrumpSelectionMethod.lastCard;

  @override
  Suit? determineTrumpSuit(GameState state) {
    // Trump is the suit of the last card dealt (dealer's last card)
    if (state.getHand(state.dealer).isEmpty) return null;
    final dealerHand = state.getHand(state.dealer);
    return dealerHand.last.suit;
  }

  @override
  ScoringEngine createScoringEngine() {
    return ClassicWhistScoringEngine();
  }

  @override
  int get winningScore => 5; // Traditional: 5 game points

  @override
  bool get allowsClaimingTricks => true;

  @override
  int get tricksPerHand => 13;

  @override
  bool get hasSpecialCards => false;

  // ==================== UI PROVIDERS ====================

  @override
  Widget? buildBiddingWidget(BiddingWidgetContext context) {
    // No bidding in classic whist
    return null;
  }

  @override
  Widget? buildTrumpIndicator(TrumpIndicatorContext context) {
    return DefaultTrumpIndicator(context: context);
  }

  @override
  Widget? buildSpecialCardDisplay(SpecialCardContext context) {
    return null;
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    return [];
  }

  // ==================== HELP & DOCUMENTATION ====================

  @override
  String getRulesText() {
    return '''
Classic Whist Rules

OBJECTIVE:
First team to reach 5 game points wins

SETUP:
- No bidding phase
- Trump suit is determined by last card dealt to dealer
- Dealer leads first trick

PLAY:
- Must follow suit if possible
- Highest trump wins, or highest card of led suit
- Winner leads next trick

SCORING:
- Team that wins 7+ tricks scores 1 game point per trick over 6
- First team to 5 game points wins

HISTORY:
Classic Whist is the original form of whist, dating back to the 17th century.
It's the foundation for many modern trick-taking games.
    ''';
  }

  @override
  String getQuickReference() {
    return 'Last card = trump • Dealer leads • 1 pt per trick over 6 • First to 5 wins';
  }
}
```

---

## Usage Example in GameEngine

**File:** `lib/src/game/engine/game_engine.dart` (excerpt)

```dart
void _startBidding() {
  final variant = _state.variant;

  // Check if variant uses bidding
  if (!variant.usesBidding) {
    _debugLog('Variant ${variant.name} does not use bidding - skipping to play');
    _startPlay();
    return;
  }

  _debugLog('Starting bidding for ${variant.name}');

  _updateState(
    _state.copyWith(
      currentPhase: GamePhase.bidding,
      isBiddingPhase: true,
      bidHistory: [],
      gameStatus: 'Bidding in progress',
      showBiddingDialog: true,
    ),
  );
}

void submitBid(dynamic bid) {
  final biddingEngine = _state.variant.createBiddingEngine(_state.dealer);

  if (biddingEngine == null) {
    _debugLog('ERROR: Variant has no bidding engine but submitBid called');
    return;
  }

  // Validate bid using variant's bidding engine
  final validation = biddingEngine.validateBid(
    bid: bid,
    bidder: Position.south,
    currentBids: _state.bidHistory,
  );

  if (!validation.isValid) {
    _updateState(_state.copyWith(
      gameStatus: validation.errorMessage ?? 'Invalid bid',
    ));
    return;
  }

  // Create bid entry (variant-specific)
  final entry = BidEntry(
    bidder: Position.south,
    bid: bid is Bid ? bid : Bid(bidType: BidType.high, bidder: Position.south),
  );

  _addBidEntry(entry);

  // Check if bidding complete
  if (biddingEngine.isComplete(_state.bidHistory)) {
    _finalizeBidding();
  }
}

void _scoreHand() {
  final scoringEngine = _state.variant.createScoringEngine();

  final handScore = scoringEngine.scoreHand(
    handType: _state.handType,
    contractingTeam: _state.contractor?.team,
    tricksWonByContractingTeam: _state.getTricksWon(_state.contractor?.team ?? Team.northSouth),
  );

  // Apply scores
  final newScoreNS = _state.teamNorthSouthScore + handScore.teamNSPoints;
  final newScoreEW = _state.teamEastWestScore + handScore.teamEWPoints;

  _updateState(_state.copyWith(
    teamNorthSouthScore: newScoreNS,
    teamEastWestScore: newScoreEW,
    gameStatus: handScore.description,
  ));

  // Check game over
  final gameOverStatus = scoringEngine.checkGameOver(
    teamNSScore: newScoreNS,
    teamEWScore: newScoreEW,
    winningScore: _state.variant.winningScore,
  );

  if (gameOverStatus != null) {
    _handleGameOver(gameOverStatus, newScoreNS, newScoreEW);
  }
}
```

---

## Summary

These base classes provide:

✅ **Clear contracts** - Each variant knows exactly what to implement
✅ **Type safety** - Dart's type system ensures compliance
✅ **UI flexibility** - Variants control their own UI components
✅ **Game logic encapsulation** - Each variant owns its rules
✅ **Easy testing** - Mock implementations for testing
✅ **Future extensibility** - New variants just implement the interface

The abstraction layer is designed to be:
- **Minimal** - Only abstract what actually varies between variants
- **Flexible** - Support widely different game mechanics
- **Type-safe** - Leverage Dart's type system
- **Testable** - Clear boundaries for unit testing
- **Maintainable** - Changes to one variant don't affect others
