import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/game_models.dart';

/// Result of dealing cards for Minnesota Whist
class DealResult {
  DealResult({
    required this.hands,
  });

  final Map<Position, List<PlayingCard>> hands;
}

/// Deal cards for Minnesota Whist
///
/// Cards are dealt one at a time starting with the person to the left of
/// the dealer and moving clockwise until all cards are dealt.
///
/// Result: Each player has 13 cards (52 card deck ÷ 4 players)
DealResult dealHand({
  required List<PlayingCard> deck,
  required Position dealer,
}) {
  if (deck.length != 52) {
    throw ArgumentError('Deck must have exactly 52 cards (got ${deck.length})');
  }

  final drawDeck = List<PlayingCard>.from(deck);
  final hands = <Position, List<PlayingCard>>{
    Position.north: [],
    Position.south: [],
    Position.east: [],
    Position.west: [],
  };

  // Get dealing order (starts with player to dealer's left, goes clockwise)
  final dealingOrder = _getDealingOrder(dealer);

  // Deal cards one at a time (13 rounds of 4 cards each)
  for (int i = 0; i < 13; i++) {
    for (final position in dealingOrder) {
      hands[position]!.add(drawDeck.removeAt(0));
    }
  }

  // Verify - use runtime checks instead of asserts (asserts removed in release builds)
  final northCount = hands[Position.north]!.length;
  final southCount = hands[Position.south]!.length;
  final eastCount = hands[Position.east]!.length;
  final westCount = hands[Position.west]!.length;
  final remainingCards = drawDeck.length;

  if (northCount != 13 || southCount != 13 || eastCount != 13 || westCount != 13) {
    final error = 'Deal validation failed: Invalid hand counts - '
        'N:$northCount S:$southCount E:$eastCount W:$westCount (expected 13 each)';
    if (kDebugMode) {
      debugPrint('[DealUtils] ERROR: $error');
    }
    throw StateError(error);
  }

  if (remainingCards != 0) {
    final error = 'Deal validation failed: Cards remaining in deck - $remainingCards (expected 0)';
    if (kDebugMode) {
      debugPrint('[DealUtils] ERROR: $error');
    }
    throw StateError(error);
  }

  if (kDebugMode) {
    debugPrint('[DealUtils] Deal validated successfully: All hands 13 cards');
  }

  return DealResult(hands: hands);
}

/// Get dealing order starting from dealer's left
List<Position> _getDealingOrder(Position dealer) {
  final order = <Position>[];
  var current = dealer.next; // Start with player to dealer's left
  for (int i = 0; i < 4; i++) {
    order.add(current);
    current = current.next;
  }
  return order;
}

/// Get next dealer (rotates clockwise)
Position getNextDealer(Position currentDealer) {
  return currentDealer.next;
}
