import 'dart:math';

enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

class PlayingCard {
  const PlayingCard({required this.rank, required this.suit});

  final Rank rank;
  final Suit suit;

  // Relative card value (useful for AI)
  int get value {
    switch (rank) {
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
      case Rank.ace:
        return 11;
    }
  }

  String get label {
    return '${_rankLabel(rank)}${_suitLabel(suit)}';
  }

  // Get rank symbol only (for UI display)
  String get rankSymbol => _rankLabel(rank);

  // Get suit symbol only (for UI display)
  String get suitSymbol => _suitLabel(suit);

  // Check if card is red (hearts or diamonds)
  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  // Helper method for card identification
  bool get isJack => rank == Rank.jack;

  // Get the same-color suit (for left bower determination)
  // Hearts ↔ Diamonds (both red), Spades ↔ Clubs (both black)
  Suit getSameColorSuit() {
    switch (suit) {
      case Suit.hearts:
        return Suit.diamonds;
      case Suit.diamonds:
        return Suit.hearts;
      case Suit.spades:
        return Suit.clubs;
      case Suit.clubs:
        return Suit.spades;
    }
  }

  String encode() => '${rank.index}|${suit.index}';

  static PlayingCard decode(String raw) {
    final parts = raw.split('|');

    // Validate encoded string format
    if (parts.length != 2) {
      throw FormatException(
        'Invalid card encoding: expected "rank|suit" format, got "$raw"',
      );
    }

    final rankIndex = int.tryParse(parts[0]);
    final suitIndex = int.tryParse(parts[1]);

    // Validate that both parts are valid integers
    if (rankIndex == null || suitIndex == null) {
      throw FormatException(
        'Invalid card encoding: rank and suit must be integers, got "$raw"',
      );
    }

    // Validate indices are within valid ranges
    if (rankIndex < 0 || rankIndex >= Rank.values.length) {
      throw RangeError(
        'Invalid rank index: $rankIndex (must be 0-${Rank.values.length - 1})',
      );
    }

    if (suitIndex < 0 || suitIndex >= Suit.values.length) {
      throw RangeError(
        'Invalid suit index: $suitIndex (must be 0-${Suit.values.length - 1})',
      );
    }

    return PlayingCard(
      rank: Rank.values[rankIndex],
      suit: Suit.values[suitIndex],
    );
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayingCard && other.rank == rank && other.suit == suit;
  }

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;
}

String _rankLabel(Rank rank) {
  switch (rank) {
    case Rank.two:
      return '2';
    case Rank.three:
      return '3';
    case Rank.four:
      return '4';
    case Rank.five:
      return '5';
    case Rank.six:
      return '6';
    case Rank.seven:
      return '7';
    case Rank.eight:
      return '8';
    case Rank.nine:
      return '9';
    case Rank.ten:
      return '10';
    case Rank.jack:
      return 'J';
    case Rank.queen:
      return 'Q';
    case Rank.king:
      return 'K';
    case Rank.ace:
      return 'A';
  }
}

String _suitLabel(Suit suit) {
  switch (suit) {
    case Suit.spades:
      return '♠';
    case Suit.hearts:
      return '♥';
    case Suit.diamonds:
      return '♦';
    case Suit.clubs:
      return '♣';
  }
}

// Creates a standard 52-card deck for Minnesota Whist (2-Ace in all suits)
List<PlayingCard> createDeck({Random? random}) {
  final deck = <PlayingCard>[];

  // Add 2-Ace for all suits (13 cards × 4 suits = 52 cards)
  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      deck.add(PlayingCard(rank: rank, suit: suit));
    }
  }

  if (random != null) {
    deck.shuffle(random);
  } else {
    deck.shuffle();
  }
  return deck;
}

/// Sorts a hand of cards by suit and rank for display
///
/// Order: Spades, Hearts, Diamonds, Clubs
/// Within each suit: Ace (high) down to 2 (low)
///
/// Minnesota Whist typically has no trumps, so we use simple suit sorting.
/// If a trump variant is played, trumpSuit can be specified for trump-aware sorting.
List<PlayingCard> sortHandBySuit(List<PlayingCard> hand, {Suit? trumpSuit}) {
  if (trumpSuit == null) {
    // Standard: simple suit sorting
    return _sortByNaturalSuit(hand);
  } else {
    // Trump variant: trump-aware sorting
    return _sortWithTrump(hand, trumpSuit);
  }
}

