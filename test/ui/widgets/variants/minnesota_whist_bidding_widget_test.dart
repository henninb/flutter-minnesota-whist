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
        PlayingCard(rank: Rank.ace, suit: Suit.spades),   // Black (High)
        PlayingCard(rank: Rank.two, suit: Suit.spades),   // Black (High)
        PlayingCard(rank: Rank.king, suit: Suit.hearts),  // Red (Low)
        PlayingCard(rank: Rank.three, suit: Suit.hearts), // Red (Low)
        PlayingCard(rank: Rank.queen, suit: Suit.clubs),  // Black (High)
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

      // Should show instructions
      expect(find.textContaining('Black = HIGH'), findsOneWidget);
      expect(find.textContaining('Red = LOW'), findsOneWidget);

      // Should show black and red card sections
      expect(find.text('Black Cards (HIGH Bid)'), findsOneWidget);
      expect(find.text('Red Cards (LOW Bid)'), findsOneWidget);
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

      // Find a card widget (look for rank symbol)
      final cardFinder = find.text('A'); // Ace of spades
      expect(cardFinder, findsOneWidget);

      // Tap on the card
      await tester.tap(cardFinder);
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

      // Select a card
      final cardFinder = find.text('A'); // Ace of spades
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Confirm the bid
      final confirmButton = find.textContaining('Confirm Bid');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Should have submitted the bid
      expect(submittedBid, isNotNull);
      expect(submittedBid, isA<PlayingCard>());
      final card = submittedBid as PlayingCard;
      expect(card.rank, equals(Rank.ace));
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

      // Select a black card (HIGH bid)
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      // Should show "Bidding HIGH"
      expect(find.textContaining('Bidding HIGH'), findsOneWidget);
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

      // Should show black cards
      expect(find.text('Black Cards (HIGH Bid)'), findsOneWidget);

      // Should show message about no red cards
      expect(find.textContaining('No red cards in hand'), findsOneWidget);
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

      // Should show red cards
      expect(find.text('Red Cards (LOW Bid)'), findsOneWidget);

      // Should show message about no black cards
      expect(find.textContaining('No black cards in hand'), findsOneWidget);
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

      // Tap a card to select it
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      // Should show the selected card in the status display
      expect(find.textContaining('A♠'), findsAtLeastNWidgets(1));
    });
  });
}
