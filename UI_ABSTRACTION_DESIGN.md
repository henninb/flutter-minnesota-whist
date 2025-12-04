# UI Abstraction Design for Whist Variants

## Overview
This document details the UI abstraction layer needed to support multiple whist variants. Each variant has different UI requirements for bidding, trump display, and game flow. We'll use a combination of **Factory Pattern**, **Strategy Pattern**, and **Widget Composition** to create flexible, variant-specific UIs.

---

## Core Principle: Variants Control Their UI

Each `GameVariant` not only defines game logic but also **provides UI components** for variant-specific interactions:

```dart
abstract class GameVariant {
  // ... existing methods ...

  // UI Providers
  Widget buildBiddingWidget(BiddingWidgetContext context);
  Widget? buildTrumpIndicator(TrumpIndicatorContext context);
  Widget? buildSpecialCardDisplay(SpecialCardContext context); // kitty, widow, etc.
  List<GameAction> getAvailableActions(GameState state);
}
```

---

## UI Abstraction Layers

### Layer 1: Game Variant Interface (Extended)

**File:** `lib/src/game/variants/game_variant.dart`

```dart
import 'package:flutter/material.dart';
import '../engine/game_state.dart';

abstract class GameVariant {
  // === METADATA ===
  String get name;
  String get description;
  String get shortDescription; // For variant selector cards
  IconData get icon;

  // === GAME LOGIC ===
  bool get usesBidding;
  BiddingEngine? createBiddingEngine(Position dealer);

  TrumpSelectionMethod get trumpSelectionMethod;
  Suit? determineTrumpSuit(GameState state);

  ScoringEngine createScoringEngine();
  int get winningScore;

  bool get allowsClaimingTricks;
  int get tricksPerHand;

  // === UI PROVIDERS ===

  /// Build the bidding interface for this variant
  /// Returns null if variant doesn't use bidding (e.g., Classic Whist)
  Widget? buildBiddingWidget(BiddingWidgetContext context);

  /// Build the trump indicator widget
  /// Returns null if variant doesn't use trump or trump isn't revealed yet
  Widget? buildTrumpIndicator(TrumpIndicatorContext context);

  /// Build special card displays (kitty, widow, etc.)
  /// Returns null if variant doesn't have special card areas
  Widget? buildSpecialCardDisplay(SpecialCardContext context);

  /// Get available player actions for current game state
  /// Used to dynamically build action buttons
  List<GameAction> getAvailableActions(GameState state);

  /// Get help/rules text for this variant
  String getRulesText();

  /// Get quick reference (shown during gameplay)
  String getQuickReference();
}
```

---

### Layer 2: UI Context Objects

**File:** `lib/src/ui/context/variant_ui_context.dart` (new)

Context objects provide all the data and callbacks UI widgets need:

```dart
/// Context for building bidding widgets
class BiddingWidgetContext {
  final List<PlayingCard> playerHand;
  final List<BidEntry> currentBids;
  final Position currentBidder;
  final Function(dynamic bid) onBidSubmitted;
  final GameState gameState;

  const BiddingWidgetContext({
    required this.playerHand,
    required this.currentBids,
    required this.currentBidder,
    required this.onBidSubmitted,
    required this.gameState,
  });
}

/// Context for building trump indicators
class TrumpIndicatorContext {
  final Suit? trumpSuit;
  final bool isRevealed;
  final Position? declarer; // Who declared trump
  final GameState gameState;

  const TrumpIndicatorContext({
    required this.trumpSuit,
    required this.isRevealed,
    this.declarer,
    required this.gameState,
  });
}

/// Context for special card displays (kitty, widow)
class SpecialCardContext {
  final List<PlayingCard> cards;
  final bool isRevealed;
  final String label; // "Kitty", "Widow", etc.
  final Function(List<PlayingCard>)? onCardsSelected;
  final GameState gameState;

  const SpecialCardContext({
    required this.cards,
    required this.isRevealed,
    required this.label,
    this.onCardsSelected,
    required this.gameState,
  });
}

/// Represents an action the player can take
class GameAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? disabledReason;

  const GameAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.disabledReason,
  });
}
```

---

### Layer 3: Variant-Specific Bidding Widgets

