import 'package:flutter/foundation.dart';

import '../models/game_models.dart';

/// Handles scoring for Minnesota Whist
///
/// Scoring rules:
/// - High (Grand) Hand: If granding team wins 7+tricks, they score 1 point per trick over 6
/// - High Hand (opponent wins): Opponents score 2 points per trick over 6
/// - Low (Nula) Hand: Team with fewer tricks scores 1 point for every trick under 7
/// - All Red (no one granded): Team with more tricks loses 1 point per trick over 6
/// - Game ends when a team reaches 13 points (default)
class MinnesotaWhistScorer {
  // Private constructor to prevent instantiation
  MinnesotaWhistScorer._();

  /// Default winning score for Minnesota Whist
  static const int defaultWinningScore = 13;

  /// Score a completed hand
  static HandScore scoreHand({
    required BidType handType,
    required Team grandingTeam,
    required int tricksWonByGrandingTeam,
    bool allBidLow = false,
  }) {
    if (kDebugMode) {
      debugPrint('\n[SCORER] Scoring Minnesota Whist hand');
      debugPrint(
        '  Hand type: ${handType == BidType.high ? "HIGH (Grand)" : "LOW (Nula)"}',
      );
      debugPrint('  Granding team: ${_teamName(grandingTeam)}');
      debugPrint('  Tricks won by granding team: $tricksWonByGrandingTeam');
      debugPrint('  All bid low: $allBidLow');
    }

    // Validate trick counts
    final tricksWonByOpponents = 13 - tricksWonByGrandingTeam;
    if (tricksWonByGrandingTeam < 0 || tricksWonByGrandingTeam > 13) {
      final error = 'Tricks must be 0-13 (got $tricksWonByGrandingTeam)';
      if (kDebugMode) {
        debugPrint('  ⚠️  ERROR: $error');
      }
      throw ArgumentError(error);
    }

    final opponentTeam =
        grandingTeam == Team.northSouth ? Team.eastWest : Team.northSouth;

    int teamNSPoints = 0;
    int teamEWPoints = 0;
    bool grandingTeamSucceeded = false;
    String resultDescription;

    if (allBidLow) {
      // Special case: All players bid red (low)
      // Team that wins more tricks loses points
      if (grandingTeam == Team.northSouth) {
        if (tricksWonByGrandingTeam > tricksWonByOpponents) {
          teamNSPoints = -(tricksWonByGrandingTeam - 6);
          resultDescription =
              'All bid LOW. North-South took $tricksWonByGrandingTeam tricks and loses ${-teamNSPoints} points';
        } else if (tricksWonByOpponents > tricksWonByGrandingTeam) {
          teamEWPoints = -(tricksWonByOpponents - 6);
          resultDescription =
              'All bid LOW. East-West took $tricksWonByOpponents tricks and loses ${-teamEWPoints} points';
        } else {
          resultDescription = 'All bid LOW. Tied 6-6, no points scored';
        }
      } else {
        if (tricksWonByOpponents > tricksWonByGrandingTeam) {
          teamNSPoints = -(tricksWonByOpponents - 6);
          resultDescription =
              'All bid LOW. North-South took $tricksWonByOpponents tricks and loses ${-teamNSPoints} points';
        } else if (tricksWonByGrandingTeam > tricksWonByOpponents) {
          teamEWPoints = -(tricksWonByGrandingTeam - 6);
          resultDescription =
              'All bid LOW. East-West took $tricksWonByGrandingTeam tricks and loses ${-teamEWPoints} points';
        } else {
          resultDescription = 'All bid LOW. Tied 6-6, no points scored';
        }
      }
    } else if (handType == BidType.high) {
      // High (Grand) hand
      if (tricksWonByGrandingTeam >= 7) {
        // Granding team succeeded
        grandingTeamSucceeded = true;
        final points = tricksWonByGrandingTeam - 6;
        if (grandingTeam == Team.northSouth) {
          teamNSPoints = points;
        } else {
          teamEWPoints = points;
        }
        resultDescription =
            '${_teamName(grandingTeam)} granded HIGH and won $tricksWonByGrandingTeam tricks (+$points)';
      } else {
        // Opponents won - they score 2 points per trick over 6
        final points = (tricksWonByOpponents - 6) * 2;
        if (opponentTeam == Team.northSouth) {
          teamNSPoints = points;
        } else {
          teamEWPoints = points;
        }
        resultDescription =
            '${_teamName(grandingTeam)} granded HIGH but only won $tricksWonByGrandingTeam tricks. ${_teamName(opponentTeam)} scores +$points (×2)';
      }
    } else {
      // Low (Nula) hand
      if (tricksWonByGrandingTeam <= 6) {
        // Granding team succeeded
        grandingTeamSucceeded = true;
        final points = 7 - tricksWonByGrandingTeam;
        if (grandingTeam == Team.northSouth) {
          teamNSPoints = points;
        } else {
          teamEWPoints = points;
        }
        resultDescription =
            '${_teamName(grandingTeam)} granded LOW and won only $tricksWonByGrandingTeam tricks (+$points)';
      } else {
        // Granding team failed - opponents score
        final points = 7 - tricksWonByOpponents;
        if (opponentTeam == Team.northSouth) {
          teamNSPoints = points;
        } else {
          teamEWPoints = points;
        }
        resultDescription =
            '${_teamName(grandingTeam)} granded LOW but won $tricksWonByGrandingTeam tricks. ${_teamName(opponentTeam)} scores +$points';
      }
    }

    if (kDebugMode) {
      debugPrint(
        '  Team North-South points: ${teamNSPoints > 0 ? "+$teamNSPoints" : teamNSPoints}',
      );
      debugPrint(
        '  Team East-West points: ${teamEWPoints > 0 ? "+$teamEWPoints" : teamEWPoints}',
      );
      debugPrint('  $resultDescription');
    }

    return HandScore(
      teamNSPoints: teamNSPoints,
      teamEWPoints: teamEWPoints,
      grandingTeamSucceeded: grandingTeamSucceeded,
      tricksWonByGrandingTeam: tricksWonByGrandingTeam,
      tricksWonByOpponents: tricksWonByOpponents,
      description: resultDescription,
    );
  }

