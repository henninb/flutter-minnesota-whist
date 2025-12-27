import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';
import 'playing_card_widget.dart';

/// Minnesota Whist bidding interface
///
/// Players simultaneously place one card face-down to indicate their bid:
/// - Black card (spades/clubs) = HIGH bid (team wants to win tricks)
/// - Red card (hearts/diamonds) = LOW bid (team wants to lose tricks)
///
/// Strategy: Use lowest card of chosen color to preserve hand strength
class BiddingInterface extends StatefulWidget {
  const BiddingInterface({
    super.key,
    required this.playerHand,
    required this.onCardSelected,
    this.selectedCard,
  });

  final List<PlayingCard> playerHand;
  final Function(PlayingCard card) onCardSelected;
  final PlayingCard? selectedCard;

  @override
  State<BiddingInterface> createState() => _BiddingInterfaceState();
}

class _BiddingInterfaceState extends State<BiddingInterface> {
  PlayingCard? _hoveredCard;

  bool _isBlackCard(PlayingCard card) {
    return card.suit == Suit.spades || card.suit == Suit.clubs;
  }

  BidType _getBidType(PlayingCard card) {
    return _isBlackCard(card) ? BidType.high : BidType.low;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Separate cards by color and get only the lowest from each
    final allBlackCards = widget.playerHand.where(_isBlackCard).toList()
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));
    final blackCards = allBlackCards.isNotEmpty ? [allBlackCards.first] : <PlayingCard>[];

    final allRedCards = widget.playerHand.where((c) => !_isBlackCard(c)).toList()
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));
    final redCards = allRedCards.isNotEmpty ? [allRedCards.first] : <PlayingCard>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),

        // Compact selection display
        if (widget.selectedCard != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.onSecondaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getBidType(widget.selectedCard!).name.toUpperCase()}: ${widget.selectedCard!.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Side-by-side card selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Black card (HIGH bid)
              Expanded(
                child: _buildCompactCardOption(
                  context,
                  title: 'HIGH',
                  subtitle: '♠♣',
                  cards: blackCards,
                  bidType: BidType.high,
                  sectionColor: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 12),
              // Red card (LOW bid)
              Expanded(
                child: _buildCompactCardOption(
                  context,
                  title: 'LOW',
                  subtitle: '♥♦',
                  cards: redCards,
                  bidType: BidType.low,
                  sectionColor: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Compact card option for side-by-side layout
  Widget _buildCompactCardOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<PlayingCard> cards,
    required BidType bidType,
    required Color sectionColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'None',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final card = cards.first;
    final isSelected = widget.selectedCard == card;
    final isHovered = _hoveredCard == card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCard = card),
      onExit: (_) => setState(() => _hoveredCard = null),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onCardSelected(card);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : isHovered
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : isHovered
                      ? colorScheme.outline
                      : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : isHovered
                    ? [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title (HIGH/LOW) with theme-aware color
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              // Suit symbols with theme-aware color
              Text(
                subtitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Use PlayingCardWidget like in hand display
              PlayingCardWidget(
                card: card,
                width: 70,
                height: 98,
                isSelected: isSelected,
                isPeeking: false,
                isWinning: false,
                onTap: null, // Handled by parent GestureDetector
              ),
            ],
          ),
        ),
      ),
    );
  }
}
