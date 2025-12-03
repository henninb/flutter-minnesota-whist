import 'package:flutter/material.dart';
import '../../game/engine/game_engine.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/game_models.dart';
import '../../models/game_settings.dart';
import '../../models/theme_models.dart';
import '../widgets/overlays/bidding_bottom_sheet.dart';
import '../widgets/overlays/game_over_modal.dart';
import '../widgets/overlays/setup_overlay.dart';
import '../widgets/overlays/welcome_overlay.dart';
import '../widgets/persistent_game_board.dart';
import 'settings_screen.dart';

/// Main game screen for Minnesota Whist using single-page overlay design.
///
/// The screen uses a Stack layout with:
/// - PersistentGameBoard as the base layer (always visible)
/// - Overlays that appear based on game phase (welcome, bidding, etc.)
/// - Bottom sheets for contextual interactions (bidding)
///
/// This design ensures the core game board (score, trick, hand, actions) is
/// always visible while phase-specific UI appears as overlays.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.engine,
    required this.currentTheme,
    required this.onThemeChange,
    required this.currentSettings,
    required this.onSettingsChange,
  });

  final GameEngine engine;
  final MinnesotaWhistTheme currentTheme;
  final Function(MinnesotaWhistTheme) onThemeChange;
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChange;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Track which overlays have been shown to prevent duplicates
  bool _setupOverlayShown = false;
  bool _biddingOverlayShown = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        // Reset overlay flags on phase changes
        _resetOverlayFlags(state);

        // Show bottom sheets based on game phase
        debugPrint('🎯 [UI TIMING] Build phase: ${state.currentPhase}, currentBidder: ${state.currentBidder}, biddingOverlayShown: $_biddingOverlayShown');

        // For bidding, show immediately; for others use post-frame callback
        // Minnesota Whist: Check showBiddingDialog flag instead of currentBidder (simultaneous bidding)
        if (state.showBiddingDialog && !_biddingOverlayShown) {
          debugPrint('🎯 [UI TIMING] Scheduling bidding sheet via postFrameCallback');
          // Show bidding sheet immediately without delay
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('🎯 [UI TIMING] postFrameCallback executing for bidding sheet');
            if (!mounted) return;
            _biddingOverlayShown = true;
            _showBiddingSheet(context, state);
          });
        } else {
          // Other overlays can use post-frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleOverlays(context, state);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Minnesota Whist'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Persistent game board (always visible)
              PersistentGameBoard(
                state: state,
                engine: widget.engine,
                onStartGame: () => widget.engine.startNewGame(),
                onCutForDeal: () => widget.engine.cutForDeal(),
                onSelectCutCard: (index) => widget.engine.selectCutCard(index),
                onDealCards: () => widget.engine.dealCards(),
                onNextHand: () => widget.engine.startNextHand(),
                onClaimTricks: () => widget.engine.claimRemainingTricks(),
              ),

              // Welcome overlay (when game not started)
              if (!state.gameStarted)
                WelcomeOverlay(
                  onStartGame: () => widget.engine.startNewGame(),
                ),

              // Game over modal
              if (state.showGameOverDialog && state.gameOverData != null)
                GameOverModal(
                  data: state.gameOverData!,
                  onDismiss: () => widget.engine.dismissGameOverDialog(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Reset overlay shown flags when phase changes
  void _resetOverlayFlags(GameState state) {
    if (state.currentPhase != GamePhase.cutForDeal) {
      _setupOverlayShown = false;
    }
    // Minnesota Whist: Check showBiddingDialog flag instead of currentBidder
    if (!state.showBiddingDialog) {
      _biddingOverlayShown = false;
    }
  }

  /// Handle showing bottom sheet overlays based on game state
  void _handleOverlays(BuildContext context, GameState state) {
    // Additional safety check - should not be needed but prevents edge cases
    if (!mounted) return;

    // Show setup overlay after cut for deal
    if (state.currentPhase == GamePhase.cutForDeal &&
        state.cutCards.isNotEmpty &&
        !_setupOverlayShown) {
      _setupOverlayShown = true;
      _showSetupOverlay(context, state);
    }

    // Show bidding sheet when showBiddingDialog flag is set
    // Minnesota Whist: Check showBiddingDialog instead of currentBidder (simultaneous bidding)
    if (state.showBiddingDialog && !_biddingOverlayShown) {
      debugPrint('🎯 [UI TIMING] Triggering bidding sheet in _handleOverlays');
      _biddingOverlayShown = true;
      _showBiddingSheet(context, state);
    }

  }

  /// Show setup overlay (cut for deal results)
  void _showSetupOverlay(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SetupOverlay(state: state),
    );
  }

  /// Show bidding bottom sheet
  void _showBiddingSheet(BuildContext context, GameState state) {
    debugPrint('🎯 [UI TIMING] _showBiddingSheet() called, showing modal');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Must bid or pass
      enableDrag: false,
      builder: (context) {
        debugPrint('🎯 [UI TIMING] Bidding sheet builder called');
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) => AnimatedBuilder(
            animation: widget.engine,
            builder: (context, _) {
              final currentState = widget.engine.state;

              // Auto-close sheet when bidding phase ends
              if (!currentState.isBiddingPhase) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                });
              }

              return BiddingBottomSheet(
                key: ValueKey(currentState.playerHand.length + currentState.playerHand.hashCode),
                state: currentState,
                onCardSelected: (card) {
                  // Store the selected card but don't submit yet
                  widget.engine.selectBidCard(card);
                },
                onConfirm: () {
                  // Confirm and submit the bid
                  widget.engine.confirmBid();
                },
                onTestHandSelected: (testHand) {
                  widget.engine.applyTestHand(testHand);
                  // Don't close the bidding sheet - let user bid with new hand
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Show settings overlay
  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: SettingsScreen(
          currentSettings: widget.currentSettings,
          onSettingsChange: widget.onSettingsChange,
          onBackPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
