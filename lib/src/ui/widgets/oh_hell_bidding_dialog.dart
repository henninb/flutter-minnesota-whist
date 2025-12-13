import 'package:flutter/material.dart';
import '../../game/models/game_models.dart';

/// Dialog for Oh Hell bidding - player selects exact number of tricks
class OhHellBiddingDialog extends StatefulWidget {
  const OhHellBiddingDialog({
    super.key,
    required this.currentBidder,
    required this.currentBids,
    required this.tricksAvailable,
    required this.onBid,
  });

  final Position currentBidder;
  final Map<Position, int> currentBids; // Bids placed so far
  final int tricksAvailable; // Total tricks in this hand
  final Function(int tricks) onBid;

  @override
  State<OhHellBiddingDialog> createState() => _OhHellBiddingDialogState();
}

class _OhHellBiddingDialogState extends State<OhHellBiddingDialog> {
  int? _selectedTricks;

  @override
  Widget build(BuildContext context) {
    final isDealer = widget.currentBidder == _getDealer();
    final totalBidsSoFar =
        widget.currentBids.values.fold<int>(0, (sum, bid) => sum + bid);
    final forbiddenBid =
        isDealer ? (widget.tricksAvailable - totalBidsSoFar) : null;

    return AlertDialog(
      title: Text('${_positionName(widget.currentBidder)}\'s Bid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show current bids
          if (widget.currentBids.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bids so far:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...widget.currentBids.entries.map((entry) {
                    return Text('${_positionName(entry.key)}: ${entry.value}');
                  }),
                  const Divider(),
                  Text(
                    'Total: $totalBidsSoFar / ${widget.tricksAvailable}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Dealer restriction warning
          if (isDealer && forbiddenBid != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dealer restriction: Cannot bid $forbiddenBid',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          const Text(
            'Bid exact number of tricks:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Tricks selection
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(widget.tricksAvailable + 1, (tricks) {
              final isForbidden = isDealer && tricks == forbiddenBid;

              return ChoiceChip(
                label: Text(tricks.toString()),
                selected: _selectedTricks == tricks,
                onSelected: isForbidden
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() => _selectedTricks = tricks);
                        }
                      },
                backgroundColor: isForbidden ? Colors.red.shade100 : null,
                disabledColor: Colors.red.shade100,
              );
            }),
          ),

          const SizedBox(height: 16),

          // Explanation
          Text(
            _selectedTricks == 0
                ? 'Nil bid: Take no tricks for 10 points'
                : _selectedTricks != null
                    ? 'Make exactly $_selectedTricks tricks for ${10 + _selectedTricks!} points'
                    : 'Select number of tricks you\'ll take',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
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
          child: const Text('Bid'),
        ),
      ],
    );
  }

  String _positionName(Position position) {
    switch (position) {
      case Position.south:
        return 'You';
      case Position.north:
        return 'Partner';
      case Position.east:
        return 'East';
      case Position.west:
        return 'West';
    }
  }

  // Helper to determine dealer (simplified - should come from game state)
  Position _getDealer() {
    // This is a placeholder - in reality should come from widget parameter
    // For now, assume last bidder is dealer
    if (widget.currentBids.length == 3) {
      return widget.currentBidder;
    }
    return Position.east; // Default
  }
}
