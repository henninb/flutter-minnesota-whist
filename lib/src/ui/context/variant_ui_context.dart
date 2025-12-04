import 'package:flutter/material.dart';
import '../../game/engine/game_state.dart';
import '../../game/models/card.dart';
import '../../game/models/game_models.dart';

/// Context for building bidding widgets
class BiddingWidgetContext {
  const BiddingWidgetContext({
    required this.playerHand,
    required this.currentBids,
    required this.currentBidder,
    required this.onBidSubmitted,
    required this.gameState,
  });

  final List<PlayingCard> playerHand;
  final List<BidEntry> currentBids;
  final Position currentBidder;
  final Function(dynamic bid) onBidSubmitted;
  final GameState gameState;
}

/// Context for building trump indicators
class TrumpIndicatorContext {
  const TrumpIndicatorContext({
    required this.trumpSuit,
    required this.isRevealed,
    this.declarer,
    required this.gameState,
  });

  final Suit? trumpSuit;
  final bool isRevealed;
  final Position? declarer;
  final GameState gameState;
}

/// Context for special card displays (kitty, widow)
class SpecialCardContext {
  const SpecialCardContext({
    required this.cards,
    required this.isRevealed,
    required this.label,
    this.onCardsSelected,
    required this.gameState,
  });

  final List<PlayingCard> cards;
  final bool isRevealed;
  final String label;
  final Function(List<PlayingCard>)? onCardsSelected;
  final GameState gameState;
}

/// Represents an action the player can take
class GameAction {
  const GameAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.disabledReason,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? disabledReason;
}
