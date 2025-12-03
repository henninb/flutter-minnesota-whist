import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';

/// Manages the bidding for Minnesota Whist
///
/// Minnesota Whist bidding rules:
/// - All 4 players simultaneously place a card face down
/// - Black card (spades/clubs) = High bid (want to win tricks)
/// - Red card (hearts/diamonds) = Low bid (want to lose tricks)
/// - Players reveal cards in order starting from dealer's left
/// - First black card revealed ends the revealing (others don't reveal)
/// - If all red, it's a "Low" (Nula) hand
/// - If any black, it's a "High" (Grand) hand
class MinnesotaWhistBiddingEngine {
  MinnesotaWhistBiddingEngine({required this.dealer});

  final Position dealer;

  /// Get the revealing order starting from dealer's left
  List<Position> getRevealingOrder() {
    final order = <Position>[];
    var current = dealer.next; // Start with player to dealer's left
    for (int i = 0; i < 4; i++) {
      order.add(current);
      current = current.next;
    }
    return order;
  }

  /// Validate that a card can be used for bidding
  /// Players typically use their lowest card of the chosen color
  BidValidation validateBidCard({
    required PlayingCard card,
    required Position bidder,
    required List<BidEntry> currentBids,
  }) {
    // Check if already bid
    final alreadyBid = currentBids.any((entry) => entry.bidder == bidder);
    if (alreadyBid) {
      return BidValidation.invalid('You have already placed your bid card');
    }

    // Any card is valid for bidding (player chooses their own card)
    return BidValidation.valid();
  }

  /// Create a bid from a card
  /// Black suits (spades, clubs) = High
  /// Red suits (hearts, diamonds) = Low
  Bid createBidFromCard(PlayingCard card, Position bidder) {
    final bidType = _isBlackCard(card) ? BidType.high : BidType.low;
    return Bid(
      bidType: bidType,
      bidder: bidder,
      bidCard: card,
    );
  }

  /// Check if a card is black (spades or clubs)
  bool _isBlackCard(PlayingCard card) {
    return card.suit == Suit.spades || card.suit == Suit.clubs;
  }

  /// Determine auction result after all players have placed bid cards
  ///
  /// Reveals cards in order from dealer's left. Stops revealing when first
  /// black card is found (that player "granded").
  AuctionResult determineWinner(List<BidEntry> bids) {
    if (kDebugMode) {
      debugPrint('\n[BIDDING ENGINE] Determining Minnesota Whist auction winner');
      debugPrint('  Total bids received: ${bids.length}');
    }

    // Must have 4 bids (one per player)
    if (bids.length != 4) {
      final message = 'Waiting for ${4 - bids.length} more bid(s)';
      if (kDebugMode) {
        debugPrint('  Result: INCOMPLETE - $message');
      }
      return AuctionResult.incomplete(message: message);
    }

    // Get revealing order (starting from dealer's left)
    final revealingOrder = getRevealingOrder();

    // Reveal bids in order until we find a black card
    Bid? grandBid;
    final revealedBids = <Position, Bid>{};

    for (final position in revealingOrder) {
      // Find this player's bid
      final bidEntry = bids.firstWhere((entry) => entry.bidder == position);
      final bid = bidEntry.bid;

      revealedBids[position] = bid;

      if (kDebugMode) {
        debugPrint('  Revealing ${position.name}: ${bid.bidType == BidType.high ? "BLACK (High)" : "RED (Low)"}');
      }

      // If black card, this player granded - stop revealing
      if (bid.bidType == BidType.high) {
        grandBid = bid;
        if (kDebugMode) {
          debugPrint('  ${position.name} GRANDED! (showed black card)');
        }
        break;
      }
    }

    // Determine result
    if (grandBid != null) {
      // Someone showed black - HIGH (Grand) hand
      final message = '${grandBid.bidder.name} granded HIGH';
      if (kDebugMode) {
        debugPrint('  Result: HIGH HAND - $message');
      }
      return AuctionResult.winner(
        winningBid: grandBid,
        handType: BidType.high,
        message: message,
        revealedBids: revealedBids,
      );
    } else {
      // All showed red - LOW (Nula) hand
      const message = 'All bid LOW (red cards)';
      if (kDebugMode) {
        debugPrint('  Result: LOW HAND - $message');
      }
      // In all-low, the first player in revealing order is considered the "leader"
      // for determining who leads first
      final firstPlayer = revealingOrder.first;
      final firstBid = revealedBids[firstPlayer]!;
      return AuctionResult.winner(
        winningBid: firstBid,
        handType: BidType.low,
        message: message,
        revealedBids: revealedBids,
        allBidLow: true,
      );
    }
  }

  /// Check if auction is complete (all 4 players have bid)
  bool isComplete(List<BidEntry> bids) {
    return bids.length == 4;
  }

  /// Get next bidder (for simultaneous bidding, all bid at once)
  /// Returns null if all have bid
  Position? getNextBidder(List<BidEntry> bids) {
    if (isComplete(bids)) return null;

    // In Minnesota Whist, bidding is simultaneous, but for UI purposes
    // we can show them in revealing order
    final revealingOrder = getRevealingOrder();
    final alreadyBid = bids.map((e) => e.bidder).toSet();

    for (final position in revealingOrder) {
      if (!alreadyBid.contains(position)) {
        return position;
      }
    }

    return null;
  }
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

/// Result of the Minnesota Whist auction
class AuctionResult {
  const AuctionResult._({
    required this.status,
    this.winningBid,
    required this.handType,
    required this.message,
    this.revealedBids,
    this.allBidLow = false,
  });

  final AuctionStatus status;
  final Bid? winningBid;
  final BidType handType; // Whether it's a HIGH or LOW hand
  final String message;
  final Map<Position, Bid>? revealedBids; // Which bids were revealed before stopping
  final bool allBidLow; // True if all 4 players bid red (special case)

  Position? get winner => winningBid?.bidder;
  Team? get winningTeam => winner?.team;

  factory AuctionResult.winner({
    required Bid winningBid,
    required BidType handType,
    required String message,
    Map<Position, Bid>? revealedBids,
    bool allBidLow = false,
  }) =>
      AuctionResult._(
        status: AuctionStatus.won,
        winningBid: winningBid,
        handType: handType,
        message: message,
        revealedBids: revealedBids,
        allBidLow: allBidLow,
      );

  factory AuctionResult.incomplete({required String message}) =>
      AuctionResult._(
        status: AuctionStatus.incomplete,
        handType: BidType.low, // Default, not used when incomplete
        message: message,
      );
}

enum AuctionStatus {
  incomplete, // Still waiting for bids
  won, // Auction complete (someone granded or all bid low)
}
