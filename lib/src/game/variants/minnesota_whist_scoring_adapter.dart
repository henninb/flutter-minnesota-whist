import '../logic/scoring_engine.dart';
import '../logic/minnesota_whist_scorer.dart' as legacy;
import '../models/game_models.dart';

/// Adapter that wraps the legacy MinnesotaWhistScorer to conform to
/// the new abstract ScoringEngine interface
class MinnesotaWhistScoringEngineAdapter extends ScoringEngine {
  const MinnesotaWhistScoringEngineAdapter();

  @override
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  }) {
    // Validate required parameters for Minnesota Whist
    if (handType == null) {
      throw ArgumentError('handType is required for Minnesota Whist scoring');
    }
    if (contractingTeam == null) {
      throw ArgumentError(
        'contractingTeam (granding team) is required for Minnesota Whist scoring',
      );
    }
    if (tricksWonByContractingTeam == null) {
      throw ArgumentError(
        'tricksWonByContractingTeam is required for Minnesota Whist scoring',
      );
    }

    // Extract Minnesota Whist specific parameter
    final allBidLow = additionalParams?['allBidLow'] as bool? ?? false;

    // Use legacy scorer
    final legacyScore = legacy.MinnesotaWhistScorer.scoreHand(
      handType: handType,
      grandingTeam: contractingTeam,
      tricksWonByGrandingTeam: tricksWonByContractingTeam,
      allBidLow: allBidLow,
    );

    // Convert legacy HandScore to new HandScore
    return HandScore(
      teamNSPoints: legacyScore.teamNSPoints,
      teamEWPoints: legacyScore.teamEWPoints,
      description: legacyScore.description,
      additionalData: {
        'grandingTeamSucceeded': legacyScore.grandingTeamSucceeded,
        'tricksWonByGrandingTeam': legacyScore.tricksWonByGrandingTeam,
        'tricksWonByOpponents': legacyScore.tricksWonByOpponents,
      },
    );
  }

  @override
  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int? winningScore,
  }) {
    final legacy.GameOverStatus? legacyStatus =
        legacy.MinnesotaWhistScorer.checkGameOver(
      teamNSScore: teamNSScore,
      teamEWScore: teamEWScore,
      winningScore:
          winningScore ?? legacy.MinnesotaWhistScorer.defaultWinningScore,
    );

    if (legacyStatus == null) {
      return null;
    }

    // Convert legacy GameOverStatus to new GameOverStatus
    switch (legacyStatus) {
      case legacy.GameOverStatus.teamNSWins:
        return GameOverStatus.teamNSWins;
      case legacy.GameOverStatus.teamEWWins:
        return GameOverStatus.teamEWWins;
    }
  }

  @override
  String getGameOverMessage(GameOverStatus status, int scoreNS, int scoreEW) {
    // Convert new GameOverStatus to legacy GameOverStatus
    final legacyStatus = status == GameOverStatus.teamNSWins
        ? legacy.GameOverStatus.teamNSWins
        : legacy.GameOverStatus.teamEWWins;

    return legacy.MinnesotaWhistScorer.getGameOverMessage(
      legacyStatus,
      scoreNS,
      scoreEW,
    );
  }

  @override
  String getScoreDescription(HandScore score) {
    // The description is already in the HandScore
    return score.description;
  }

  /// Get the default winning score for Minnesota Whist
  static int get defaultWinningScore =>
      legacy.MinnesotaWhistScorer.defaultWinningScore;
}
