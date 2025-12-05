import 'package:flutter/material.dart';
import '../../game/variants/variant_type.dart';

/// Widget for selecting which whist variant to play
class VariantSelector extends StatefulWidget {
  const VariantSelector({
    super.key,
    required this.selectedVariant,
    required this.onVariantSelected,
  });

  final VariantType selectedVariant;
  final Function(VariantType) onVariantSelected;

  @override
  State<VariantSelector> createState() => _VariantSelectorState();
}

class _VariantSelectorState extends State<VariantSelector> {
  VariantType? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.selectedVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.view_carousel,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select Game Variant',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Variant cards
          ...VariantType.values.map((variant) {
            final isSelected = _selectedVariant == variant;
            final isImplemented = variant == VariantType.minnesotaWhist ||
                                  variant == VariantType.classicWhist;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VariantCard(
                variant: variant,
                isSelected: isSelected,
                isImplemented: isImplemented,
                onTap: isImplemented
                    ? () {
                        setState(() {
                          _selectedVariant = variant;
                        });
                        widget.onVariantSelected(variant);
                      }
                    : null,
              ),
            );
          }),

          const SizedBox(height: 8),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'More variants coming soon!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.variant,
    required this.isSelected,
    required this.isImplemented,
    this.onTap,
  });

  final VariantType variant;
  final bool isSelected;
  final bool isImplemented;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : isImplemented
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : isImplemented
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.1),
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: colorScheme.onPrimary,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Variant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          variant.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isImplemented
                                ? (isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!isImplemented) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      variant.shortDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isImplemented
                            ? (isSelected
                                ? colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant)
                            : colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (isImplemented) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
