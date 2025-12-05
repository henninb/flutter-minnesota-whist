import 'game_variant.dart';
import 'minnesota_whist_variant.dart';
import 'classic_whist_variant.dart';

/// Enumeration of all supported whist variants
enum VariantType {
  minnesotaWhist,
  classicWhist,
  bidWhist,
  ohHell,
  widowWhist,
}

extension VariantTypeExtension on VariantType {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case VariantType.minnesotaWhist:
        return 'Minnesota Whist';
      case VariantType.classicWhist:
        return 'Classic Whist';
      case VariantType.bidWhist:
        return 'Bid Whist';
      case VariantType.ohHell:
        return 'Oh Hell';
      case VariantType.widowWhist:
        return 'Widow Whist';
    }
  }

  /// Short description for variant selector
  String get shortDescription {
    switch (this) {
      case VariantType.minnesotaWhist:
        return 'Simultaneous bidding with black/red cards. No trump.';
      case VariantType.classicWhist:
        return 'Traditional whist with fixed trump and simple scoring.';
      case VariantType.bidWhist:
        return 'Sequential bidding with kitty, trump declaration.';
      case VariantType.ohHell:
        return 'Bid exact number of tricks. Precision scoring.';
      case VariantType.widowWhist:
        return 'Bid for widow rights. Exchange and play.';
    }
  }

  /// Factory method to create variant instance
  GameVariant createVariant() {
    switch (this) {
      case VariantType.minnesotaWhist:
        return const MinnesotaWhistVariant();
      case VariantType.classicWhist:
        return const ClassicWhistVariant();
      case VariantType.bidWhist:
        throw UnimplementedError('Bid Whist variant not yet implemented');
      case VariantType.ohHell:
        throw UnimplementedError('Oh Hell variant not yet implemented');
      case VariantType.widowWhist:
        throw UnimplementedError('Widow Whist variant not yet implemented');
    }
  }

  /// Get variant from name (for serialization)
  static VariantType fromName(String name) {
    return VariantType.values.firstWhere(
      (v) => v.name == name,
      orElse: () => VariantType.minnesotaWhist,
    );
  }
}
