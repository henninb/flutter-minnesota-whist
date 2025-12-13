import 'package:flutter/material.dart';

/// Dialog for Widow Whist bidding
/// All players select trick count (6-12) simultaneously
class WidowWhistBiddingDialog extends StatefulWidget {
  const WidowWhistBiddingDialog({
    super.key,
    required this.onBid,
  });

  final Function(int tricks) onBid;

  @override
  State<WidowWhistBiddingDialog> createState() =>
      _WidowWhistBiddingDialogState();
}

class _WidowWhistBiddingDialogState extends State<WidowWhistBiddingDialog> {
  int? _selectedTricks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Bid for the Widow'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'High bidder wins the 4-card widow!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Winner plays solo against the other 3 players',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Select minimum tricks you\'ll take:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Tricks selection (6-12)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(7, (index) {
              final tricks = 6 + index; // 6 to 12
              return ChoiceChip(
                label: Text(
                  tricks.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: _selectedTricks == tricks,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTricks = tricks);
                  }
                },
                selectedColor: colorScheme.primaryContainer,
                labelStyle: _selectedTricks == tricks
                    ? TextStyle(color: colorScheme.onPrimaryContainer)
                    : null,
              );
            }),
          ),

          const SizedBox(height: 16),

          // Scoring explanation
          if (_selectedTricks != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If you win with $_selectedTricks:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Make bid: +${_selectedTricks! - 6} points',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '• Fail by 1: -2 points',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Additional info
          Text(
            'Min: 6 tricks (half), Max: 12 tricks (all)',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedTricks == null
              ? null
              : () {
                  widget.onBid(_selectedTricks!);
                  Navigator.of(context).pop();
                },
          child: const Text('Place Bid'),
        ),
      ],
    );
  }
}
