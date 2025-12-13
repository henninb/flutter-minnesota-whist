import 'package:flutter/material.dart';
import '../../game/models/card.dart';

/// Dialog for Widow Whist widow exchange
/// Player sees widow cards and selects 4 cards to discard
class WidowExchangeDialog extends StatefulWidget {
  const WidowExchangeDialog({
    super.key,
    required this.widowCards,
    required this.playerHand,
    required this.onExchange,
  });

  final List<PlayingCard> widowCards; // The 4 widow cards
  final List<PlayingCard> playerHand; // Player's current 12 cards
  final Function(List<PlayingCard> discards, Suit trump) onExchange;

  @override
  State<WidowExchangeDialog> createState() => _WidowExchangeDialogState();
}

class _WidowExchangeDialogState extends State<WidowExchangeDialog> {
  final Set<PlayingCard> _selectedDiscards = {};
  Suit _selectedTrump = Suit.spades;

  List<PlayingCard> get _combinedHand =>
      [...widget.playerHand, ...widget.widowCards];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final canConfirm = _selectedDiscards.length == 4;

    return AlertDialog(
      title: const Text('Widow Exchange'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Text(
              'You won the bid! Select 4 cards to discard and choose trump.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Widow cards display
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Text(
                        'Widow Cards:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: widget.widowCards.map((card) {
                      return Chip(
                        label: Text(card.label),
                        backgroundColor: Colors.amber.shade50,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Discard selection
            Text(
              'Select 4 cards to discard (${_selectedDiscards.length}/4):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // All cards (hand + widow)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _combinedHand.map((card) {
                    final isSelected = _selectedDiscards.contains(card);

                    return FilterChip(
                      label: Text(card.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected && _selectedDiscards.length < 4) {
                            _selectedDiscards.add(card);
                          } else if (!selected) {
                            _selectedDiscards.remove(card);
                          }
                        });
                      },
                      selectedColor: Colors.red.shade100,
                      checkmarkColor: Colors.red,
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Trump selection
            const Text(
              'Select trump suit:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Suit.values.map((suit) {
                return ChoiceChip(
                  label: Text(_suitName(suit)),
                  selected: _selectedTrump == suit,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTrump = suit);
                    }
                  },
                  avatar: Text(_suitSymbol(suit)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () {
                  widget.onExchange(_selectedDiscards.toList(), _selectedTrump);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  String _suitName(Suit suit) {
    switch (suit) {
      case Suit.spades:
        return 'Spades';
      case Suit.hearts:
        return 'Hearts';
      case Suit.diamonds:
        return 'Diamonds';
      case Suit.clubs:
        return 'Clubs';
    }
  }

  String _suitSymbol(Suit suit) {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }
}