Each variant provides its own bidding widget implementation:

#### Minnesota Whist Bidding Widget
**File:** `lib/src/ui/widgets/variants/minnesota_bidding_widget.dart` (new)

```dart
class MinnesotaBiddingWidget extends StatefulWidget {
  final BiddingWidgetContext context;

  const MinnesotaBiddingWidget({
    super.key,
    required this.context,
  });

  @override
  State<MinnesotaBiddingWidget> createState() => _MinnesotaBiddingWidgetState();
}

class _MinnesotaBiddingWidgetState extends State<MinnesotaBiddingWidget> {
  PlayingCard? _selectedCard;

  @override
  Widget build(BuildContext context) {
    // Current implementation from BiddingInterface
    // Shows black cards (HIGH) and red cards (LOW) sections
    // User taps card to select
    // Callback: widget.context.onBidSubmitted(_selectedCard)
  }
}
```

#### Bid Whist Bidding Widget
**File:** `lib/src/ui/widgets/variants/bid_whist_bidding_widget.dart` (new)

```dart
class BidWhistBiddingWidget extends StatefulWidget {
  final BiddingWidgetContext context;

  const BidWhistBiddingWidget({
    super.key,
    required this.context,
  });

  @override
  State<BidWhistBiddingWidget> createState() => _BidWhistBiddingWidgetState();
}

class _BidWhistBiddingWidgetState extends State<BidWhistBiddingWidget> {
  int? _selectedTricks; // 3-7
  Suit? _selectedSuit; // or null for no-trump
  BidWhistDirection? _selectedDirection; // uptown or downtown

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Number of tricks selector (3-7)
        _buildTricksSelector(),

        // Suit selector (spades, hearts, diamonds, clubs, no-trump)
        _buildSuitSelector(),

        // Uptown/Downtown selector
        _buildDirectionSelector(),

        // Submit button
        ElevatedButton(
          onPressed: _canSubmit ? _submitBid : null,
          child: Text('Place Bid'),
        ),
      ],
    );
  }

  void _submitBid() {
    final bid = BidWhistBid(
      tricks: _selectedTricks!,
      suit: _selectedSuit,
      direction: _selectedDirection!,
    );
    widget.context.onBidSubmitted(bid);
  }
}
```

#### Oh Hell Bidding Widget
**File:** `lib/src/ui/widgets/variants/oh_hell_bidding_widget.dart` (new)

```dart
class OhHellBiddingWidget extends StatefulWidget {
  final BiddingWidgetContext context;

  const OhHellBiddingWidget({
    super.key,
    required this.context,
  });

  @override
  State<OhHellBiddingWidget> createState() => _OhHellBiddingWidgetState();
}

class _OhHellBiddingWidgetState extends State<OhHellBiddingWidget> {
  int _selectedTricks = 0;

  @override
  Widget build(BuildContext context) {
    final maxTricks = widget.context.playerHand.length;
    final totalBidsSoFar = widget.context.currentBids
        .map((e) => (e.bid as OhHellBid).tricks)
        .fold(0, (a, b) => a + b);
    final isDealer = widget.context.currentBidder == widget.context.gameState.dealer;
    final forbiddenBid = isDealer ? (maxTricks - totalBidsSoFar) : null;

    return Column(
      children: [
        // Instructions
        Text(
          'Bid exactly how many tricks you will take',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        if (forbiddenBid != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'As dealer, you cannot bid $forbiddenBid (would make total = $maxTricks)',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),

        // Number picker (0 to maxTricks)
        SizedBox(
          height: 150,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            onSelectedItemChanged: (index) {
              setState(() => _selectedTricks = index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final isForbidden = index == forbiddenBid;
                return Center(
                  child: Text(
                    '$index tricks',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: index == _selectedTricks ? FontWeight.bold : FontWeight.normal,
                      color: isForbidden ? Colors.grey : Colors.black,
                      decoration: isForbidden ? TextDecoration.lineThrough : null,
                    ),
                  ),
                );
              },
              childCount: maxTricks + 1,
            ),
          ),
        ),

        // Submit button
        ElevatedButton(
          onPressed: (_selectedTricks != forbiddenBid) ? _submitBid : null,
          child: Text('Bid $_selectedTricks Tricks'),
        ),
      ],
    );
  }

  void _submitBid() {
    final bid = OhHellBid(tricks: _selectedTricks);
    widget.context.onBidSubmitted(bid);
  }
}
```

