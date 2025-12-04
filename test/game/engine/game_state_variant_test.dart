import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/game/engine/game_state.dart';
import 'package:minnesota_whist/src/game/variants/variant_type.dart';
import 'package:minnesota_whist/src/game/models/card.dart';

void main() {
  group('GameState variant integration', () {
    test('defaults to Minnesota Whist variant', () {
      final state = GameState();
      expect(state.variantType, equals(VariantType.minnesotaWhist));
    });

    test('can be created with specific variant', () {
      final state = GameState(variantType: VariantType.classicWhist);
      expect(state.variantType, equals(VariantType.classicWhist));
    });

    test('variant property throws UnimplementedError (stub)', () {
      final state = GameState();
      expect(() => state.variant, throwsUnimplementedError);
    });

    test('copyWith preserves variant type by default', () {
      final state = GameState(variantType: VariantType.bidWhist);
      final newState = state.copyWith(handNumber: 5);

      expect(newState.variantType, equals(VariantType.bidWhist));
      expect(newState.handNumber, equals(5));
    });

    test('copyWith can change variant type', () {
      final state = GameState(variantType: VariantType.minnesotaWhist);
      final newState = state.copyWith(variantType: VariantType.ohHell);

      expect(newState.variantType, equals(VariantType.ohHell));
    });

    group('special cards fields', () {
      test('special cards default to null', () {
        final state = GameState();
        expect(state.specialCards, isNull);
        expect(state.specialCardsLabel, isNull);
        expect(state.specialCardsRevealed, isNull);
      });

      test('can set special cards', () {
        final cards = [
          PlayingCard(rank: Rank.ace, suit: Suit.spades),
          PlayingCard(rank: Rank.king, suit: Suit.hearts),
        ];

        final state = GameState(
          specialCards: cards,
          specialCardsLabel: 'Kitty',
          specialCardsRevealed: true,
        );

        expect(state.specialCards, equals(cards));
        expect(state.specialCardsLabel, equals('Kitty'));
        expect(state.specialCardsRevealed, isTrue);
      });

      test('copyWith preserves special cards', () {
        final cards = [
          PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
        ];

        final state = GameState(
          specialCards: cards,
          specialCardsLabel: 'Widow',
        );

        final newState = state.copyWith(handNumber: 2);

        expect(newState.specialCards, equals(cards));
        expect(newState.specialCardsLabel, equals('Widow'));
      });

      test('copyWith can update special cards', () {
        final oldCards = [
          PlayingCard(rank: Rank.two, suit: Suit.clubs),
        ];

        final newCards = [
          PlayingCard(rank: Rank.ace, suit: Suit.spades),
          PlayingCard(rank: Rank.king, suit: Suit.hearts),
        ];

        final state = GameState(
          specialCards: oldCards,
          specialCardsLabel: 'Old',
        );

        final newState = state.copyWith(
          specialCards: newCards,
          specialCardsLabel: 'New',
        );

        expect(newState.specialCards, equals(newCards));
        expect(newState.specialCardsLabel, equals('New'));
      });

      test('clearSpecialCards removes special cards', () {
        final cards = [
          PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        ];

        final state = GameState(
          specialCards: cards,
          specialCardsLabel: 'Kitty',
        );

        final newState = state.copyWith(clearSpecialCards: true);

        expect(newState.specialCards, isNull);
        // Note: label is not cleared, only the cards
        expect(newState.specialCardsLabel, equals('Kitty'));
      });

      test('can reveal previously hidden special cards', () {
        final cards = [
          PlayingCard(rank: Rank.ten, suit: Suit.spades),
        ];

        final state = GameState(
          specialCards: cards,
          specialCardsRevealed: false,
        );

        final newState = state.copyWith(specialCardsRevealed: true);

        expect(newState.specialCards, equals(cards));
        expect(newState.specialCardsRevealed, isTrue);
      });
    });

    group('trump revealed field', () {
      test('trump revealed defaults to null', () {
        final state = GameState();
        expect(state.trumpRevealed, isNull);
      });

      test('can set trump revealed', () {
        final state = GameState(trumpRevealed: true);
        expect(state.trumpRevealed, isTrue);
      });

      test('copyWith preserves trump revealed', () {
        final state = GameState(trumpRevealed: false);
        final newState = state.copyWith(handNumber: 3);

        expect(newState.trumpRevealed, isFalse);
      });

      test('copyWith can update trump revealed', () {
        final state = GameState(trumpRevealed: false);
        final newState = state.copyWith(trumpRevealed: true);

        expect(newState.trumpRevealed, isTrue);
      });

      test('trump revealed works with trump suit', () {
        final state = GameState(
          trumpSuit: Suit.hearts,
          trumpRevealed: true,
        );

        expect(state.trumpSuit, equals(Suit.hearts));
        expect(state.trumpRevealed, isTrue);
      });
    });

    group('variant-specific game scenarios', () {
      test('Minnesota Whist scenario - no trump, no special cards', () {
        final state = GameState(
          variantType: VariantType.minnesotaWhist,
          trumpSuit: null,
          specialCards: null,
        );

        expect(state.variantType, equals(VariantType.minnesotaWhist));
        expect(state.trumpSuit, isNull);
        expect(state.specialCards, isNull);
      });

      test('Bid Whist scenario - trump and kitty', () {
        final kittyCards = [
          PlayingCard(rank: Rank.ace, suit: Suit.spades),
          PlayingCard(rank: Rank.king, suit: Suit.hearts),
          PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
          PlayingCard(rank: Rank.jack, suit: Suit.clubs),
          PlayingCard(rank: Rank.ten, suit: Suit.spades),
          PlayingCard(rank: Rank.nine, suit: Suit.hearts),
        ];

        final state = GameState(
          variantType: VariantType.bidWhist,
          trumpSuit: Suit.spades,
          trumpRevealed: true,
          specialCards: kittyCards,
          specialCardsLabel: 'Kitty',
          specialCardsRevealed: false,
        );

        expect(state.variantType, equals(VariantType.bidWhist));
        expect(state.trumpSuit, equals(Suit.spades));
        expect(state.trumpRevealed, isTrue);
        expect(state.specialCards?.length, equals(6));
        expect(state.specialCardsLabel, equals('Kitty'));
        expect(state.specialCardsRevealed, isFalse);
      });

      test('Widow Whist scenario - widow exchange', () {
        final widowCards = [
          PlayingCard(rank: Rank.seven, suit: Suit.clubs),
          PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
          PlayingCard(rank: Rank.nine, suit: Suit.hearts),
          PlayingCard(rank: Rank.ten, suit: Suit.spades),
        ];

        final state = GameState(
          variantType: VariantType.widowWhist,
          specialCards: widowCards,
          specialCardsLabel: 'Widow',
          specialCardsRevealed: true,
        );

        expect(state.variantType, equals(VariantType.widowWhist));
        expect(state.specialCards?.length, equals(4));
        expect(state.specialCardsLabel, equals('Widow'));
        expect(state.specialCardsRevealed, isTrue);
      });
    });

    group('all variant types can be used in GameState', () {
      test('Minnesota Whist', () {
        final state = GameState(variantType: VariantType.minnesotaWhist);
        expect(state.variantType, equals(VariantType.minnesotaWhist));
      });

      test('Classic Whist', () {
        final state = GameState(variantType: VariantType.classicWhist);
        expect(state.variantType, equals(VariantType.classicWhist));
      });

      test('Bid Whist', () {
        final state = GameState(variantType: VariantType.bidWhist);
        expect(state.variantType, equals(VariantType.bidWhist));
      });

      test('Oh Hell', () {
        final state = GameState(variantType: VariantType.ohHell);
        expect(state.variantType, equals(VariantType.ohHell));
      });

      test('Widow Whist', () {
        final state = GameState(variantType: VariantType.widowWhist);
        expect(state.variantType, equals(VariantType.widowWhist));
      });
    });

    group('immutability and copyWith', () {
      test('original state unchanged after copyWith', () {
        final originalCards = [
          PlayingCard(rank: Rank.ace, suit: Suit.spades),
        ];

        final state = GameState(
          variantType: VariantType.bidWhist,
          specialCards: originalCards,
        );

        final newCards = [
          PlayingCard(rank: Rank.king, suit: Suit.hearts),
        ];

        final newState = state.copyWith(
          variantType: VariantType.ohHell,
          specialCards: newCards,
        );

        // Original unchanged
        expect(state.variantType, equals(VariantType.bidWhist));
        expect(state.specialCards, equals(originalCards));

        // New state updated
        expect(newState.variantType, equals(VariantType.ohHell));
        expect(newState.specialCards, equals(newCards));
      });
    });
  });
}
