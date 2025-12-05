import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/ui/widgets/variant_selector.dart';
import 'package:minnesota_whist/src/game/variants/variant_type.dart';

void main() {
  group('VariantSelector', () {
    testWidgets('renders all 5 variants', (WidgetTester tester) async {
      VariantType? selectedVariant;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) => selectedVariant = variant,
            ),
          ),
        ),
      );

      // Should show the title
      expect(find.text('Select Game Variant'), findsOneWidget);

      // Should show all 5 variant names
      expect(find.text('Minnesota Whist'), findsOneWidget);
      expect(find.text('Classic Whist'), findsOneWidget);
      expect(find.text('Bid Whist'), findsOneWidget);
      expect(find.text('Oh Hell'), findsOneWidget);
      expect(find.text('Widow Whist'), findsOneWidget);
    });

    testWidgets('shows Minnesota Whist as selectable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) {},
            ),
          ),
        ),
      );

      // Minnesota Whist should NOT have "Coming Soon" badge
      final minnesotaCard = find.ancestor(
        of: find.text('Minnesota Whist'),
        matching: find.byType(InkWell),
      );
      expect(minnesotaCard, findsOneWidget);
    });

    testWidgets('shows unimplemented variants as coming soon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) {},
            ),
          ),
        ),
      );

      // Should show "Coming Soon" badges (4 for unimplemented variants)
      expect(find.text('Coming Soon'), findsNWidgets(4));
    });

    testWidgets('indicates selected variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) {},
            ),
          ),
        ),
      );

      // Should show checkmark for selected variant
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('calls onVariantSelected when tapping Minnesota Whist',
        (WidgetTester tester) async {
      VariantType? selectedVariant;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) => selectedVariant = variant,
            ),
          ),
        ),
      );

      // Tap on Minnesota Whist
      await tester.tap(find.text('Minnesota Whist'));
      await tester.pumpAndSettle();

      // Should have called the callback
      expect(selectedVariant, equals(VariantType.minnesotaWhist));
    });

    testWidgets('does not call onVariantSelected for unimplemented variants',
        (WidgetTester tester) async {
      VariantType? selectedVariant;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) => selectedVariant = variant,
            ),
          ),
        ),
      );

      // Try to tap on Classic Whist (unimplemented)
      await tester.tap(find.text('Classic Whist'));
      await tester.pumpAndSettle();

      // Should not have changed the selection
      expect(selectedVariant, isNull);
    });

    testWidgets('shows info message about more variants coming',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) {},
            ),
          ),
        ),
      );

      expect(find.text('More variants coming soon!'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays variant short descriptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantSelector(
              selectedVariant: VariantType.minnesotaWhist,
              onVariantSelected: (variant) {},
            ),
          ),
        ),
      );

      // Should show the short description for Minnesota Whist
      expect(
        find.textContaining('Simultaneous bidding'),
        findsOneWidget,
      );
    });

    testWidgets('updates selection visually when variant changes',
        (WidgetTester tester) async {
      VariantType currentVariant = VariantType.minnesotaWhist;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: VariantSelector(
                  selectedVariant: currentVariant,
                  onVariantSelected: (variant) {
                    setState(() {
                      currentVariant = variant;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Initially should have 1 checkmark
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Tap Minnesota Whist again
      await tester.tap(find.text('Minnesota Whist'));
      await tester.pumpAndSettle();

      // Should still have 1 checkmark
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('has proper icons and appearance',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VariantSelector(
                selectedVariant: VariantType.minnesotaWhist,
                onVariantSelected: (variant) {},
              ),
            ),
          ),
        ),
      );

      // Should have card-like appearance icons
      expect(find.byIcon(Icons.view_carousel), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });
  });
}