#### Classic Whist (No Bidding Widget)
**File:** `lib/src/game/variants/classic_whist_variant.dart`

```dart
@override
Widget? buildBiddingWidget(BiddingWidgetContext context) {
  // Classic Whist has no bidding
  return null;
}
```

---

### Layer 4: Unified Bidding Container

**File:** `lib/src/ui/widgets/overlays/bidding_overlay.dart` (refactor existing)

This replaces the current `bidding_dialog.dart` and `bidding_bottom_sheet.dart`:

```dart
class BiddingOverlay extends StatelessWidget {
  final GameState gameState;
  final Function(dynamic bid) onBidSubmitted;

  const BiddingOverlay({
    super.key,
    required this.gameState,
    required this.onBidSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Get the active variant from game state
    final variant = gameState.variant;

    // If variant doesn't use bidding, return empty
    if (!variant.usesBidding) {
      return const SizedBox.shrink();
    }

    // Build context for bidding widget
    final biddingContext = BiddingWidgetContext(
      playerHand: gameState.playerHand,
      currentBids: gameState.bidHistory,
      currentBidder: gameState.currentBidder ?? Position.south,
      onBidSubmitted: onBidSubmitted,
      gameState: gameState,
    );

    // Get variant-specific bidding widget
    final biddingWidget = variant.buildBiddingWidget(biddingContext);

    if (biddingWidget == null) {
      return const SizedBox.shrink();
    }

    // Wrap in standard modal bottom sheet UI
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),

          // Variant-specific bidding widget
          Flexible(child: biddingWidget),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.gavel, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Place Your Bid',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showBiddingHelp(context),
          ),
        ],
      ),
    );
  }

  void _showBiddingHelp(BuildContext context) {
    // Show variant-specific bidding rules
    final rulesText = gameState.variant.getRulesText();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${gameState.variant.name} Bidding Rules'),
        content: SingleChildScrollView(
          child: Text(rulesText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
```

---

### Layer 5: Trump Indicator Abstraction

**File:** `lib/src/ui/widgets/trump_indicator.dart` (new)

```dart
class TrumpIndicator extends StatelessWidget {
  final GameState gameState;

  const TrumpIndicator({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    final variant = gameState.variant;

    // Build context
    final trumpContext = TrumpIndicatorContext(
      trumpSuit: gameState.trumpSuit,
      isRevealed: gameState.trumpRevealed ?? true,
      declarer: gameState.contractor,
      gameState: gameState,
    );

    // Get variant-specific trump indicator
    final trumpWidget = variant.buildTrumpIndicator(trumpContext);

    // If no trump widget (variant doesn't use trump), return empty
    if (trumpWidget == null) {
      return const SizedBox.shrink();
    }

    return trumpWidget;
  }
}

/// Default trump indicator implementation
/// Variants can use this or provide their own
class DefaultTrumpIndicator extends StatelessWidget {
  final TrumpIndicatorContext context;

  const DefaultTrumpIndicator({
    super.key,
    required this.context,
  });

  @override
  Widget build(BuildContext buildContext) {
    if (!context.isRevealed || context.trumpSuit == null) {
      return const SizedBox.shrink();
    }

    final suit = context.trumpSuit!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(buildContext).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(buildContext).colorScheme.tertiary,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Trump:',
            style: Theme.of(buildContext).textTheme.titleSmall,
          ),
          const SizedBox(width: 8),
          Text(
            suit.symbol,
            style: TextStyle(
              fontSize: 24,
              color: suit.color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            suit.name.toUpperCase(),
            style: Theme.of(buildContext).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: suit.color,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Layer 6: Special Card Display Abstraction

**File:** `lib/src/ui/widgets/special_card_display.dart` (new)

For kitty, widow, and other special card areas:

```dart
class SpecialCardDisplay extends StatelessWidget {
  final GameState gameState;
  final String label;
  final List<PlayingCard> cards;
  final bool isRevealed;
  final Function(List<PlayingCard>)? onCardsSelected;

