import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/models/game_settings.dart';
import 'package:minnesota_whist/src/game/variants/variant_type.dart';
import 'package:minnesota_whist/src/models/theme_models.dart';

void main() {
  group('GameSettings variant support', () {
    test('defaults to Minnesota Whist variant', () {
      const settings = GameSettings();
      expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
    });

    test('can be created with specific variant', () {
      const settings = GameSettings(
        selectedVariant: VariantType.classicWhist,
      );
      expect(settings.selectedVariant, equals(VariantType.classicWhist));
    });

    test('preserves other settings with variant', () {
      const settings = GameSettings(
        cardSelectionMode: CardSelectionMode.longPress,
        countingMode: CountingMode.automatic,
        selectedTheme: ThemeType.fall,
        selectedVariant: VariantType.bidWhist,
      );

      expect(settings.cardSelectionMode, equals(CardSelectionMode.longPress));
      expect(settings.countingMode, equals(CountingMode.automatic));
      expect(settings.selectedTheme, equals(ThemeType.fall));
      expect(settings.selectedVariant, equals(VariantType.bidWhist));
    });

    group('copyWith', () {
      test('preserves variant by default', () {
        const settings = GameSettings(
          selectedVariant: VariantType.ohHell,
        );

        final newSettings = settings.copyWith(
          cardSelectionMode: CardSelectionMode.drag,
        );

        expect(newSettings.selectedVariant, equals(VariantType.ohHell));
        expect(newSettings.cardSelectionMode, equals(CardSelectionMode.drag));
      });

      test('can change variant', () {
        const settings = GameSettings(
          selectedVariant: VariantType.minnesotaWhist,
        );

        final newSettings = settings.copyWith(
          selectedVariant: VariantType.widowWhist,
        );

        expect(newSettings.selectedVariant, equals(VariantType.widowWhist));
      });

      test('preserves all settings when changing variant', () {
        const settings = GameSettings(
          cardSelectionMode: CardSelectionMode.longPress,
          countingMode: CountingMode.automatic,
          selectedTheme: ThemeType.summer,
          selectedVariant: VariantType.minnesotaWhist,
        );

        final newSettings = settings.copyWith(
          selectedVariant: VariantType.bidWhist,
        );

        expect(newSettings.cardSelectionMode, equals(CardSelectionMode.longPress));
        expect(newSettings.countingMode, equals(CountingMode.automatic));
        expect(newSettings.selectedTheme, equals(ThemeType.summer));
        expect(newSettings.selectedVariant, equals(VariantType.bidWhist));
      });
    });

    group('JSON serialization', () {
      test('toJson includes variant', () {
        const settings = GameSettings(
          selectedVariant: VariantType.classicWhist,
        );

        final json = settings.toJson();

        expect(json['selectedVariant'], equals('classicWhist'));
      });

      test('toJson serializes all fields including variant', () {
        const settings = GameSettings(
          cardSelectionMode: CardSelectionMode.drag,
          countingMode: CountingMode.automatic,
          selectedTheme: ThemeType.winter,
          selectedVariant: VariantType.bidWhist,
        );

        final json = settings.toJson();

        expect(json['cardSelectionMode'], equals('drag'));
        expect(json['countingMode'], equals('automatic'));
        expect(json['selectedTheme'], equals('winter'));
        expect(json['selectedVariant'], equals('bidWhist'));
      });

      test('fromJson restores variant', () {
        final json = {
          'cardSelectionMode': 'tap',
          'countingMode': 'automatic',
          'selectedTheme': 'spring',
          'selectedVariant': 'ohHell',
        };

        final settings = GameSettings.fromJson(json);

        expect(settings.selectedVariant, equals(VariantType.ohHell));
      });

      test('fromJson defaults to Minnesota Whist for missing variant', () {
        final json = {
          'cardSelectionMode': 'tap',
          'countingMode': 'automatic',
        };

        final settings = GameSettings.fromJson(json);

        expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
      });

      test('fromJson defaults to Minnesota Whist for null variant', () {
        final json = {
          'cardSelectionMode': 'tap',
          'countingMode': 'automatic',
          'selectedVariant': null,
        };

        final settings = GameSettings.fromJson(json);

        expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
      });

      test('fromJson defaults to Minnesota Whist for invalid variant name', () {
        final json = {
          'cardSelectionMode': 'tap',
          'countingMode': 'automatic',
          'selectedVariant': 'invalidVariant',
        };

        final settings = GameSettings.fromJson(json);

        expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
      });

      test('round-trip serialization preserves variant', () {
        const original = GameSettings(
          selectedVariant: VariantType.widowWhist,
        );

        final json = original.toJson();
        final restored = GameSettings.fromJson(json);

        expect(restored.selectedVariant, equals(VariantType.widowWhist));
      });

      test('round-trip for all variants', () {
        for (final variant in VariantType.values) {
          final original = GameSettings(selectedVariant: variant);
          final json = original.toJson();
          final restored = GameSettings.fromJson(json);

          expect(
            restored.selectedVariant,
            equals(variant),
            reason: 'Failed for ${variant.name}',
          );
        }
      });
    });

    group('equality', () {
      test('equal settings with same variant', () {
        const settings1 = GameSettings(
          selectedVariant: VariantType.bidWhist,
        );
        const settings2 = GameSettings(
          selectedVariant: VariantType.bidWhist,
        );

        expect(settings1, equals(settings2));
        expect(settings1.hashCode, equals(settings2.hashCode));
      });

      test('not equal with different variants', () {
        const settings1 = GameSettings(
          selectedVariant: VariantType.minnesotaWhist,
        );
        const settings2 = GameSettings(
          selectedVariant: VariantType.classicWhist,
        );

        expect(settings1, isNot(equals(settings2)));
      });

      test('equality checks all fields including variant', () {
        const settings1 = GameSettings(
          cardSelectionMode: CardSelectionMode.tap,
          countingMode: CountingMode.automatic,
          selectedTheme: ThemeType.spring,
          selectedVariant: VariantType.minnesotaWhist,
        );

        const settings2 = GameSettings(
          cardSelectionMode: CardSelectionMode.tap,
          countingMode: CountingMode.automatic,
          selectedTheme: ThemeType.spring,
          selectedVariant: VariantType.minnesotaWhist,
        );

        const settings3 = GameSettings(
          cardSelectionMode: CardSelectionMode.tap,
          countingMode: CountingMode.automatic,
          selectedTheme: ThemeType.spring,
          selectedVariant: VariantType.classicWhist, // Different
        );

        expect(settings1, equals(settings2));
        expect(settings1, isNot(equals(settings3)));
      });

      test('identical settings are equal', () {
        const settings = GameSettings(
          selectedVariant: VariantType.ohHell,
        );

        expect(identical(settings, settings), isTrue);
        expect(settings == settings, isTrue);
      });
    });

    group('all variants supported in settings', () {
      test('Minnesota Whist', () {
        const settings = GameSettings(
          selectedVariant: VariantType.minnesotaWhist,
        );
        expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
      });

      test('Classic Whist', () {
        const settings = GameSettings(
          selectedVariant: VariantType.classicWhist,
        );
        expect(settings.selectedVariant, equals(VariantType.classicWhist));
      });

      test('Bid Whist', () {
        const settings = GameSettings(
          selectedVariant: VariantType.bidWhist,
        );
        expect(settings.selectedVariant, equals(VariantType.bidWhist));
      });

      test('Oh Hell', () {
        const settings = GameSettings(
          selectedVariant: VariantType.ohHell,
        );
        expect(settings.selectedVariant, equals(VariantType.ohHell));
      });

      test('Widow Whist', () {
        const settings = GameSettings(
          selectedVariant: VariantType.widowWhist,
        );
        expect(settings.selectedVariant, equals(VariantType.widowWhist));
      });
    });

    group('migration scenarios', () {
      test('old settings without variant default to Minnesota Whist', () {
        // Simulates loading old saved settings
        final json = {
          'cardSelectionMode': 'tap',
          'countingMode': 'automatic',
          'selectedTheme': 'spring',
          // No selectedVariant field
        };

        final settings = GameSettings.fromJson(json);

        expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
        expect(settings.cardSelectionMode, equals(CardSelectionMode.tap));
        expect(settings.countingMode, equals(CountingMode.automatic));
        expect(settings.selectedTheme, equals(ThemeType.spring));
      });

      test('corrupted variant name defaults to Minnesota Whist', () {
        final json = {
          'selectedVariant': 'CORRUPTED_VALUE_123',
        };

        final settings = GameSettings.fromJson(json);

        expect(settings.selectedVariant, equals(VariantType.minnesotaWhist));
      });
    });
  });
}
