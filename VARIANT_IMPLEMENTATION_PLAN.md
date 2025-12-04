# Whist Variants Implementation Plan

## Overview
This plan outlines the implementation strategy for adding support for multiple 4-player whist variants to the Minnesota Whist app using the Strategy Pattern. The variants to be supported include:

1. **Minnesota Whist** (current implementation)
2. **Classic Whist**
3. **Bid Whist**
4. **Oh Hell / Nomination Whist**
5. **Widow Whist**

## Architecture Strategy

### Strategy Pattern Approach
We'll implement a strategy pattern where each variant encapsulates its own rules for:
- Bidding mechanics
- Trump selection
- Scoring rules
- Trick-taking rules

This allows us to swap variant implementations at runtime while maintaining a clean separation of concerns.

---

## Implementation Steps

### Phase 1: Create Variant Abstraction Layer

#### 1.1 Define Core Variant Interface
**File:** `lib/src/game/variants/game_variant.dart` (new)

Create an abstract base class that all variants must implement:

```dart
abstract class GameVariant {
  // Metadata
  String get name;
  String get description;

  // Bidding
  bool get usesBidding;
  BiddingEngine? createBiddingEngine(Position dealer);

  // Trump selection
  TrumpSelectionMethod get trumpSelectionMethod;
  Suit? determineTrumpSuit(/* parameters */);

  // Scoring
  ScoringEngine createScoringEngine();
  int get winningScore;

  // Special rules
  bool get allowsClaimingTricks;
  int get tricksPerHand;
}
```

**Key decisions:**
- Each variant provides its own bidding engine, scoring engine, and trump rules
- Metadata helps UI display variant information
- Configuration methods allow variants to customize game flow

---

#### 1.2 Create Variant Enum
**File:** `lib/src/game/variants/variant_type.dart` (new)

```dart
enum VariantType {
  minnesotaWhist,
  classicWhist,
  bidWhist,
  ohHell,
  widowWhist,
}
```

Add helper methods:
- `String get displayName`
- `String get description`
- `GameVariant createVariant()` - Factory method

---

#### 1.3 Extract Abstract Bidding Engine
**File:** `lib/src/game/logic/bidding_engine.dart` (new)

Create abstract base class:
```dart
abstract class BiddingEngine {
  Position get dealer;

  bool isComplete(List<BidEntry> bids);
  AuctionResult determineWinner(List<BidEntry> bids);
  Position? getNextBidder(List<BidEntry> bids);
}
```

Refactor existing `MinnesotaWhistBiddingEngine` to extend this base class.

---

#### 1.4 Extract Abstract Scoring Engine
**File:** `lib/src/game/logic/scoring_engine.dart` (new)

Create abstract base class:
```dart
abstract class ScoringEngine {
  HandScore scoreHand({
    required BidType? handType,
    required Team? contractingTeam,
    required int tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  });

  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
  });

  String getGameOverMessage(GameOverStatus status, int scoreNS, int scoreEW);
}
```

Refactor existing `MinnesotaWhistScorer` to extend this base class.

---

### Phase 2: Implement Individual Variants

#### 2.1 Minnesota Whist Variant
**File:** `lib/src/game/variants/minnesota_whist_variant.dart` (new)

- Extract current implementation into variant class
- Reference existing `MinnesotaWhistBiddingEngine`
- Reference existing `MinnesotaWhistScorer`
- No trump suit (null)
- 13 tricks per hand

---

#### 2.2 Classic Whist Variant
**File:** `lib/src/game/variants/classic_whist_variant.dart` (new)
**File:** `lib/src/game/logic/classic_whist_bidding_engine.dart` (new)
**File:** `lib/src/game/logic/classic_whist_scorer.dart` (new)

**Rules:**
- **No bidding phase** - dealer or last card determines trump
- **Trump selection:** Last card dealt or dealer's choice
- **Scoring:** Simple point-per-trick above 6 (traditional whist scoring)
- **Winning score:** First to 5 game points (configurable)
- **13 tricks per hand**

**Implementation notes:**
- `usesBidding = false`
- Trump determined by last card dealt (show briefly to all players)
- Simpler scoring: 1 point for each trick over 6
- Game point awarded when team reaches certain threshold

---

#### 2.3 Bid Whist Variant
**File:** `lib/src/game/variants/bid_whist_variant.dart` (new)
**File:** `lib/src/game/logic/bid_whist_bidding_engine.dart` (new)
**File:** `lib/src/game/logic/bid_whist_scorer.dart` (new)

**Rules:**
- **Bidding:** Players bid number of tricks (3-7) with uptown/downtown modifier
- **Trump selection:** Winner names trump suit after bidding
- **Kitty:** 6-card kitty goes to high bidder (exchange before play)
- **Scoring:** Points based on bid level and success/failure
- **Winning score:** 7 points (or -7 for loss)
- **13 tricks per hand**

