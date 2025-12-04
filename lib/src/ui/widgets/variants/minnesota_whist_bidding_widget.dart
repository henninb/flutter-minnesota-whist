import 'package:flutter/material.dart';
import '../../../game/models/card.dart';
import '../../../ui/context/variant_ui_context.dart';
import '../bidding_interface.dart';

/// Minnesota Whist specific bidding widget
///
/// Wraps the existing BiddingInterface to work with the variant system
class MinnesotaWhistBiddingWidget extends StatefulWidget {
  const MinnesotaWhistBiddingWidget({
    super.key,
    required this.context,
  });

  final BiddingWidgetContext context;

  @override
  State<MinnesotaWhistBiddingWidget> createState() =>
      _MinnesotaWhistBiddingWidgetState();
}

class _MinnesotaWhistBiddingWidgetState
    extends State<MinnesotaWhistBiddingWidget> {
  PlayingCard? _selectedCard;

  void _onCardSelected(PlayingCard card) {
    setState(() {
      _selectedCard = card;
    });
  }

  void _onConfirmBid() {
    if (_selectedCard != null) {
      // Submit the selected card as the bid
      widget.context.onBidSubmitted(_selectedCard!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.gavel,
                color: colorScheme.onPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Place Your Bid',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Bidding interface
        Expanded(
          child: BiddingInterface(
            playerHand: widget.context.playerHand,
            onCardSelected: _onCardSelected,
            selectedCard: _selectedCard,
          ),
        ),

        // Confirm button
        if (_selectedCard != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: _onConfirmBid,
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Confirm Bid: ${_selectedCard!.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }
}
