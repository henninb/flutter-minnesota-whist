import 'package:flutter/material.dart';
import '../../../game/variants/variant_type.dart';
import '../variant_selector.dart';

/// Full-screen welcome overlay shown on app launch.
///
/// Displays the game title, icon, welcome message, variant selector,
/// and "Start New Game" button over a semi-transparent background.
/// The overlay fades in on appearance and fades out when the user starts a new game.
class WelcomeOverlay extends StatelessWidget {
  const WelcomeOverlay({
    super.key,
    required this.onStartGame,
    this.selectedVariant,
    this.onVariantSelected,
  });

  final VoidCallback onStartGame;
  final VariantType? selectedVariant;
  final Function(VariantType)? onVariantSelected;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface.withAlpha(242),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title
                Text(
                  'Whist',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 48,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Classic Partnership Card Games',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),

                // App icon
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).colorScheme.primary.withAlpha(51),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/minnesota_whist_icon.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback icon if asset not found
                        return Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.style,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome card
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Welcome!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose your game variant and start playing!',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Variant selector
                if (selectedVariant != null && onVariantSelected != null) ...[
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: VariantSelector(
                      selectedVariant: selectedVariant!,
                      onVariantSelected: onVariantSelected!,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Start button (below variant selector)
                  FilledButton.icon(
                    onPressed: onStartGame,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start New Game'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
