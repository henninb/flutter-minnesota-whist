import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/game/logic/bidding_engine.dart';
import 'package:minnesota_whist/src/game/models/game_models.dart';
import 'package:minnesota_whist/src/game/models/card.dart';

/// Mock bidding engine for testing the abstract base class
class MockBiddingEngine extends BiddingEngine {
  MockBiddingEngine({required super.dealer});

  final List<BidEntry> _bids = [];

  @override
  bool isComplete(List<BidEntry> bids) {
    // Simple mock: complete when all 4 players have bid
    return bids.length >= 4;
  }

  @override
  AuctionResult determineWinner(List<BidEntry> bids) {
    if (!isComplete(bids)) {
      return AuctionResult.incomplete(message: 'Waiting for more bids');
    }

    // Simple mock: first bidder wins
    final firstBid = bids.first.bid;
    return AuctionResult.winner(
      winningBid: firstBid,
      handType: BidType.high,
      message: 'First bidder wins',
    );
  }

  @override
  Position? getNextBidder(List<BidEntry> bids) {
    if (isComplete(bids)) return null;

    // Simple mock: bid in position order
    final positions = [Position.south, Position.west, Position.north, Position.east];
    return positions[bids.length];
  }

  @override
  BidValidation validateBid({
    required dynamic bid,
    required Position bidder,
    required List<BidEntry> currentBids,
  }) {
    // Simple mock: any bid is valid if player hasn't bid yet
    final alreadyBid = currentBids.any((entry) => entry.bidder == bidder);
    if (alreadyBid) {
      return BidValidation.invalid('Player has already bid');
    }
    return BidValidation.valid();
  }
}

void main() {
  group('BiddingEngine', () {
    late MockBiddingEngine biddingEngine;

    setUp(() {
      biddingEngine = MockBiddingEngine(dealer: Position.west);
    });

    test('should have dealer property', () {
      expect(biddingEngine.dealer, equals(Position.west));
    });

    group('BidValidation', () {
      test('valid() creates a valid validation', () {
        final validation = BidValidation.valid();
        expect(validation.isValid, isTrue);
        expect(validation.errorMessage, isNull);
      });

      test('invalid() creates an invalid validation with message', () {
        final validation = BidValidation.invalid('Test error');
        expect(validation.isValid, isFalse);
        expect(validation.errorMessage, equals('Test error'));
      });
    });

    group('AuctionResult', () {
      test('incomplete() creates incomplete result', () {
        final result = AuctionResult.incomplete(message: 'Waiting');
        expect(result.status, equals(AuctionStatus.incomplete));
        expect(result.winningBid, isNull);
        expect(result.winner, isNull);
        expect(result.winningTeam, isNull);
        expect(result.message, equals('Waiting'));
      });

      test('winner() creates won result with winner data', () {
        final bid = Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs));
        final result = AuctionResult.winner(
          winningBid: bid,
          handType: BidType.high,
          message: 'South wins',
        );

        expect(result.status, equals(AuctionStatus.won));
        expect(result.winningBid, equals(bid));
        expect(result.winner, equals(Position.south));
        expect(result.winningTeam, equals(Team.northSouth));
        expect(result.handType, equals(BidType.high));
        expect(result.message, equals('South wins'));
      });

      test('winner() supports additional data', () {
        final bid = Bid(bidType: BidType.low, bidder: Position.east, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs));
        final additionalData = {'tricks': 7, 'trump': 'spades'};
        final result = AuctionResult.winner(
          winningBid: bid,
          message: 'East wins',
          additionalData: additionalData,
        );

        expect(result.additionalData, equals(additionalData));
        expect(result.additionalData?['tricks'], equals(7));
      });

      test('allPass() creates all-pass result', () {
        final result = AuctionResult.allPass(message: 'All players passed');
        expect(result.status, equals(AuctionStatus.allPass));
        expect(result.winningBid, isNull);
        expect(result.message, equals('All players passed'));
      });
    });

    group('MockBiddingEngine implementation', () {
      test('isComplete returns false for empty bids', () {
        expect(biddingEngine.isComplete([]), isFalse);
      });

      test('isComplete returns false for incomplete bidding', () {
        final bids = [
          BidEntry(
            bidder: Position.south,
            bid: Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        ];
        expect(biddingEngine.isComplete(bids), isFalse);
      });

      test('isComplete returns true when all 4 players have bid', () {
        final bids = [
          BidEntry(
            bidder: Position.south,
            bid: Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
          BidEntry(
            bidder: Position.west,
            bid: Bid(bidType: BidType.low, bidder: Position.west, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
          BidEntry(
            bidder: Position.north,
            bid: Bid(bidType: BidType.high, bidder: Position.north, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
          BidEntry(
            bidder: Position.east,
            bid: Bid(bidType: BidType.low, bidder: Position.east, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        ];
        expect(biddingEngine.isComplete(bids), isTrue);
      });

      test('getNextBidder returns first position when no bids', () {
        expect(biddingEngine.getNextBidder([]), equals(Position.south));
      });

      test('getNextBidder returns next position in sequence', () {
        final bids = [
          BidEntry(
            bidder: Position.south,
            bid: Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        ];
        expect(biddingEngine.getNextBidder(bids), equals(Position.west));
      });

      test('getNextBidder returns null when bidding complete', () {
        final bids = List.generate(
          4,
          (i) => BidEntry(
            bidder: Position.values[i],
            bid: Bid(bidType: BidType.high, bidder: Position.values[i], bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        );
        expect(biddingEngine.getNextBidder(bids), isNull);
      });

      test('validateBid allows first bid from player', () {
        final validation = biddingEngine.validateBid(
          bid: Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          bidder: Position.south,
          currentBids: [],
        );
        expect(validation.isValid, isTrue);
      });

      test('validateBid rejects duplicate bid from same player', () {
        final bids = [
          BidEntry(
            bidder: Position.south,
            bid: Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        ];

        final validation = biddingEngine.validateBid(
          bid: Bid(bidType: BidType.low, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          bidder: Position.south,
          currentBids: bids,
        );

        expect(validation.isValid, isFalse);
        expect(validation.errorMessage, contains('already bid'));
      });

      test('determineWinner returns incomplete for incomplete bidding', () {
        final bids = [
          BidEntry(
            bidder: Position.south,
            bid: Bid(bidType: BidType.high, bidder: Position.south, bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        ];

        final result = biddingEngine.determineWinner(bids);
        expect(result.status, equals(AuctionStatus.incomplete));
      });

      test('determineWinner returns winner when complete', () {
        final bids = List.generate(
          4,
          (i) => BidEntry(
            bidder: Position.values[i],
            bid: Bid(bidType: BidType.high, bidder: Position.values[i], bidCard: PlayingCard(rank: Rank.two, suit: Suit.clubs)),
          ),
        );

        final result = biddingEngine.determineWinner(bids);
        expect(result.status, equals(AuctionStatus.won));
        expect(result.winner, equals(Position.north)); // First bidder (Position.values[0])
      });
    });

    group('AuctionStatus enum', () {
      test('has expected values', () {
        expect(AuctionStatus.values.length, equals(3));
        expect(AuctionStatus.values, contains(AuctionStatus.incomplete));
        expect(AuctionStatus.values, contains(AuctionStatus.won));
        expect(AuctionStatus.values, contains(AuctionStatus.allPass));
      });
    });
  });
}
