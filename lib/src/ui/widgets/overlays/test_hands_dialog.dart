import 'package:flutter/material.dart';
import '../../../game/models/card.dart';
import '../../../game/models/test_hands.dart';

/// Dialog for selecting test hands during debugging/testing
///
/// Provides two tabs:
/// 1. Canned Scenarios - Pre-defined interesting hands
/// 2. Random with Constraints - Generate random hands with specific requirements
class TestHandsDialog extends StatefulWidget {
  const TestHandsDialog({
    super.key,
    required this.onTestHandSelected,
  });

  final Function(List<PlayingCard> testHand) onTestHandSelected;

  @override
  State<TestHandsDialog> createState() => _TestHandsDialogState();
}

class _TestHandsDialogState extends State<TestHandsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Hands',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a test hand for debugging',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Canned Scenarios'),
                Tab(text: 'Random + Constraints'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScenariosTab(),
                  _buildConstraintsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenariosTab() {
    return ListView.builder(
      itemCount: TestHands.scenarios.length,
      itemBuilder: (context, index) {
        final scenario = TestHands.scenarios[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              scenario.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(scenario.description),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: scenario.cards
                      .map(
                        (card) => Chip(
                          label: Text(
                            card.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCardColor(card, context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => widget.onTestHandSelected(scenario.cards),
          ),
        );
      },
    );
  }

  Widget _buildConstraintsTab() {
    // Minnesota Whist: Use predefined scenarios (no random generation)
    return _buildScenariosTab();
  }

  Color _getCardColor(PlayingCard card, BuildContext context) {
    switch (card.suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return Colors.red;
      case Suit.spades:
      case Suit.clubs:
        return Colors.black87;
    }
  }

  // Minnesota Whist: Removed random hand generation (use predefined scenarios instead)
}
