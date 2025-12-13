import '../logic/bidding_engine.dart';
import '../logic/minnesota_whist_bidding_engine.dart' as legacy;
import '../models/game_models.dart';
import '../models/card.dart';

/// Adapter that wraps the legacy MinnesotaWhistBiddingEngine to conform to
/// the new abstract BiddingEngine interface
class MinnesotaWhistBiddingEngineAdapter extends BiddingEngine {
  MinnesotaWhistBiddingEngineAdapter({required super.dealer})
      : _legacy = legacy.MinnesotaWhistBiddingEngine(dealer: dealer);

  final legacy.MinnesotaWhistBiddingEngine _legacy;

  @override
  bool isComplete(List<BidEntry> bids) {
    return _legacy.isComplete(bids);
  }

  @override
  AuctionResult determineWinner(List<BidEntry> bids) {
    final legacyResult = _legacy.determineWinner(bids);

    // Convert legacy AuctionResult to new AuctionResult
    return _convertAuctionResult(legacyResult);
  }

  @override
  Position? getNextBidder(List<BidEntry> bids) {
    return _legacy.getNextBidder(bids);
  }

  @override
  BidValidation validateBid({
    required dynamic bid,
    required Position bidder,
    required List<BidEntry> currentBids,
  }) {
    // In Minnesota Whist, the bid is a PlayingCard
    if (bid is! PlayingCard) {
      return BidValidation.invalid('Bid must be a PlayingCard');
    }

    final legacyValidation = _legacy.validateBidCard(
      card: bid,
      bidder: bidder,
      currentBids: currentBids,
    );

    // Convert legacy BidValidation to new BidValidation
    if (legacyValidation.isValid) {
      return BidValidation.valid();
    } else {
      return BidValidation.invalid(
        legacyValidation.errorMessage ?? 'Invalid bid',
      );
    }
  }

  /// Convert legacy AuctionResult to new AuctionResult
  AuctionResult _convertAuctionResult(legacy.AuctionResult legacyResult) {
    switch (legacyResult.status) {
      case legacy.AuctionStatus.incomplete:
        return AuctionResult.incomplete(message: legacyResult.message);

      case legacy.AuctionStatus.won:
        return AuctionResult.winner(
          winningBid: legacyResult.winningBid!,
          handType: legacyResult.handType,
          message: legacyResult.message,
          additionalData: {
            'revealedBids': legacyResult.revealedBids,
            'allBidLow': legacyResult.allBidLow,
          },
        );
    }
  }

  /// Helper to create a bid from a card (Minnesota Whist specific)
  Bid createBidFromCard(PlayingCard card, Position bidder) {
    return _legacy.createBidFromCard(card, bidder);
  }

  /// Get the revealing order for Minnesota Whist
  List<Position> getRevealingOrder() {
    return _legacy.getRevealingOrder();
  }
}
