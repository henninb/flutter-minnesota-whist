import 'card.dart';

// Bid type for Minnesota Whist (High or Low)
enum BidType { high, low }

// Player positions around the table (South is human player)
enum Position { north, south, east, west }

// Teams in Minnesota Whist (North-South vs East-West)
enum Team { northSouth, eastWest }

// Extension to get team from position
extension PositionExt on Position {
  Team get team {
    switch (this) {
      case Position.north:
      case Position.south:
        return Team.northSouth;
      case Position.east:
      case Position.west:
        return Team.eastWest;
    }
  }

  Position get partner {
    switch (this) {
      case Position.north:
        return Position.south;
      case Position.south:
        return Position.north;
      case Position.east:
        return Position.west;
      case Position.west:
        return Position.east;
    }
  }

  // Get next player clockwise
  Position get next {
    switch (this) {
      case Position.north:
        return Position.east;
      case Position.east:
        return Position.south;
      case Position.south:
        return Position.west;
      case Position.west:
        return Position.north;
    }
  }
}

// A bid in Minnesota Whist (player indicates high or low with a card)
class Bid {
  const Bid({
    required this.bidType,
    required this.bidder,
    required this.bidCard,
  });

  final BidType bidType; // high or low
  final Position bidder;
  final PlayingCard bidCard; // The card used to indicate the bid (black=high, red=low)

  // Check if this is a high bid (grand)
  bool get isHigh => bidType == BidType.high;

  // Check if this is a low bid (nula)
  bool get isLow => bidType == BidType.low;

  @override
  String toString() => '${bidType == BidType.high ? "High" : "Low"} by ${bidder.name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bid &&
        other.bidType == bidType &&
        other.bidder == bidder &&
        other.bidCard == bidCard;
  }

  @override
  int get hashCode => bidType.hashCode ^ bidder.hashCode ^ bidCard.hashCode;
}

// A card played by a player in a trick
class CardPlay {
  const CardPlay({
    required this.card,
    required this.player,
  });

  final PlayingCard card;
  final Position player;

  @override
  String toString() => '$card by ${player.name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardPlay && other.card == card && other.player == player;
  }

  @override
  int get hashCode => card.hashCode ^ player.hashCode;
}

// A trick (4 cards played)
class Trick {
  const Trick({
    required this.plays,
    required this.leader,
    this.trumpSuit,
  });

  final List<CardPlay> plays; // 0-4 cards
  final Position leader;
  final Suit? trumpSuit; // null for no-trump

  bool get isComplete => plays.length == 4;
  bool get isEmpty => plays.isEmpty;

  // Get the suit that was led
  Suit? get ledSuit {
    if (plays.isEmpty) return null;
    return plays.first.card.suit;
  }

  // Get winner of trick (must be complete)
  // Note: Winner determination logic will be in TrickEngine
  Position? get winner => null; // Implemented in TrickEngine

  Trick copyWith({
    List<CardPlay>? plays,
    Position? leader,
    Suit? trumpSuit,
  }) {
    return Trick(
      plays: plays ?? this.plays,
      leader: leader ?? this.leader,
      trumpSuit: trumpSuit ?? this.trumpSuit,
    );
  }

  Trick addPlay(CardPlay play) {
    return copyWith(plays: [...plays, play]);
  }

  @override
  String toString() => 'Trick: ${plays.length}/4 cards, led by ${leader.name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Trick) return false;
    if (plays.length != other.plays.length) return false;
    for (int i = 0; i < plays.length; i++) {
      if (plays[i] != other.plays[i]) return false;
    }
    return leader == other.leader && trumpSuit == other.trumpSuit;
  }

  @override
  int get hashCode => plays.hashCode ^ leader.hashCode ^ trumpSuit.hashCode;
}

// An entry in the bidding history for Minnesota Whist
// Each player places a card face down (black=high, red=low)
class BidEntry {
  const BidEntry({
    required this.bidder,
    required this.bid,
  });

  final Position bidder;
  final Bid bid;

  @override
  String toString() => '${bidder.name}: $bid';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BidEntry &&
        other.bidder == bidder &&
        other.bid == bid;
  }

  @override
  int get hashCode => bidder.hashCode ^ bid.hashCode;
}
