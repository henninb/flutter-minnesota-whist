import '../models/card.dart';

/// Handles all trump-related logic for Minnesota Whist
///
/// Standard Minnesota Whist has no trumps - the highest card of the suit led wins.
/// This class supports optional trump variants (e.g., South Dakota Whist where
/// the suit of the first lead becomes trump).
///
/// This includes:
/// - Card comparison in the context of trump suit
/// - Determining if a card is trump
class TrumpRules {
  const TrumpRules({this.trumpSuit});

  final Suit? trumpSuit; // null for standard Minnesota Whist (no trump)

  /// Check if a card is trump
  bool isTrump(PlayingCard card) {
    if (trumpSuit == null) return false; // No trump in standard Minnesota Whist
    return card.suit == trumpSuit; // Trump suit cards only
  }

  /// Get the effective suit of a card (for following suit)
  /// In Minnesota Whist, effective suit is always the card's printed suit
  Suit getEffectiveSuit(PlayingCard card) {
    return card.suit;
  }

  /// Compare two cards in the context of trump
  ///
  /// Returns:
  ///  - Positive number if card1 is higher
  ///  - Negative number if card2 is higher
  ///  - Zero if equal (shouldn't happen in practice)
  int compare(PlayingCard card1, PlayingCard card2) {
    final card1Trump = isTrump(card1);
    final card2Trump = isTrump(card2);

    // Trump always beats non-trump
    if (card1Trump && !card2Trump) return 1;
    if (!card1Trump && card2Trump) return -1;

    // Both trump: compare trump ranks
    if (card1Trump && card2Trump) {
      return _compareTrumpCards(card1, card2);
    }

    // Both non-trump: compare by rank (same suit assumed, caller should check)
    return _compareNonTrumpCards(card1, card2);
  }

  /// Compare two trump cards
  int _compareTrumpCards(PlayingCard card1, PlayingCard card2) {
    final rank1 = _getTrumpRank(card1);
    final rank2 = _getTrumpRank(card2);
    return rank1.compareTo(rank2);
  }

  /// Get trump rank (higher number = higher card)
  /// In Minnesota Whist: A (high) K Q J 10 9 8 7 6 5 4 3 2 (low)
  int _getTrumpRank(PlayingCard card) {
    switch (card.rank) {
      case Rank.ace:
        return 14;
      case Rank.king:
        return 13;
      case Rank.queen:
        return 12;
      case Rank.jack:
        return 11;
      case Rank.ten:
        return 10;
      case Rank.nine:
        return 9;
      case Rank.eight:
        return 8;
      case Rank.seven:
        return 7;
      case Rank.six:
        return 6;
      case Rank.five:
        return 5;
      case Rank.four:
        return 4;
      case Rank.three:
        return 3;
      case Rank.two:
        return 2;
    }
  }

  /// Compare two non-trump cards (assumed to be same suit)
  int _compareNonTrumpCards(PlayingCard card1, PlayingCard card2) {
    final rank1 = _getNonTrumpRank(card1);
    final rank2 = _getNonTrumpRank(card2);
    return rank1.compareTo(rank2);
  }

  /// Get non-trump rank (higher number = higher card)
  /// In Minnesota Whist: A (high) K Q J 10 9 8 7 6 5 4 3 2 (low)
  int _getNonTrumpRank(PlayingCard card) {
    switch (card.rank) {
      case Rank.ace:
        return 14;
      case Rank.king:
        return 13;
      case Rank.queen:
        return 12;
      case Rank.jack:
        return 11;
      case Rank.ten:
        return 10;
      case Rank.nine:
        return 9;
      case Rank.eight:
        return 8;
      case Rank.seven:
        return 7;
      case Rank.six:
        return 6;
      case Rank.five:
        return 5;
      case Rank.four:
        return 4;
      case Rank.three:
        return 3;
      case Rank.two:
        return 2;
    }
  }

  /// Get all trump cards from a list of cards
  List<PlayingCard> getTrumpCards(List<PlayingCard> cards) {
    return cards.where(isTrump).toList();
  }

  /// Get all non-trump cards from a list of cards
  List<PlayingCard> getNonTrumpCards(List<PlayingCard> cards) {
    return cards.where((card) => !isTrump(card)).toList();
  }

  /// Count trump cards in a hand
  int countTrump(List<PlayingCard> cards) {
    return cards.where(isTrump).length;
  }

  /// Get highest card from a list (in context of trump)
  PlayingCard? getHighestCard(List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    return cards.reduce((a, b) => compare(a, b) > 0 ? a : b);
  }

  /// Get lowest card from a list (in context of trump)
  PlayingCard? getLowestCard(List<PlayingCard> cards) {
    if (cards.isEmpty) return null;
    return cards.reduce((a, b) => compare(a, b) < 0 ? a : b);
  }

  @override
  String toString() {
    if (trumpSuit == null) return 'TrumpRules(No Trump)';
    return 'TrumpRules(${_suitLabel(trumpSuit!)})';
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
}