  const SpecialCardDisplay({
    super.key,
    required this.gameState,
    required this.label,
    required this.cards,
    this.isRevealed = false,
    this.onCardsSelected,
  });

  @override
  Widget build(BuildContext context) {
    final variant = gameState.variant;

    final specialCardContext = SpecialCardContext(
      cards: cards,
      isRevealed: isRevealed,
      label: label,
      onCardsSelected: onCardsSelected,
      gameState: gameState,
    );

    final widget = variant.buildSpecialCardDisplay(specialCardContext);

    if (widget == null) {
      return const SizedBox.shrink();
    }

    return widget;
  }
}

/// Default implementation for kitty/widow display
class DefaultKittyDisplay extends StatelessWidget {
  final SpecialCardContext context;

  const DefaultKittyDisplay({
    super.key,
    required this.context,
  });

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(buildContext).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(buildContext).colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Text(
            context.label,
            style: Theme.of(buildContext).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: context.cards.map((card) {
              if (!context.isRevealed) {
                // Show card backs
                return _CardBack(width: 40, height: 56);
              }
              // Show actual cards
              return _MiniCard(card: card, width: 40, height: 56);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
```

---

### Layer 7: Dynamic Action Bar

**File:** `lib/src/ui/widgets/action_bar.dart` (refactor existing)

The action bar dynamically shows actions based on variant and game state:

```dart
class ActionBar extends StatelessWidget {
  final GameState gameState;
  final VoidCallback? onDeal;
  final VoidCallback? onCutForDeal;
  final VoidCallback? onConfirmBid;
  final VoidCallback? onNextHand;
  final VoidCallback? onClaimTricks;
  // ... other callbacks ...

  const ActionBar({
    super.key,
    required this.gameState,
    this.onDeal,
    this.onCutForDeal,
    this.onConfirmBid,
    this.onNextHand,
    this.onClaimTricks,
  });

  @override
  Widget build(BuildContext context) {
    // Get variant-specific actions
    final variantActions = gameState.variant?.getAvailableActions(gameState) ?? [];

    // Combine with standard actions
    final allActions = [
      ..._getStandardActions(),
      ...variantActions,
    ];

    // Filter to only enabled actions
    final enabledActions = allActions.where((a) => a.isEnabled).toList();

    if (enabledActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: enabledActions.map((action) {
          return _ActionButton(action: action);
        }).toList(),
      ),
    );
  }

  List<GameAction> _getStandardActions() {
    final actions = <GameAction>[];

    // Cut for deal
    if (gameState.currentPhase == GamePhase.setup && !gameState.cutComplete) {
      actions.add(GameAction(
        label: 'Cut for Deal',
        icon: Icons.shuffle,
        onTap: onCutForDeal ?? () {},
        isEnabled: onCutForDeal != null,
      ));
    }

    // Deal
    if (gameState.currentPhase == GamePhase.setup && gameState.cutComplete) {
      actions.add(GameAction(
        label: 'Deal',
        icon: Icons.style,
        onTap: onDeal ?? () {},
        isEnabled: onDeal != null,
      ));
    }

    // Confirm bid (only if variant uses bidding)
    if (gameState.currentPhase == GamePhase.bidding &&
        gameState.variant?.usesBidding == true &&
        gameState.pendingBidCard != null) {
      actions.add(GameAction(
        label: 'Confirm Bid',
        icon: Icons.check,
        onTap: onConfirmBid ?? () {},
        isEnabled: onConfirmBid != null,
      ));
    }

    // Claim tricks (only if variant allows)
    if (gameState.currentPhase == GamePhase.play &&
        gameState.variant?.allowsClaimingTricks == true &&
        gameState.canPlayerClaimRemainingTricks) {
      actions.add(GameAction(
        label: 'Claim Remaining Tricks',
        icon: Icons.bolt,
        onTap: onClaimTricks ?? () {},
        isEnabled: onClaimTricks != null,
      ));
    }

    // Next hand
    if (gameState.currentPhase == GamePhase.scoring) {
      actions.add(GameAction(
        label: 'Next Hand',
        icon: Icons.arrow_forward,
        onTap: onNextHand ?? () {},
        isEnabled: onNextHand != null,
      ));
    }

    return actions;
  }
}

class _ActionButton extends StatelessWidget {
  final GameAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.disabledReason ?? '',
      child: ElevatedButton.icon(
        onPressed: action.isEnabled ? action.onTap : null,
        icon: Icon(action.icon),
        label: Text(action.label),
      ),
    );
  }
}
```

---

## Variant Implementation Examples

### Minnesota Whist Variant (UI Methods)

**File:** `lib/src/game/variants/minnesota_whist_variant.dart`

```dart
class MinnesotaWhistVariant extends GameVariant {
  // ... existing logic methods ...

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
    // Minnesota Whist has no special actions beyond standard ones
    return [];
  }