  /// Check if game is over and determine winner
  static GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int winningScore = defaultWinningScore,
  }) {
    if (kDebugMode) {
      debugPrint('\n[SCORER] Checking game over status');
      debugPrint('  North-South score: $teamNSScore');
      debugPrint('  East-West score: $teamEWScore');
      debugPrint('  Winning score: $winningScore');
    }

    // Check for wins
    if (teamNSScore >= winningScore && teamEWScore >= winningScore) {
      // Both teams reached winning score - highest score wins
      if (teamNSScore > teamEWScore) {
        if (kDebugMode) {
          debugPrint(
            '  GAME OVER: Both teams reached $winningScore+, North-South wins ($teamNSScore > $teamEWScore)',
          );
        }
        return GameOverStatus.teamNSWins;
      } else {
        if (kDebugMode) {
          debugPrint(
            '  GAME OVER: Both teams reached $winningScore+, East-West wins ($teamEWScore > $teamNSScore)',
          );
        }
        return GameOverStatus.teamEWWins;
      }
    }

    if (teamNSScore >= winningScore) {
      if (kDebugMode) {
        debugPrint(
          '  GAME OVER: North-South reaches $winningScore+ ($teamNSScore)',
        );
      }
      return GameOverStatus.teamNSWins;
    }

    if (teamEWScore >= winningScore) {
      if (kDebugMode) {
        debugPrint(
          '  GAME OVER: East-West reaches $winningScore+ ($teamEWScore)',
        );
      }
      return GameOverStatus.teamEWWins;
    }

    // Game continues
    if (kDebugMode) {
      debugPrint('  Game continues (no win condition met)');
    }
    return null;
  }

  /// Get game over message
  static String getGameOverMessage(
    GameOverStatus status,
    int scoreNS,
    int scoreEW,
  ) {
    switch (status) {
      case GameOverStatus.teamNSWins:
        return 'Team North-South wins! Final score: $scoreNS to $scoreEW';
      case GameOverStatus.teamEWWins:
        return 'Team East-West wins! Final score: $scoreEW to $scoreNS';
    }
  }

  static String _teamName(Team team) {
    return team == Team.northSouth ? 'North-South' : 'East-West';
  }
}

/// Result of scoring a hand in Minnesota Whist
class HandScore {
  const HandScore({
    required this.teamNSPoints,
    required this.teamEWPoints,
    required this.grandingTeamSucceeded,
    required this.tricksWonByGrandingTeam,
    required this.tricksWonByOpponents,
    required this.description,
  });

  final int
      teamNSPoints; // Points scored by North-South (can be negative in all-low)
  final int
      teamEWPoints; // Points scored by East-West (can be negative in all-low)
  final bool grandingTeamSucceeded;
  final int tricksWonByGrandingTeam;
  final int tricksWonByOpponents;
  final String description;

  @override
  String toString() => description;
}

/// Game over status
enum GameOverStatus {
  teamNSWins, // North-South reached winning score
  teamEWWins, // East-West reached winning score
}
