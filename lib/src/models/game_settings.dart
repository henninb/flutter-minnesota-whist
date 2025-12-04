import 'theme_models.dart';
import '../game/variants/variant_type.dart';

/// Card selection method
enum CardSelectionMode {
  tap, // Single tap to select (default)
  longPress, // Long press to select
  drag, // Drag to discard area
}

/// Counting mode for game scoring
enum CountingMode {
  automatic, // App calculates points automatically (default)
  manual, // Player inputs points manually (deferred - not yet implemented)
}

/// Game settings data class
class GameSettings {
  final CardSelectionMode cardSelectionMode;
  final CountingMode countingMode;
  final ThemeType? selectedTheme; // null means use date-based theme
  final VariantType selectedVariant; // Whist variant to play

  const GameSettings({
    this.cardSelectionMode = CardSelectionMode.tap,
    this.countingMode = CountingMode.automatic,
    this.selectedTheme, // null by default for date-based theme
    this.selectedVariant = VariantType.minnesotaWhist, // Default variant
  });

  /// Copy with method for immutable updates
  GameSettings copyWith({
    CardSelectionMode? cardSelectionMode,
    CountingMode? countingMode,
    ThemeType? selectedTheme,
    VariantType? selectedVariant,
    bool clearSelectedTheme = false,
  }) {
    return GameSettings(
      cardSelectionMode: cardSelectionMode ?? this.cardSelectionMode,
      countingMode: countingMode ?? this.countingMode,
      selectedTheme: clearSelectedTheme ? null : (selectedTheme ?? this.selectedTheme),
      selectedVariant: selectedVariant ?? this.selectedVariant,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'cardSelectionMode': cardSelectionMode.name,
      'countingMode': countingMode.name,
      'selectedTheme': selectedTheme?.name,
      'selectedVariant': selectedVariant.name,
    };
  }

  /// Create from JSON
  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      cardSelectionMode: CardSelectionMode.values.firstWhere(
        (e) => e.name == json['cardSelectionMode'],
        orElse: () => CardSelectionMode.tap,
      ),
      countingMode: CountingMode.values.firstWhere(
        (e) => e.name == json['countingMode'],
        orElse: () => CountingMode.automatic,
      ),
      selectedTheme: json['selectedTheme'] != null
          ? ThemeType.values.firstWhere(
              (e) => e.name == json['selectedTheme'],
              orElse: () => ThemeType.spring,
            )
          : null,
      selectedVariant: json['selectedVariant'] != null
          ? VariantType.values.firstWhere(
              (e) => e.name == json['selectedVariant'],
              orElse: () => VariantType.minnesotaWhist,
            )
          : VariantType.minnesotaWhist,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSettings &&
        other.cardSelectionMode == cardSelectionMode &&
        other.countingMode == countingMode &&
        other.selectedTheme == selectedTheme &&
        other.selectedVariant == selectedVariant;
  }

  @override
  int get hashCode => Object.hash(cardSelectionMode, countingMode, selectedTheme, selectedVariant);
}