  @override
  String getRulesText() {
    return '''
Minnesota Whist Bidding Rules:

1. All 4 players simultaneously place one card face-down
2. Black card (♠♣) = HIGH bid (want to win tricks)
3. Red card (♥♦) = LOW bid (want to lose tricks)
4. Cards revealed starting from dealer's left
5. First black card ends revealing (that player "granded")
6. If all red cards, it's a LOW hand

Strategy: Use your lowest card of the chosen color to preserve hand strength!
    ''';
  }

  @override
  String getQuickReference() {
    return 'No trump • BLACK=High, RED=Low • First to 13 points wins';
  }
}
```

### Bid Whist Variant (UI Methods)

**File:** `lib/src/game/variants/bid_whist_variant.dart`

```dart
class BidWhistVariant extends GameVariant {
  // ... existing logic methods ...

  @override
  Widget? buildBiddingWidget(BiddingWidgetContext context) {
    return BidWhistBiddingWidget(context: context);
  }

  @override
  Widget? buildTrumpIndicator(TrumpIndicatorContext context) {
    // Show trump if declared
    if (context.trumpSuit == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const Text('No Trump', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return DefaultTrumpIndicator(context: context);
  }

  @override
  Widget? buildSpecialCardDisplay(SpecialCardContext context) {
    // Show kitty
    return DefaultKittyDisplay(context: context);
  }

  @override
  List<GameAction> getAvailableActions(GameState state) {
    final actions = <GameAction>[];

    // Declare trump (after winning bid)
    if (state.currentPhase == GamePhase.biddingComplete &&
        state.trumpSuit == null &&
        state.contractor == Position.south) {
      actions.add(GameAction(
        label: 'Declare Trump',
        icon: Icons.flag,
        onTap: () => _showTrumpDeclarationDialog(state),
        isEnabled: true,
      ));
    }

    // Exchange kitty (after declaring trump)
    if (state.currentPhase == GamePhase.kittyExchange &&
        state.contractor == Position.south) {
      actions.add(GameAction(
        label: 'Exchange Kitty',
        icon: Icons.swap_horiz,
        onTap: () => _showKittyExchangeDialog(state),
        isEnabled: true,
      ));
    }

    return actions;
  }

  @override
  String getRulesText() {
    return '''
Bid Whist Bidding Rules:

1. Bid the number of tricks (3-7) your team will take
2. Choose a trump suit OR bid no-trump
3. Choose Uptown (Ace high) or Downtown (2 high, Ace low)
4. Higher bids beat lower bids
5. High bidder takes the 6-card kitty
6. High bidder declares final trump and exchanges kitty

Example: "4 Spades Uptown" means 4 tricks, spades trump, Ace high
    ''';
  }

  @override
  String getQuickReference() {
    return 'Sequential bidding • Kitty to winner • First to 7 points wins';
  }
}
```

---

## Game Engine Integration

**File:** `lib/src/game/engine/game_engine.dart` (updates)

The game engine delegates UI creation to variants:

```dart
class GameEngine extends ChangeNotifier {
  // ... existing code ...

  void _startBidding() {
    // Check if variant uses bidding
    if (!_state.variant.usesBidding) {
      // Skip directly to play phase
      _startPlay();
      return;
    }

    _updateState(
      _state.copyWith(
        currentPhase: GamePhase.bidding,
        isBiddingPhase: true,
        bidHistory: [],
        gameStatus: 'Bidding in progress',
        showBiddingDialog: true, // This triggers BiddingOverlay to show
      ),
    );
  }

  // Handle variant-specific bid submissions
  void submitBid(dynamic bid) {
    final biddingEngine = _state.variant.createBiddingEngine(_state.dealer);

    // Variant's bidding engine handles validation and processing
    // bid could be:
    // - PlayingCard (Minnesota Whist)
    // - BidWhistBid (Bid Whist)
    // - OhHellBid (Oh Hell)
    // - etc.

    // ... rest of bidding logic delegated to variant's engine
  }
}
```

---

## Main Game Screen Integration

**File:** `lib/src/ui/screens/game_screen.dart` (updates)

```dart
class GameScreen extends StatelessWidget {
  final GameEngine engine;

  const GameScreen({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final state = engine.state;

        return Scaffold(
          body: Stack(
            children: [
              // Main game board
              PersistentGameBoard(state: state, engine: engine),

              // Trump indicator (variant-specific, shown when applicable)
              if (state.isPlayPhase)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TrumpIndicator(gameState: state),
                  ),
                ),

              // Special card display (kitty, widow - variant-specific)
              if (state.specialCards != null && state.specialCards!.isNotEmpty)
                Positioned(
                  top: 100,
                  right: 16,
                  child: SpecialCardDisplay(
                    gameState: state,
                    label: state.specialCardsLabel ?? 'Cards',
                    cards: state.specialCards!,
                    isRevealed: state.specialCardsRevealed ?? false,
                  ),
                ),

              // Status bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: StatusBar(state: state),
              ),

              // Action bar (dynamically built by variant)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ActionBar(
                  gameState: state,
                  onDeal: () => engine.dealCards(),
                  onCutForDeal: () => engine.cutForDeal(),
                  onConfirmBid: () => engine.confirmBid(),
                  onNextHand: () => engine.startNextHand(),
                  onClaimTricks: () => engine.claimRemainingTricks(),
                ),
              ),

              // Bidding overlay (variant-specific widget)
              if (state.showBiddingDialog)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BiddingOverlay(
                    gameState: state,
                    onBidSubmitted: (bid) => engine.submitBid(bid),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## Additional GameState Fields

**File:** `lib/src/game/engine/game_state.dart` (additions)

```dart
class GameState {
  // ... existing fields ...

  // UI-related fields for variants
  final List<PlayingCard>? specialCards; // Kitty, widow, etc.
  final String? specialCardsLabel; // "Kitty", "Widow"
  final bool? specialCardsRevealed;
  final bool? trumpRevealed;

  // ... copyWith, etc.
}
```

---

## Summary of UI Abstraction Benefits

### ✅ **Encapsulation**
- Each variant owns its UI components
- UI logic lives with game logic
- Easy to add new variants without touching existing code

### ✅ **Flexibility**
- Variants can have completely different UIs
- No need for massive if/else chains in main UI code
- Context objects provide clean data contracts

### ✅ **Reusability**
- Default implementations (DefaultTrumpIndicator, DefaultKittyDisplay)
- Variants can reuse or customize as needed
- Shared UI components (action bar, overlays) work for all variants

### ✅ **Testability**
- UI components can be tested independently
- Mock contexts for widget testing
- Clear separation of concerns

### ✅ **Maintainability**
- Adding a new variant only requires implementing the variant interface
- UI changes localized to specific variant files
- Main game screen remains clean and simple

---

## Implementation Checklist

- [ ] Create UI context classes (BiddingWidgetContext, TrumpIndicatorContext, etc.)
- [ ] Extend GameVariant interface with UI methods
- [ ] Create variant-specific bidding widgets for each variant
- [ ] Build unified BiddingOverlay container
- [ ] Create TrumpIndicator abstraction
- [ ] Create SpecialCardDisplay abstraction
- [ ] Refactor ActionBar to use GameAction system
- [ ] Update GameState with UI-related fields
- [ ] Update GameEngine to delegate to variant UI methods
- [ ] Update GameScreen to use abstracted UI components
- [ ] Implement UI methods in each variant class
- [ ] Test each variant's UI independently
- [ ] Test variant switching

---

This UI abstraction design ensures that each variant can fully customize its user interface while maintaining a consistent overall game experience. The strategy pattern extends seamlessly from game logic into the UI layer.