/// Sort cards by natural suit (no trump consideration)
List<PlayingCard> _sortByNaturalSuit(List<PlayingCard> hand) {
  final sorted = List<PlayingCard>.from(hand);

  sorted.sort((a, b) {
    // Sort by suit (Spades, Hearts, Diamonds, Clubs)
    final suitOrder = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final suitCompare =
        suitOrder.indexOf(a.suit).compareTo(suitOrder.indexOf(b.suit));
    if (suitCompare != 0) return suitCompare;

    // Within same suit, sort by rank (Ace high to 2 low)
    final rankOrder = [
      Rank.ace,
      Rank.king,
      Rank.queen,
      Rank.jack,
      Rank.ten,
      Rank.nine,
      Rank.eight,
      Rank.seven,
      Rank.six,
      Rank.five,
      Rank.four,
      Rank.three,
      Rank.two,
    ];
    return rankOrder.indexOf(a.rank).compareTo(rankOrder.indexOf(b.rank));
  });

  return sorted;
}

/// Sort cards with trump consideration (left bower appears with trump)
List<PlayingCard> _sortWithTrump(List<PlayingCard> hand, Suit trumpSuit) {
  final sorted = List<PlayingCard>.from(hand);

  // Helper: Get same-color suit
  Suit getOppositeColorSuit(Suit suit) {
    switch (suit) {
      case Suit.hearts:
        return Suit.diamonds;
      case Suit.diamonds:
        return Suit.hearts;
      case Suit.spades:
        return Suit.clubs;
      case Suit.clubs:
        return Suit.spades;
    }
  }

  // Helper: Check if card is left bower
  bool isLeftBower(PlayingCard card) {
    return card.rank == Rank.jack &&
        card.suit == getOppositeColorSuit(trumpSuit);
  }

  // Helper: Check if card is right bower
  bool isRightBower(PlayingCard card) {
    return card.rank == Rank.jack && card.suit == trumpSuit;
  }

  // Helper: Check if card is trump
  bool isTrump(PlayingCard card) {
    if (card.suit == trumpSuit) return true;
    if (isLeftBower(card)) return true;
    return false;
  }

  // Helper: Get trump rank
  int getTrumpRank(PlayingCard card) {
    if (isRightBower(card)) return 99;
    if (isLeftBower(card)) return 98;
    switch (card.rank) {
      case Rank.ace:
        return 14;
      case Rank.king:
        return 13;
      case Rank.queen:
        return 12;
      case Rank.ten:
        return 11;
      case Rank.nine:
        return 10;
      case Rank.eight:
        return 9;
      case Rank.seven:
        return 8;
      case Rank.six:
        return 7;
      case Rank.five:
        return 6;
      case Rank.four:
        return 5;
      case Rank.three:
        return 4;
      case Rank.two:
        return 3;
      default:
        return 0;
    }
  }

  sorted.sort((a, b) {
    final aTrump = isTrump(a);
    final bTrump = isTrump(b);

    // Trump cards come first
    if (aTrump && !bTrump) return -1;
    if (!aTrump && bTrump) return 1;

    // Both trump: sort by trump rank (high to low)
    if (aTrump && bTrump) {
      return getTrumpRank(b).compareTo(getTrumpRank(a));
    }

    // Both non-trump: sort by suit then rank
    final suitOrder = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
    final suitCompare =
        suitOrder.indexOf(a.suit).compareTo(suitOrder.indexOf(b.suit));
    if (suitCompare != 0) return suitCompare;

    // Within same suit, sort by rank (Ace high to 2 low)
    final rankOrder = [
      Rank.ace,
      Rank.king,
      Rank.queen,
      Rank.jack,
      Rank.ten,
      Rank.nine,
      Rank.eight,
      Rank.seven,
      Rank.six,
      Rank.five,
      Rank.four,
      Rank.three,
      Rank.two,
    ];
    return rankOrder.indexOf(a.rank).compareTo(rankOrder.indexOf(b.rank));
  });

  return sorted;
}
