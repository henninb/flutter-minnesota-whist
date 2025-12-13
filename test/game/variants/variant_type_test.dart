import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/game/variants/variant_type.dart';
import 'package:minnesota_whist/src/game/variants/game_variant.dart';
import 'package:minnesota_whist/src/game/models/game_models.dart';

void main() {
  group('VariantType', () {
    test('has exactly 5 variants', () {
      expect(VariantType.values.length, equals(5));
    });

    test('includes all expected variants', () {
      expect(VariantType.values, contains(VariantType.minnesotaWhist));
      expect(VariantType.values, contains(VariantType.classicWhist));
      expect(VariantType.values, contains(VariantType.bidWhist));
      expect(VariantType.values, contains(VariantType.ohHell));
      expect(VariantType.values, contains(VariantType.widowWhist));
    });

    group('displayName', () {
      test('Minnesota Whist has correct display name', () {
        expect(
          VariantType.minnesotaWhist.displayName,
          equals('Minnesota Whist'),
        );
      });

      test('Classic Whist has correct display name', () {
        expect(
          VariantType.classicWhist.displayName,
          equals('Classic Whist'),
        );
      });

      test('Bid Whist has correct display name', () {
        expect(
          VariantType.bidWhist.displayName,
          equals('Bid Whist'),
        );
      });

      test('Oh Hell has correct display name', () {
        expect(
          VariantType.ohHell.displayName,
          equals('Oh Hell'),
        );
      });

      test('Widow Whist has correct display name', () {
        expect(
          VariantType.widowWhist.displayName,
          equals('Widow Whist'),
        );
      });

      test('all display names are non-empty', () {
        for (final variant in VariantType.values) {
          expect(variant.displayName, isNotEmpty);
        }
      });

      test('all display names are unique', () {
        final displayNames =
            VariantType.values.map((v) => v.displayName).toSet();
        expect(displayNames.length, equals(VariantType.values.length));
      });
    });

    group('shortDescription', () {
      test('Minnesota Whist has description', () {
        expect(
          VariantType.minnesotaWhist.shortDescription,
          contains('Simultaneous bidding'),
        );
        expect(
          VariantType.minnesotaWhist.shortDescription,
          contains('black/red cards'),
        );
      });

      test('Classic Whist has description', () {
        expect(
          VariantType.classicWhist.shortDescription,
          contains('Traditional'),
        );
      });

      test('Bid Whist has description', () {
        expect(
          VariantType.bidWhist.shortDescription,
          contains('Sequential bidding'),
        );
        expect(
          VariantType.bidWhist.shortDescription,
          contains('kitty'),
        );
      });

      test('Oh Hell has description', () {
        expect(
          VariantType.ohHell.shortDescription,
          contains('exact'),
        );
        expect(
          VariantType.ohHell.shortDescription,
          contains('tricks'),
        );
      });

      test('Widow Whist has description', () {
        expect(
          VariantType.widowWhist.shortDescription,
          contains('widow'),
        );
      });

      test('all descriptions are non-empty', () {
        for (final variant in VariantType.values) {
          expect(variant.shortDescription, isNotEmpty);
        }
      });

      test('all descriptions are reasonably short (< 100 chars)', () {
        for (final variant in VariantType.values) {
          expect(
            variant.shortDescription.length,
            lessThan(100),
            reason: '${variant.displayName} description is too long',
          );
        }
      });
    });

    group('createVariant', () {
      test('Minnesota Whist creates variant successfully', () {
        final variant = VariantType.minnesotaWhist.createVariant();
        expect(variant, isNotNull);
        expect(variant.name, equals('Minnesota Whist'));
      });

      test('unimplemented variants throw UnimplementedError', () {
        expect(
          () => VariantType.classicWhist.createVariant(),
          throwsUnimplementedError,
        );
        expect(
          () => VariantType.bidWhist.createVariant(),
          throwsUnimplementedError,
        );
        expect(
          () => VariantType.ohHell.createVariant(),
          throwsUnimplementedError,
        );
        expect(
          () => VariantType.widowWhist.createVariant(),
          throwsUnimplementedError,
        );
      });

      test('Minnesota Whist variant has bidding engine', () {
        final variant = VariantType.minnesotaWhist.createVariant();
        expect(variant.usesBidding, isTrue);

        final biddingEngine = variant.createBiddingEngine(Position.west);
        expect(biddingEngine, isNotNull);
      });

      test('Minnesota Whist variant has scoring engine', () {
        final variant = VariantType.minnesotaWhist.createVariant();

        final scoringEngine = variant.createScoringEngine();
        expect(scoringEngine, isNotNull);
      });

      test('Minnesota Whist variant has correct properties', () {
        final variant = VariantType.minnesotaWhist.createVariant();

        expect(variant.trumpSelectionMethod, equals(TrumpSelectionMethod.none));
        expect(variant.hasSpecialCards, isFalse);
        expect(variant.tricksPerHand, equals(13));
        expect(variant.winningScore, equals(13));
      });
    });

    group('fromName', () {
      test('returns correct variant for valid name', () {
        expect(
          VariantTypeExtension.fromName('minnesotaWhist'),
          equals(VariantType.minnesotaWhist),
        );
        expect(
          VariantTypeExtension.fromName('classicWhist'),
          equals(VariantType.classicWhist),
        );
        expect(
          VariantTypeExtension.fromName('bidWhist'),
          equals(VariantType.bidWhist),
        );
        expect(
          VariantTypeExtension.fromName('ohHell'),
          equals(VariantType.ohHell),
        );
        expect(
          VariantTypeExtension.fromName('widowWhist'),
          equals(VariantType.widowWhist),
        );
      });

      test('defaults to Minnesota Whist for invalid name', () {
        expect(
          VariantTypeExtension.fromName('invalidVariant'),
          equals(VariantType.minnesotaWhist),
        );
      });

      test('defaults to Minnesota Whist for empty string', () {
        expect(
          VariantTypeExtension.fromName(''),
          equals(VariantType.minnesotaWhist),
        );
      });

      test('is case-sensitive', () {
        // Dart enum names are case-sensitive
        expect(
          VariantTypeExtension.fromName('MinnesotaWhist'), // Wrong case
          equals(VariantType.minnesotaWhist), // Should default
        );
      });

      test('round-trip serialization works', () {
        for (final variant in VariantType.values) {
          final name = variant.name;
          final restored = VariantTypeExtension.fromName(name);
          expect(restored, equals(variant));
        }
      });
    });

    group('enum name property', () {
      test('Minnesota Whist has correct enum name', () {
        expect(VariantType.minnesotaWhist.name, equals('minnesotaWhist'));
      });

      test('Classic Whist has correct enum name', () {
        expect(VariantType.classicWhist.name, equals('classicWhist'));
      });

      test('Bid Whist has correct enum name', () {
        expect(VariantType.bidWhist.name, equals('bidWhist'));
      });

      test('Oh Hell has correct enum name', () {
        expect(VariantType.ohHell.name, equals('ohHell'));
      });

      test('Widow Whist has correct enum name', () {
        expect(VariantType.widowWhist.name, equals('widowWhist'));
      });

      test('all enum names are camelCase', () {
        for (final variant in VariantType.values) {
          expect(variant.name[0], equals(variant.name[0].toLowerCase()));
        }
      });
    });

    group('variant ordering', () {
      test('Minnesota Whist is first (default variant)', () {
        expect(VariantType.values.first, equals(VariantType.minnesotaWhist));
      });

      test('variants are in expected order', () {
        expect(VariantType.values[0], equals(VariantType.minnesotaWhist));
        expect(VariantType.values[1], equals(VariantType.classicWhist));
        expect(VariantType.values[2], equals(VariantType.bidWhist));
        expect(VariantType.values[3], equals(VariantType.ohHell));
        expect(VariantType.values[4], equals(VariantType.widowWhist));
      });
    });
  });
}
