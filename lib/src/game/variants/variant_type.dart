import 'game_variant.dart';

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
  /// NOTE: This will be implemented once we create the variant classes
  /// For now, it returns a stub implementation
  GameVariant createVariant() {
    // TODO: Implement variant classes
    // This is a temporary stub to allow compilation
    throw UnimplementedError(
      'Variant implementations not yet created. '
      'This will be implemented in the next phase.',
    );

    // Future implementation will look like:
    // switch (this) {
    //   case VariantType.minnesotaWhist:
    //     return MinnesotaWhistVariant();
    //   case VariantType.classicWhist:
    //     return ClassicWhistVariant();
    //   case VariantType.bidWhist:
    //     return BidWhistVariant();
    //   case VariantType.ohHell:
    //     return OhHellVariant();
    //   case VariantType.widowWhist:
    //     return WidowWhistVariant();
    // }
  }

  /// Get variant from name (for serialization)
  static VariantType fromName(String name) {
    return VariantType.values.firstWhere(
      (v) => v.name == name,
      orElse: () => VariantType.minnesotaWhist,
    );
  }
}
