import 'package:flutter/material.dart';
import '../../../game/engine/game_state.dart';
import '../../../game/models/card.dart';
import '../../../game/models/game_models.dart';
import '../bidding_interface.dart';
import '../hand_display.dart';
import '../score_display.dart';
import 'test_hands_dialog.dart';

/// Bottom sheet wrapper for Minnesota Whist bidding interface.
///
/// Displays the card-based bidding interface in a draggable bottom sheet when
/// it's the player's turn to bid. Players select one card from their hand:
/// - Black card (♠♣) = HIGH bid (want to win tricks)
/// - Red card (♥♦) = LOW bid (want to lose tricks)
///
/// Hidden feature: Triple-tap on the title to access test hands menu.
class BiddingBottomSheet extends StatefulWidget {
  const BiddingBottomSheet({
    super.key,
    required this.state,
    required this.onCardSelected,
    required this.onConfirm,
    required this.onTestHandSelected,
  });

  final GameState state;
  final Function(PlayingCard card) onCardSelected;
  final VoidCallback onConfirm;
  final Function(List<PlayingCard> testHand) onTestHandSelected;

  @override
  State<BiddingBottomSheet> createState() => _BiddingBottomSheetState();
}

class _BiddingBottomSheetState extends State<BiddingBottomSheet> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  PlayingCard? _selectedCard;

  bool _isBlackCard(PlayingCard card) {
    return card.suit == Suit.spades || card.suit == Suit.clubs;
  }

  BidType _getBidType(PlayingCard card) {
    return _isBlackCard(card) ? BidType.high : BidType.low;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scoreboard at top of bidding sheet
          if (widget.state.gameStarted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ScoreDisplay(
                scoreNS: widget.state.teamNorthSouthScore,
                scoreEW: widget.state.teamEastWestScore,
                tricksNS: widget.state.tricksWonNS,
                tricksEW: widget.state.tricksWonEW,
                trumpSuit: widget.state.trumpSuit,
                winningBid: widget.state.winningBid,
                dealer: widget.state.dealer,
              ),
            ),

          // Title bar with triple-tap gesture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _handleTitleTap,
                child: Text(
                  'Place Your Bid',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Tooltip(
                message: '♠♣ Black = HIGH (win tricks)\n♥♦ Red = LOW (lose tricks)\n\nUse your lowest card!',
                preferBelow: false,
                child: IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: '', // Handled by Tooltip widget
                  onPressed: () => _showBiddingHelp(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Player's hand display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Hand:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              HandDisplay(
                hand: widget.state.playerHand,
                onCardTap: (_) {}, // No interaction during bidding
                selectedIndices: const {},
                phase: widget.state.currentPhase,
                enabled: false, // Cards not tappable during bidding
                allowPeek: true, // Allow peeking at overlapping cards
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bidding interface
          Expanded(
            child: BiddingInterface(
              playerHand: widget.state.playerHand,
              selectedCard: _selectedCard ?? widget.state.pendingBidCard,
              onCardSelected: (card) {
                setState(() {
                  _selectedCard = card;
                });
                widget.onCardSelected(card);
              },
            ),
          ),

          // Confirm button at bottom
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    (_selectedCard ?? widget.state.pendingBidCard) != null
                        ? widget.onConfirm
                        : null,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  (_selectedCard ?? widget.state.pendingBidCard) != null
                      ? 'Confirm ${_getBidType(_selectedCard ?? widget.state.pendingBidCard!).name.toUpperCase()} Bid'
                      : 'Select a card to bid',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTitleTap() {
    final now = DateTime.now();

    // Reset tap count if too much time has elapsed (> 1 second)
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!).inMilliseconds > 1000) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }

    _lastTapTime = now;

    // Open test hands dialog on triple tap
    if (_tapCount >= 3) {
      _tapCount = 0;
      _lastTapTime = null;
      _showTestHandsDialog(context);
    }
  }

  void _showTestHandsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TestHandsDialog(
        onTestHandSelected: (testHand) {
          widget.onTestHandSelected(testHand);
          Navigator.pop(context); // Close dialog
        },
      ),
    );
  }

  void _showBiddingHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minnesota Whist Bidding'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to Bid:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• All players simultaneously select one card\n'
                '• Black card (♠♣) = HIGH bid (your team tries to win tricks)\n'
                '• Red card (♥♦) = LOW bid (your team tries to lose tricks)\n'
                '• The card used for bidding is removed from your hand\n'
                '• Choose wisely - use your lowest card of the chosen color',
              ),
              const SizedBox(height: 12),
              Text(
                'How Partners Are Decided:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• If bids are split 3-1, the lone bidder becomes dummy\n'
                '• If all 4 bid the same color, no hand is played\n'
                '• The granding team plays first',
              ),
              const SizedBox(height: 12),
              Text(
                'Strategy Tips:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Strong hand? Bid black (HIGH) to win tricks\n'
                '• Weak hand? Bid red (LOW) to lose tricks\n'
                '• Use lowest card to preserve hand strength\n'
                '• First team to 13 points wins!',
              ),
            ],
          ),
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
