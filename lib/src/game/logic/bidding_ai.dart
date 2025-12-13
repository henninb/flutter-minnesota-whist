import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';

/// Basic AI for bidding in Minnesota Whist
///
/// Minnesota Whist bidding strategy:
/// - Each player places one card face down simultaneously
/// - Black card (spades/clubs) = High bid (want to win tricks)
/// - Red card (hearts/diamonds) = Low bid (want to lose tricks)
/// - Generally use lowest card of chosen color to preserve hand strength
///
/// AI Strategy:
/// - Evaluate hand strength (high cards, distribution)
/// - Strong hands (7+ likely tricks) → bid black (HIGH)
/// - Weak hands (0-6 likely tricks) → bid red (LOW)
/// - Choose lowest card of selected color to minimize impact on play
class BiddingAI {
  BiddingAI._();

  /// Choose a bid card for Minnesota Whist
  static PlayingCard chooseBidCard({
    required List<PlayingCard> hand,
    required Position position,
  }) {
    // Evaluate hand strength
    final handStrength = _evaluateHandStrength(hand);

    if (kDebugMode) {
      debugPrint(
        '[AI BIDDING] ${position.name}: Estimated tricks = ${handStrength.toStringAsFixed(1)}',
      );
    }

    // Decide high or low based on strength
    // Threshold: 7+ tricks = go high, otherwise go low
    final bidHigh = handStrength >= 7.0;

    // Get cards of the chosen color
    final blackCards = hand
        .where((c) => c.suit == Suit.spades || c.suit == Suit.clubs)
        .toList();
    final redCards = hand
        .where((c) => c.suit == Suit.hearts || c.suit == Suit.diamonds)
        .toList();

    PlayingCard bidCard;

    if (bidHigh) {
      // Bid black - choose lowest black card
      if (blackCards.isEmpty) {
        // No black cards - use lowest red card (forced to bid low)
        bidCard = _getLowestCard(redCards);
        if (kDebugMode) {
          debugPrint(
            '[AI BIDDING] ${position.name}: Want HIGH but no black cards, bidding LOW with ${bidCard.label}',
          );
        }
      } else {
        bidCard = _getLowestCard(blackCards);
        if (kDebugMode) {
          debugPrint(
            '[AI BIDDING] ${position.name}: Bidding HIGH with ${bidCard.label} (${handStrength.toStringAsFixed(1)} tricks)',
          );
        }
      }
    } else {
      // Bid red - choose lowest red card
      if (redCards.isEmpty) {
        // No red cards - use lowest black card (forced to bid high)
        bidCard = _getLowestCard(blackCards);
        if (kDebugMode) {
          debugPrint(
            '[AI BIDDING] ${position.name}: Want LOW but no red cards, bidding HIGH with ${bidCard.label}',
          );
        }
      } else {
        bidCard = _getLowestCard(redCards);
        if (kDebugMode) {
          debugPrint(
            '[AI BIDDING] ${position.name}: Bidding LOW with ${bidCard.label} (${handStrength.toStringAsFixed(1)} tricks)',
          );
        }
      }
    }

    return bidCard;
  }

  /// Evaluate hand strength (estimated tricks in no-trump)
  static double _evaluateHandStrength(List<PlayingCard> hand) {
    double trickCount = 0;

    // Count high cards by suit
    for (final suit in Suit.values) {
      final suitCards = hand.where((c) => c.suit == suit).toList()
        ..sort(
          (a, b) => b.rank.index.compareTo(a.rank.index),
        ); // Sort high to low

      if (suitCards.isEmpty) continue;

      final suitLength = suitCards.length;
      final hasAce = suitCards.any((c) => c.rank == Rank.ace);
      final hasKing = suitCards.any((c) => c.rank == Rank.king);
      final hasQueen = suitCards.any((c) => c.rank == Rank.queen);
      final hasJack = suitCards.any((c) => c.rank == Rank.jack);

      // Aces are strong winners
      if (hasAce) {
        trickCount += 0.95;
      }

      // Kings
      if (hasKing) {
        if (hasAce && suitLength >= 3) {
          trickCount += 0.8; // AK in decent suit
        } else if (hasAce) {
          trickCount += 0.6; // AK doubleton
        } else if (suitLength >= 4) {
          trickCount += 0.5; // King in long suit
        } else {
          trickCount += 0.25; // Unprotected king
        }
      }

      // Queens
      if (hasQueen) {
        if (hasAce && hasKing) {
          trickCount += 0.6; // AKQ sequence
        } else if ((hasAce || hasKing) && suitLength >= 4) {
          trickCount += 0.35;
        } else if (suitLength >= 5) {
          trickCount += 0.2;
        }
      }

      // Jacks in strong sequences
      if (hasJack && hasAce && hasKing && hasQueen && suitLength >= 4) {
        trickCount += 0.3;
      }

      // Long suit tricks (5th and 6th cards can become winners)
      if (suitLength >= 5 && (hasAce || hasKing)) {
        trickCount += 0.3 * (suitLength - 4);
      }
    }

    // Penalty for very unbalanced hands
    final suitLengths = Suit.values
        .map((s) => hand.where((c) => c.suit == s).length)
        .toList()
      ..sort();

    if (suitLengths[0] == 0) {
      trickCount -= 0.5; // Void
    } else if (suitLengths[0] == 1) {
      trickCount -= 0.25; // Singleton
    }

    // Bonus for balanced distribution
    if (suitLengths[0] >= 2 && suitLengths[3] <= 5) {
      trickCount += 0.2; // Balanced hand
    }

    return trickCount;
  }

  /// Get the lowest card from a list
  static PlayingCard _getLowestCard(List<PlayingCard> cards) {
    if (cards.isEmpty) {
      throw ArgumentError('Cannot get lowest card from empty list');
    }

    // Sort by rank (ascending)
    final sorted = List<PlayingCard>.from(cards)
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    return sorted.first;
  }
}
