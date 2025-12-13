import 'package:flutter/material.dart';
import '../../game/models/game_models.dart';

/// Sequential bidding dialog for Bid Whist
class BidWhistBiddingDialog extends StatefulWidget {
  const BidWhistBiddingDialog({
    super.key,
    required this.currentBidder,
    required this.highestBid,
    required this.onBid,
    required this.onPass,
  });

  final Position currentBidder;
  final int? highestBid; // Highest books bid so far (3-7), null if no bids yet
  final Function(int books, bool isUptown) onBid;
  final Function() onPass;

  @override
  State<BidWhistBiddingDialog> createState() => _BidWhistBiddingDialogState();
}

class _BidWhistBiddingDialogState extends State<BidWhistBiddingDialog> {
  int? _selectedBooks;
  bool _isUptown = true;

  @override
  Widget build(BuildContext context) {
    final minBid = (widget.highestBid ?? 2) + 1; // Must bid higher than current
    final maxBid = 6; // Max bid is 6 books (12 tricks total with 4-card kitty)

    return AlertDialog(
      title: Text('${_positionName(widget.currentBidder)}\'s Bid'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.highestBid != null)
            Text(
              'Current bid: ${widget.highestBid} books',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 16),

          // Books selection
          const Text('Number of books:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(
              maxBid - minBid + 1,
              (index) {
                final books = minBid + index;
                return ChoiceChip(
                  label: Text('$books'),
                  selected: _selectedBooks == books,
                  onSelected: (selected) {
                    setState(() {
                      _selectedBooks = selected ? books : null;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Uptown/Downtown selection
          const Text('Mode:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Uptown'),
                selected: _isUptown,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _isUptown = true);
                  }
                },
              ),
              ChoiceChip(
                label: const Text('Downtown'),
                selected: !_isUptown,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _isUptown = false);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onPass();
          },
          child: const Text('Pass'),
        ),
        FilledButton(
          onPressed: _selectedBooks == null
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onBid(_selectedBooks!, _isUptown);
                },
          child: const Text('Bid'),
        ),
      ],
    );
  }

  String _positionName(Position position) {
    switch (position) {
      case Position.north:
        return 'North';
      case Position.south:
        return 'You';
      case Position.east:
        return 'East';
      case Position.west:
        return 'West';
    }
  }
}
