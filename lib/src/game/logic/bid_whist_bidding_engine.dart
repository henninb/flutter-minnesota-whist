import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import '../models/card.dart';
import 'bidding_engine.dart';

/// Bidding engine for Bid Whist
///
/// Bid Whist uses sequential competitive bidding:
/// - Players bid clockwise starting from dealer's left
/// - Bids specify: number of books (3-7) + Uptown/Downtown + optional No Trump
/// - Each bid must be higher than the previous
/// - Players can pass (but may re-enter)
/// - Bidding continues until 3 consecutive passes
///
/// Implementation note: We encode Bid Whist bids into the standard Bid model:
/// - Pass: BidType.low with rank = Rank.two
/// - Books 3-7: BidType.high with rank = 3-7 (using ranks three through seven)
/// - Uptown/Downtown stored in suit (spades=uptown, hearts=downtown)
/// - No Trump: stored in additional data
class BidWhistBiddingEngine extends BiddingEngine {
  const BidWhistBiddingEngine({required super.dealer});

  /// Get the bidding order (clockwise from dealer's left)
  List<Position> getBiddingOrder() {
    final order = <Position>[];
    var current = dealer.next; // Start with player to dealer's left
    for (int i = 0; i < 4; i++) {
      order.add(current);
      current = current.next;
    }
    return order;
  }

  /// Check if a bid represents a pass
  bool _isPass(Bid bid) {
    return bid.bidType == BidType.low && bid.bidCard.rank == Rank.two;
  }

  /// Get the book level from a bid (3-7)
  int _getBooks(Bid bid) {
    if (_isPass(bid)) return 0;
    // Books encoded as rank value: three=3, four=4, five=5, six=6, seven=7
    return bid.bidCard.rank.index + 2; // Ranks start at 0, we want 3-7
  }

  @override
  bool isComplete(List<BidEntry> bids) {
    if (bids.isEmpty) return false;

    // Count consecutive passes from the end
    int consecutivePasses = 0;
    for (int i = bids.length - 1; i >= 0; i--) {
      final bid = bids[i].bid;
      if (_isPass(bid)) {
        consecutivePasses++;
      } else {
        break;
      }
    }

    // Complete if we have 3 consecutive passes and at least one real bid
    if (consecutivePasses >= 3) {
      // Check if there was at least one non-pass bid
      final hasRealBid = bids.any((entry) => !_isPass(entry.bid));
      return hasRealBid;
    }

    return false;
  }

  @override
  Position? getNextBidder(List<BidEntry> bids) {
    if (isComplete(bids)) return null;

    if (bids.isEmpty) {
      // First bidder is to dealer's left
      return dealer.next;
    }

    // Next bidder is clockwise from last bidder
    final lastBidder = bids.last.bidder;
    return lastBidder.next;
  }

  @override
  BidValidation validateBid({
    required dynamic bid,
    required Position bidder,
    required List<BidEntry> currentBids,
  }) {
    if (bid is! Bid) {
      return BidValidation.invalid('Invalid bid type');
    }

    // Pass is always valid
    if (_isPass(bid)) {
      return BidValidation.valid();
    }

    // Find the highest previous bid
    Bid? highestBid;
    int highestBooks = 0;
    for (final entry in currentBids) {
      final entryBid = entry.bid;
      if (!_isPass(entryBid)) {
        final books = _getBooks(entryBid);
        if (books > highestBooks) {
          highestBooks = books;
          highestBid = entryBid;
        }
      }
    }

    // If there's a previous bid, new bid must be higher
    final newBooks = _getBooks(bid);
    if (highestBid != null && newBooks <= highestBooks) {
      return BidValidation.invalid(
        'Bid must be higher than $highestBooks books',
      );
    }

    // Validate book range (3-7)
    if (newBooks < 3 || newBooks > 7) {
      return BidValidation.invalid('Bid must be between 3 and 7 books');
    }

    return BidValidation.valid();
  }

  @override
  AuctionResult determineWinner(List<BidEntry> bids) {
    if (kDebugMode) {
      debugPrint('\n[BID WHIST BIDDING] Determining auction winner');
      debugPrint('  Total bids: ${bids.length}');
    }

    if (!isComplete(bids)) {
      return AuctionResult.incomplete(message: 'Bidding in progress');
    }

    // Find the highest bid
    Bid? highestBid;
    Position? highestBidder;
    int highestBooks = 0;

    for (final entry in bids) {
      final bid = entry.bid;
      if (!_isPass(bid)) {
        final books = _getBooks(bid);
        if (books > highestBooks) {
          highestBooks = books;
          highestBid = bid;
          highestBidder = entry.bidder;
        }
      }
    }

    // Check if all players passed
    if (highestBid == null || highestBidder == null) {
      if (kDebugMode) {
        debugPrint('  Result: ALL PASS - redeal');
      }
      return AuctionResult.allPass(message: 'All players passed. Redeal.');
    }

    if (kDebugMode) {
      debugPrint('  Winner: ${highestBidder.name}');
      debugPrint('  Winning bid: $highestBooks books');
    }

    final mode = highestBid.bidCard.suit == Suit.spades ? 'Uptown' : 'Downtown';
    final message = '${_positionName(highestBidder)} wins with '
        '$highestBooks books $mode';

    return AuctionResult.winner(
      winningBid: highestBid,
      handType: BidType.high,
      message: message,
      additionalData: {
        'books': highestBooks,
        'mode': mode,
        'isUptown': highestBid.bidCard.suit == Suit.spades,
      },
    );
  }

  String _positionName(Position position) {
    switch (position) {
      case Position.north:
        return 'North';
      case Position.south:
        return 'South';
      case Position.east:
        return 'East';
      case Position.west:
        return 'West';
    }
  }

  /// Create a pass bid
  static Bid createPassBid(Position bidder) {
    return Bid(
      bidType: BidType.low,
      bidder: bidder,
      bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs),
    );
  }

  /// Create a book bid
  /// @param books Number of books (3-7)
  /// @param isUptown true for Uptown (Ace high), false for Downtown (2 high)
  static Bid createBookBid(Position bidder, int books, {bool isUptown = true}) {
    assert(books >= 3 && books <= 7, 'Books must be between 3 and 7');

    // Encode books as rank: 3->three, 4->four, 5->five, 6->six, 7->seven
    final rank = Rank.values[books - 2]; // Adjust for rank enum starting at 0

    return Bid(
      bidType: BidType.high,
      bidder: bidder,
      bidCard: PlayingCard(
        rank: rank,
        suit: isUptown ? Suit.spades : Suit.hearts,
      ),
    );
  }
}
