import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';

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

    // Separate cards by color
    final blackCards = widget.playerHand
        .where(_isBlackCard)
        .toList()
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    final redCards = widget.playerHand
        .where((c) => !_isBlackCard(c))
        .toList()
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            const SizedBox(height: 16),

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select a card to place your bid:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '♠♣ Black = HIGH (win tricks)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '♥♦ Red = LOW (lose tricks)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Current selection display
            if (widget.selectedCard != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.secondaryContainer,
                      colorScheme.secondaryContainer.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gavel,
                      color: colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bidding ${_getBidType(widget.selectedCard!).name.toUpperCase()} with ${widget.selectedCard!.label}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Black cards (HIGH bid)
            _buildCardSection(
              context,
              title: 'Black Cards (HIGH Bid)',
              subtitle: 'Choose to win as many tricks as possible',
              cards: blackCards,
              bidType: BidType.high,
              sectionColor: Colors.grey.shade800,
            ),

            const SizedBox(height: 20),

            // Red cards (LOW bid)
            _buildCardSection(
              context,
              title: 'Red Cards (LOW Bid)',
              subtitle: 'Choose to lose as many tricks as possible',
              cards: redCards,
              bidType: BidType.low,
              sectionColor: Colors.red.shade700,
            ),

            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCardSection(
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: sectionColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  'No ${bidType == BidType.high ? 'black' : 'red'} cards in hand',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: sectionColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cards.map((card) {
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
                    width: 60,
                    height: 84,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : isHovered
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : isHovered
                                ? colorScheme.outline
                                : colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1.5,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.rankSymbol,
                          style: TextStyle(
                            fontSize: isSelected ? 26 : 24,
                            fontWeight: FontWeight.bold,
                            color: card.isRed ? Colors.red.shade700 : Colors.black87,
                          ),
                        ),
                        Text(
                          card.suitSymbol,
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 22,
                            color: card.isRed ? Colors.red.shade700 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
