import '../models/game_models.dart';

/// Abstract base class for variant-specific bidding engines
abstract class BiddingEngine {
  const BiddingEngine({required this.dealer});

  /// The dealer for this hand
  final Position dealer;

  /// Check if bidding is complete
  bool isComplete(List<BidEntry> bids);

  /// Determine the auction result/winner
  AuctionResult determineWinner(List<BidEntry> bids);

  /// Get the next player who should bid
  /// Returns null if bidding is complete
  Position? getNextBidder(List<BidEntry> bids);

  /// Validate a bid
  /// Subclasses override to implement variant-specific validation
  BidValidation validateBid({
    required dynamic bid,
    required Position bidder,
    required List<BidEntry> currentBids,
  });
}

/// Result of bid validation
class BidValidation {
  const BidValidation._({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  factory BidValidation.valid() => const BidValidation._(isValid: true);

  factory BidValidation.invalid(String message) =>
      BidValidation._(isValid: false, errorMessage: message);
}

/// Base auction result class
/// Can be extended by variants for additional data
class AuctionResult {
  const AuctionResult._({
    required this.status,
    this.winningBid,
    this.handType,
    required this.message,
    this.additionalData,
  });

  final AuctionStatus status;
  final Bid? winningBid;
  final BidType? handType;
  final String message;
  final Map<String, dynamic>? additionalData;

  Position? get winner => winningBid?.bidder;
  Team? get winningTeam => winner?.team;

  factory AuctionResult.winner({
    required Bid winningBid,
    BidType? handType,
    required String message,
    Map<String, dynamic>? additionalData,
  }) =>
      AuctionResult._(
        status: AuctionStatus.won,
        winningBid: winningBid,
        handType: handType,
        message: message,
        additionalData: additionalData,
      );

  factory AuctionResult.incomplete({required String message}) =>
      AuctionResult._(
        status: AuctionStatus.incomplete,
        message: message,
      );

  factory AuctionResult.allPass({required String message}) => AuctionResult._(
        status: AuctionStatus.allPass,
        message: message,
      );
}

/// Auction status enum
enum AuctionStatus {
  incomplete, // Still waiting for bids
  won, // Auction complete with a winner
  allPass, // All players passed (redeal in some variants)
}
