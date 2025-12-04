import '../models/game_models.dart';

/// Abstract base class for variant-specific scoring engines
abstract class ScoringEngine {
  const ScoringEngine();

  /// Score a completed hand
  ///
  /// Returns HandScore with points for each team
  /// additionalParams allows variants to pass variant-specific data
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  });

  /// Check if game is over and determine winner
  /// Returns null if game should continue
  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int? winningScore,
  });

  /// Get game over message
  String getGameOverMessage(
    GameOverStatus status,
    int scoreNS,
    int scoreEW,
  );

  /// Get description of how points were scored
  /// Used for player feedback
  String getScoreDescription(HandScore score);
}

/// Result of scoring a hand
class HandScore {
  const HandScore({
    required this.teamNSPoints,
    required this.teamEWPoints,
    required this.description,
    this.additionalData,
  });

  final int teamNSPoints;
  final int teamEWPoints;
  final String description;
  final Map<String, dynamic>? additionalData;

  @override
  String toString() => description;
}

/// Game over status
enum GameOverStatus {
  teamNSWins,
  teamEWWins,
  draw, // For variants that allow draws
}