**Implementation notes:**
- Complex bidding with number + suit/no-trump + uptown/downtown
- Need kitty exchange UI (similar to dealer's kitty in other variants)
- Uptown (Ace high) vs Downtown (Ace low, 2 high) affects trick evaluation
- Trump nomination dialog after winning bid

---

#### 2.4 Oh Hell / Nomination Whist Variant
**File:** `lib/src/game/variants/oh_hell_variant.dart` (new)
**File:** `lib/src/game/logic/oh_hell_bidding_engine.dart` (new)
**File:** `lib/src/game/logic/oh_hell_scorer.dart` (new)

**Rules:**
- **Bidding:** Each player bids exact number of tricks they'll take (0-13)
- **Trump selection:** Top card of remaining deck (after deal) or rotate through suits
- **Constraint:** Total bids cannot equal number of tricks available (dealer restricted)
- **Scoring:** 10 points + 1 per trick if exact; 0 if not exact
- **Variable tricks:** Can play with varying hand sizes (1-13-1 progression)
- **Standard: 13 tricks per hand**

**Implementation notes:**
- Sequential bidding (dealer bids last with restriction)
- Need to track individual player bids and actual tricks won
- Scoring rewards precision
- Potential future enhancement: variable hand sizes

---

#### 2.5 Widow Whist Variant
**File:** `lib/src/game/variants/widow_whist_variant.dart` (new)
**File:** `lib/src/game/logic/widow_whist_bidding_engine.dart` (new)
**File:** `lib/src/game/logic/widow_whist_scorer.dart` (new)

**Rules:**
- **Extra hand (widow):** 4 cards dealt face-down as "widow"
- **Bidding:** Players bid for right to exchange with widow
- **Trump selection:** Determined by high bid or dealer
- **Widow exchange:** High bidder takes widow and discards 4 cards
- **Scoring:** Similar to classic whist with bid modifiers
- **13 tricks per hand (12 cards per player + 4 widow)**

**Implementation notes:**
- Need widow display and exchange UI
- Deal 12 cards to each player + 4 to widow
- Bidding for widow rights
- Exchange mechanism similar to kitty in Bid Whist

---

### Phase 3: Integrate Variants into Game Engine

#### 3.1 Update GameState
**File:** `lib/src/game/engine/game_state.dart`

Add fields:
```dart
final VariantType variantType;
final GameVariant? variant; // Computed from variantType
```

Add copyWith support for variant changes.

---

#### 3.2 Update GameEngine
**File:** `lib/src/game/engine/game_engine.dart`

**Changes:**
1. Add variant field to constructor and state
2. Replace direct references to `MinnesotaWhistBiddingEngine` with `state.variant.createBiddingEngine()`
3. Replace direct references to `MinnesotaWhistScorer` with `state.variant.createScoringEngine()`
4. Add variant-specific flow control:
   - Skip bidding for Classic Whist
   - Handle kitty/widow exchange for Bid Whist/Widow Whist
   - Handle trump selection per variant rules

**Key refactoring:**
```dart
// Before
final biddingEngine = MinnesotaWhistBiddingEngine(dealer: _state.dealer);

// After
final biddingEngine = _state.variant!.createBiddingEngine(_state.dealer);
```

---

#### 3.3 Update GameSettings
**File:** `lib/src/models/game_settings.dart`

Add field:
```dart
final VariantType selectedVariant;
```

Update:
- `copyWith()` method
- `toJson()` method
- `fromJson()` method
- Constructor default to `VariantType.minnesotaWhist`

---

### Phase 4: Create Variant Selection UI

#### 4.1 Variant Selection Screen
**File:** `lib/src/ui/widgets/overlays/variant_selector_overlay.dart` (new)

**UI Components:**
- List of available variants with cards
- Each variant card shows:
  - Name
  - Icon/illustration
  - Brief description (2-3 lines)
  - Key features (bullets)
- "Select" button for each variant
- "Learn More" expands detailed rules

**Behavior:**
- Shown at game setup phase (before cut for deal)
- Replaces setup screen initially
- Selected variant stored in GameSettings
- Can be changed only when starting new game

---

#### 4.2 Update Setup Screen
**File:** `lib/src/ui/widgets/setup_screen.dart`

Add:
- Display current variant name at top
- "Change Variant" button (only when no game in progress)
- Opens variant selector overlay

---

#### 4.3 Update Setup Overlay
**File:** `lib/src/ui/widgets/overlays/setup_overlay.dart`

Add variant selection flow:
1. User taps "New Game"
2. Show variant selector first
3. After variant selected, show cut for deal
4. Proceed with game using selected variant

---

### Phase 5: Variant-Specific UI Components

#### 5.1 Conditional Bidding UI
**File:** `lib/src/ui/widgets/bidding_interface.dart`

Update to support different bidding styles:
- Minnesota Whist: Card selection (existing)
- Bid Whist: Number + suit/no-trump selector
- Oh Hell: Number spinner (0-13) with restriction display
- Widow Whist: Number + widow exchange option
- Classic Whist: No bidding UI (hidden)

**Approach:**
- Use factory pattern or switch on variant type
- Each variant provides its own bidding widget
- GameEngine handles validation per variant

---

#### 5.2 Trump Display
**File:** `lib/src/ui/widgets/trump_indicator.dart` (new)

Display trump suit when applicable:
- Show trump suit icon/symbol
- Highlight trump cards in hand
- Display "No Trump" for variants without trump

Position: Top center of game board or near status bar

---

#### 5.3 Kitty/Widow Display
**File:** `lib/src/ui/widgets/kitty_display.dart` (new)

For Bid Whist and Widow Whist:
- Show face-down kitty/widow cards
- Animate transfer to winner
- Show exchange interface for high bidder
- Allow selection of cards to discard

---

#### 5.4 Score Display Updates
**File:** `lib/src/ui/widgets/score_display.dart`

Update to show:
- Variant-specific score format
- Different winning thresholds per variant
- Individual scores for Oh Hell (not just team scores)

---

### Phase 6: Testing and Validation

#### 6.1 Unit Tests
**Files:** `test/variants/` directory (new)

Create tests for each variant:
- `minnesota_whist_variant_test.dart`
- `classic_whist_variant_test.dart`
- `bid_whist_variant_test.dart`
- `oh_hell_variant_test.dart`
- `widow_whist_variant_test.dart`

Test:
- Bidding logic
- Scoring calculations
- Trump selection
- Game over conditions

---

#### 6.2 Integration Tests
**Files:** `integration_test/` directory

Test:
- Variant selection flow
- Complete game from start to finish for each variant
- Switching variants between games
- Settings persistence

---

#### 6.3 AI Adjustments
**Files:**
- `lib/src/game/logic/bidding_ai.dart`
- `lib/src/game/logic/play_ai.dart`

Update AI to handle:
- Different bidding strategies per variant
- Trump awareness for trick-taking
- Widow/kitty exchange decisions
- Oh Hell exact trick prediction

---

### Phase 7: Polish and Documentation

#### 7.1 In-App Rules/Help
**File:** `lib/src/ui/widgets/overlays/rules_overlay.dart` (new)

Create help overlay showing:
- Current variant rules
- Bidding explanation
- Scoring details
- Trump rules
- Special cases

Accessible via "?" button in action bar

---

#### 7.2 Variant Quick Reference
**File:** `lib/src/ui/widgets/overlays/variant_quick_ref.dart` (new)

Compact overlay showing:
- Current variant name
- Key rule reminders
- Current trump (if applicable)
- Scoring method quick ref

Accessible during gameplay (icon in status bar)

---

#### 7.3 Update README
**File:** `README.md`

Add section documenting:
- Supported variants
- Variant selection instructions
- Rules summary for each variant
- Future variant plans

---

## File Structure Summary

```
lib/src/game/
├── variants/
│   ├── game_variant.dart              (abstract base)
│   ├── variant_type.dart              (enum + factory)
│   ├── minnesota_whist_variant.dart
│   ├── classic_whist_variant.dart
│   ├── bid_whist_variant.dart
│   ├── oh_hell_variant.dart
│   └── widow_whist_variant.dart
├── logic/
│   ├── bidding_engine.dart            (abstract base)
│   ├── scoring_engine.dart            (abstract base)
│   ├── minnesota_whist_bidding_engine.dart (extends BiddingEngine)
│   ├── minnesota_whist_scorer.dart         (extends ScoringEngine)
│   ├── classic_whist_bidding_engine.dart
│   ├── classic_whist_scorer.dart
│   ├── bid_whist_bidding_engine.dart
│   ├── bid_whist_scorer.dart
│   ├── oh_hell_bidding_engine.dart
│   ├── oh_hell_scorer.dart
│   ├── widow_whist_bidding_engine.dart
│   └── widow_whist_scorer.dart
└── engine/
    ├── game_engine.dart               (updated)
    └── game_state.dart                (updated)

lib/src/ui/widgets/
├── overlays/
│   ├── variant_selector_overlay.dart  (new)
│   ├── rules_overlay.dart             (new)
│   └── variant_quick_ref.dart         (new)
├── trump_indicator.dart               (new)
├── kitty_display.dart                 (new)
├── setup_screen.dart                  (updated)
├── bidding_interface.dart             (updated)
└── score_display.dart                 (updated)

lib/src/models/
└── game_settings.dart                 (updated)

test/
└── variants/
    ├── minnesota_whist_variant_test.dart
    ├── classic_whist_variant_test.dart
    ├── bid_whist_variant_test.dart
    ├── oh_hell_variant_test.dart
    └── widow_whist_variant_test.dart
```

---

## Migration Path

### Backward Compatibility
- Default variant is Minnesota Whist (preserves current behavior)
- Existing saved games continue to work
- Settings migration auto-sets `selectedVariant = VariantType.minnesotaWhist`

### Rollout Strategy
1. **Phase 1-2:** Create abstractions and Minnesota Whist variant (refactor only, no new features visible)
2. **Phase 3-4:** Add variant selection UI (allows switching, but only Minnesota available)
3. **Phase 2 (cont.):** Add Classic Whist (first new variant - simplest to implement)
4. **Phase 2 (cont.):** Add remaining variants one by one
5. **Phase 5-6:** Variant-specific UI and testing
6. **Phase 7:** Polish and documentation

---

## Estimated Complexity

### Files to Create: ~25
### Files to Modify: ~10
### Testing Files: ~15

**Complexity by Variant:**
1. **Minnesota Whist:** Low (refactor existing)
2. **Classic Whist:** Low (no bidding, simple scoring)
3. **Oh Hell:** Medium (sequential bidding, individual scoring)
4. **Widow Whist:** Medium-High (widow mechanics, exchange UI)
5. **Bid Whist:** High (complex bidding, kitty exchange, uptown/downtown)

---

## Future Enhancements

### Potential Additional Variants (not in initial scope)
- **Knockout Whist** (varying hand sizes)
- **German Whist** (2-player)
- **Israeli Whist** (complex scoring)
- **Norwegian Whist** (partnership switching)

### Configuration Options (per-variant)
- Custom winning scores
- House rules toggles
- AI difficulty levels per variant
- Tournament mode (best of N games)

---

## Key Design Principles

1. **Separation of Concerns:** Each variant encapsulates its own rules
2. **Open/Closed Principle:** Easy to add new variants without modifying existing ones
3. **DRY:** Shared logic in base classes (TrickEngine, TrumpRules, etc.)
4. **Testability:** Each variant independently testable
5. **User Experience:** Clear variant selection, in-game help, visual differentiation

---

## Questions for Refinement

1. **Persistence:** Should we allow mid-game variant switches? (Recommend: No)
2. **Defaults:** Auto-detect user's region for default variant? (Recommend: No, always default to Minnesota)
3. **Tutorials:** Interactive tutorial for each variant? (Recommend: Future enhancement)
4. **Multiplayer:** Different variants in multiplayer? (Out of scope initially)
5. **Custom Variants:** Allow users to define custom rule sets? (Far future)

---

## Success Criteria

- [ ] All 5 variants fully playable
- [ ] Variant selection works at game setup
- [ ] Each variant has correct bidding, trump, and scoring
- [ ] UI adapts appropriately per variant
- [ ] AI plays competently for each variant
- [ ] All tests passing (100+ test cases)
- [ ] No regression in Minnesota Whist gameplay
- [ ] Settings persist variant selection
- [ ] Help/rules accessible in-game
- [ ] Performance remains smooth (no lag from abstraction)

---

## Implementation Priority

**High Priority (MVP):**
1. Phase 1: Abstractions and architecture
2. Phase 2.1: Minnesota Whist variant (refactor)
3. Phase 3: GameEngine integration
4. Phase 4: Variant selection UI
5. Phase 2.2: Classic Whist (simplest new variant)

**Medium Priority (Full Release):**
6. Phase 2.3-2.5: Remaining variants
7. Phase 5: Variant-specific UI components
8. Phase 6: Testing and AI adjustments

**Low Priority (Polish):**
9. Phase 7: Documentation and help system
10. Future enhancements

---

## Timeline Estimate (rough)

- **Phase 1:** 3-5 days (architecture and abstractions)
- **Phase 2.1:** 2-3 days (Minnesota Whist refactor)
- **Phase 3:** 2-3 days (GameEngine integration)
- **Phase 4:** 2-3 days (Variant selection UI)
- **Phase 2.2:** 2-3 days (Classic Whist)
- **Phase 2.3:** 4-5 days (Bid Whist - most complex)
- **Phase 2.4:** 3-4 days (Oh Hell)
- **Phase 2.5:** 3-4 days (Widow Whist)
- **Phase 5:** 5-7 days (All variant-specific UI)
- **Phase 6:** 5-7 days (Testing and AI)
- **Phase 7:** 2-3 days (Documentation)

**Total estimate:** 4-6 weeks for full implementation

Note: These are development estimates and don't account for planning, code review, or iterations.

---

## End of Plan

This plan provides a comprehensive roadmap for adding multiple whist variants while maintaining clean architecture and user experience. Implementation can proceed incrementally, with each phase delivering value.
