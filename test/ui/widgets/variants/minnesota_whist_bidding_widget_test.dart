import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/ui/widgets/variants/minnesota_whist_bidding_widget.dart';
import 'package:minnesota_whist/src/ui/context/variant_ui_context.dart';
import 'package:minnesota_whist/src/game/models/card.dart';
import 'package:minnesota_whist/src/game/models/game_models.dart';
import 'package:minnesota_whist/src/game/engine/game_state.dart';

void main() {
  group('MinnesotaWhistBiddingWidget', () {
    late List<PlayingCard> playerHand;
    late BiddingWidgetContext biddingContext;
    dynamic submittedBid;

    setUp(() {
      playerHand = [
        PlayingCard(rank: Rank.ace, suit: Suit.spades), // Black (High)
        PlayingCard(rank: Rank.two, suit: Suit.spades), // Black (High)
        PlayingCard(rank: Rank.king, suit: Suit.hearts), // Red (Low)
        PlayingCard(rank: Rank.three, suit: Suit.hearts), // Red (Low)
        PlayingCard(rank: Rank.queen, suit: Suit.clubs), // Black (High)
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds), // Red (Low)
      ];

      submittedBid = null;

      biddingContext = BiddingWidgetContext(
        playerHand: playerHand,
        currentBids: [],
        currentBidder: Position.south,
        onBidSubmitted: (bid) => submittedBid = bid,
        gameState: const GameState(),
      );
    });

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: biddingContext),
            ),
          ),
        ),
      );

      // Should render the title
      expect(find.text('Place Your Bid'), findsOneWidget);
    });

    testWidgets('displays player hand cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: biddingContext),
            ),
          ),
        ),
      );

      // Should show HIGH and LOW sections
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('LOW'), findsOneWidget);

      // Should show suit symbols
      expect(find.text('♠♣'), findsOneWidget); // Black suits
      expect(find.text('♥♦'), findsOneWidget); // Red suits
    });

    testWidgets('allows selecting a card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: biddingContext),
            ),
          ),
        ),
      );

      // Find the HIGH section container and tap it
      // The widget shows only the lowest black card (2 of spades)
      final highSection = find.ancestor(
        of: find.text('HIGH'),
        matching: find.byType(MouseRegion),
      );
      expect(highSection, findsOneWidget);

      // Tap on the HIGH section to select it
      await tester.tap(highSection);
      await tester.pumpAndSettle();

      // Should show confirm button after selection
      expect(find.textContaining('Confirm Bid'), findsOneWidget);
    });

    testWidgets('submits bid when confirm button pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: biddingContext),
            ),
          ),
        ),
      );

      // Select the HIGH section (which contains the 2 of spades)
      final highSection = find.ancestor(
        of: find.text('HIGH'),
        matching: find.byType(MouseRegion),
      );
      await tester.tap(highSection);
      await tester.pumpAndSettle();

      // Confirm the bid
      final confirmButton = find.textContaining('Confirm Bid');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Should have submitted the bid (lowest black card = 2 of spades)
      expect(submittedBid, isNotNull);
      expect(submittedBid, isA<PlayingCard>());
      final card = submittedBid as PlayingCard;
      expect(card.rank, equals(Rank.two));
      expect(card.suit, equals(Suit.spades));
    });

    testWidgets('displays current selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: biddingContext),
            ),
          ),
        ),
      );

      // Select the HIGH section (2 of spades)
      final highSection = find.ancestor(
        of: find.text('HIGH'),
        matching: find.byType(MouseRegion),
      );
      await tester.tap(highSection);
      await tester.pumpAndSettle();

      // Should show "HIGH: 2♠" in the selection display
      expect(find.textContaining('HIGH: 2♠'), findsOneWidget);
    });

    testWidgets('handles hand with only black cards',
        (WidgetTester tester) async {
      final blackOnlyHand = [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.clubs),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
      ];

      final context = BiddingWidgetContext(
        playerHand: blackOnlyHand,
        currentBids: [],
        currentBidder: Position.south,
        onBidSubmitted: (bid) {},
        gameState: const GameState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: context),
            ),
          ),
        ),
      );

      // Should show HIGH section
      expect(find.text('HIGH'), findsOneWidget);

      // Should show LOW section with "None" message
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('handles hand with only red cards',
        (WidgetTester tester) async {
      final redOnlyHand = [
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.diamonds),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
      ];

      final context = BiddingWidgetContext(
        playerHand: redOnlyHand,
        currentBids: [],
        currentBidder: Position.south,
        onBidSubmitted: (bid) {},
        gameState: const GameState(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: context),
            ),
          ),
        ),
      );

      // Should show LOW section
      expect(find.text('LOW'), findsOneWidget);

      // Should show HIGH section with "None" message
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('card selection is visually indicated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: MinnesotaWhistBiddingWidget(context: biddingContext),
            ),
          ),
        ),
      );

      // Tap the HIGH section to select it (selects 2 of spades)
      final highSection = find.ancestor(
        of: find.text('HIGH'),
        matching: find.byType(MouseRegion),
      );
      await tester.tap(highSection);
      await tester.pumpAndSettle();

      // Should show the selected card in the status display and confirm button
      expect(find.textContaining('2♠'), findsAtLeastNWidgets(1));
    });
  });
}
