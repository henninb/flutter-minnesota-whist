import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/ui/context/variant_ui_context.dart';
import 'package:minnesota_whist/src/game/models/card.dart';
import 'package:minnesota_whist/src/game/models/game_models.dart';
import 'package:minnesota_whist/src/game/engine/game_state.dart';

void main() {
  group('BiddingWidgetContext', () {
    late List<PlayingCard> playerHand;
    late List<BidEntry> currentBids;
    late GameState gameState;

    setUp(() {
      playerHand = [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
      ];

      currentBids = [
        BidEntry(
          bidder: Position.west,
          bid: Bid(
            bidType: BidType.high,
            bidder: Position.west,
            bidCard: PlayingCard(rank: Rank.ace, suit: Suit.spades),
          ),
        ),
      ];

      gameState = const GameState();
    });

    test('stores all provided data', () {
      var callbackInvoked = false;
      void onBidSubmitted(dynamic bid) {
        callbackInvoked = true;
      }

      final context = BiddingWidgetContext(
        playerHand: playerHand,
        currentBids: currentBids,
        currentBidder: Position.south,
        onBidSubmitted: onBidSubmitted,
        gameState: gameState,
      );

      expect(context.playerHand, equals(playerHand));
      expect(context.currentBids, equals(currentBids));
      expect(context.currentBidder, equals(Position.south));
      expect(context.gameState, equals(gameState));

      // Test callback
      context.onBidSubmitted('test bid');
      expect(callbackInvoked, isTrue);
    });

    test('callback can be invoked with different bid types', () {
      dynamic capturedBid;
      void onBidSubmitted(dynamic bid) {
        capturedBid = bid;
      }

      final context = BiddingWidgetContext(
        playerHand: playerHand,
        currentBids: currentBids,
        currentBidder: Position.south,
        onBidSubmitted: onBidSubmitted,
        gameState: gameState,
      );

      // Test with card
      final card = PlayingCard(rank: Rank.two, suit: Suit.clubs);
      context.onBidSubmitted(card);
      expect(capturedBid, equals(card));

      // Test with number
      context.onBidSubmitted(7);
      expect(capturedBid, equals(7));

      // Test with custom object
      final customBid = {'tricks': 5, 'trump': 'spades'};
      context.onBidSubmitted(customBid);
      expect(capturedBid, equals(customBid));
    });
  });

  group('TrumpIndicatorContext', () {
    late GameState gameState;

    setUp(() {
      gameState = const GameState();
    });

    test('stores trump data when revealed', () {
      final context = TrumpIndicatorContext(
        trumpSuit: Suit.hearts,
        isRevealed: true,
        declarer: Position.south,
        gameState: gameState,
      );

      expect(context.trumpSuit, equals(Suit.hearts));
      expect(context.isRevealed, isTrue);
      expect(context.declarer, equals(Position.south));
      expect(context.gameState, equals(gameState));
    });

    test('handles no trump (null suit)', () {
      final context = TrumpIndicatorContext(
        trumpSuit: null,
        isRevealed: true,
        gameState: gameState,
      );

      expect(context.trumpSuit, isNull);
      expect(context.declarer, isNull);
    });

    test('handles unrevealed trump', () {
      final context = TrumpIndicatorContext(
        trumpSuit: Suit.spades,
        isRevealed: false,
        gameState: gameState,
      );

      expect(context.trumpSuit, equals(Suit.spades));
      expect(context.isRevealed, isFalse);
    });
  });

  group('SpecialCardContext', () {
    late List<PlayingCard> cards;
    late GameState gameState;

    setUp(() {
      cards = [
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
        PlayingCard(rank: Rank.queen, suit: Suit.clubs),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
      ];

      gameState = const GameState();
    });

    test('stores special card data', () {
      final context = SpecialCardContext(
        cards: cards,
        isRevealed: true,
        label: 'Kitty',
        gameState: gameState,
      );

      expect(context.cards, equals(cards));
      expect(context.isRevealed, isTrue);
      expect(context.label, equals('Kitty'));
      expect(context.onCardsSelected, isNull);
      expect(context.gameState, equals(gameState));
    });

    test('handles widow label', () {
      final context = SpecialCardContext(
        cards: cards,
        isRevealed: false,
        label: 'Widow',
        gameState: gameState,
      );

      expect(context.label, equals('Widow'));
    });

    test('supports card selection callback', () {
      List<PlayingCard>? selectedCards;
      void onCardsSelected(List<PlayingCard> cards) {
        selectedCards = cards;
      }

      final context = SpecialCardContext(
        cards: cards,
        isRevealed: true,
        label: 'Kitty',
        onCardsSelected: onCardsSelected,
        gameState: gameState,
      );

      // Test callback
      final selection = [cards[0], cards[1]];
      context.onCardsSelected!(selection);
      expect(selectedCards, equals(selection));
    });

    test('handles empty card list', () {
      final context = SpecialCardContext(
        cards: [],
        isRevealed: true,
        label: 'Empty',
        gameState: gameState,
      );

      expect(context.cards, isEmpty);
    });
  });

  group('GameAction', () {
    test('creates enabled action with all properties', () {
      var tapped = false;
      void onTap() {
        tapped = true;
      }

      final action = GameAction(
        label: 'Deal Cards',
        icon: Icons.style,
        onTap: onTap,
      );

      expect(action.label, equals('Deal Cards'));
      expect(action.icon, equals(Icons.style));
      expect(action.isEnabled, isTrue);
      expect(action.disabledReason, isNull);

      action.onTap();
      expect(tapped, isTrue);
    });

    test('creates disabled action with reason', () {
      final action = GameAction(
        label: 'Claim Tricks',
        icon: Icons.bolt,
        onTap: () {},
        isEnabled: false,
        disabledReason: 'Cannot guarantee all remaining tricks',
      );

      expect(action.isEnabled, isFalse);
      expect(action.disabledReason, equals('Cannot guarantee all remaining tricks'));
    });

    test('supports various icon types', () {
      final dealAction = GameAction(
        label: 'Deal',
        icon: Icons.style,
        onTap: () {},
      );

      final bidAction = GameAction(
        label: 'Bid',
        icon: Icons.gavel,
        onTap: () {},
      );

      final claimAction = GameAction(
        label: 'Claim',
        icon: Icons.bolt,
        onTap: () {},
      );

      expect(dealAction.icon, equals(Icons.style));
      expect(bidAction.icon, equals(Icons.gavel));
      expect(claimAction.icon, equals(Icons.bolt));
    });

    test('enabled action has no disabled reason', () {
      final action = GameAction(
        label: 'Next Hand',
        icon: Icons.arrow_forward,
        onTap: () {},
        isEnabled: true,
      );

      expect(action.isEnabled, isTrue);
      expect(action.disabledReason, isNull);
    });

    test('callback can perform various operations', () {
      var counter = 0;
      void incrementCounter() {
        counter++;
      }

      final action = GameAction(
        label: 'Increment',
        icon: Icons.add,
        onTap: incrementCounter,
      );

      action.onTap();
      action.onTap();
      action.onTap();

      expect(counter, equals(3));
    });
  });

  group('Context classes integration', () {
    test('all contexts work together in a game scenario', () {
      // Setup game state
      const gameState = GameState(
        currentPhase: GamePhase.bidding,
        dealer: Position.west,
      );

      // Setup bidding context
      final playerHand = [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.two, suit: Suit.hearts),
      ];

      dynamic submittedBid;
      final biddingContext = BiddingWidgetContext(
        playerHand: playerHand,
        currentBids: [],
        currentBidder: Position.south,
        onBidSubmitted: (bid) => submittedBid = bid,
        gameState: gameState,
      );

      // Setup trump context (no trump yet)
      final trumpContext = TrumpIndicatorContext(
        trumpSuit: null,
        isRevealed: false,
        gameState: gameState,
      );

      // Setup special cards context
      final kittyCards = [
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
      ];

      List<PlayingCard>? selectedKittyCards;
      final specialCardContext = SpecialCardContext(
        cards: kittyCards,
        isRevealed: false,
        label: 'Kitty',
        onCardsSelected: (cards) => selectedKittyCards = cards,
        gameState: gameState,
      );

      // Verify all contexts are properly initialized
      expect(biddingContext.gameState.currentPhase, equals(GamePhase.bidding));
      expect(trumpContext.trumpSuit, isNull);
      expect(specialCardContext.cards.length, equals(1));

      // Simulate interactions
      biddingContext.onBidSubmitted(playerHand[0]);
      expect(submittedBid, equals(playerHand[0]));

      specialCardContext.onCardsSelected!(kittyCards);
      expect(selectedKittyCards, equals(kittyCards));
    });
  });
}
