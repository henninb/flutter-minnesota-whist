import '../models/game_models.dart';

/// Minnesota Whist Scoring Rules
///
/// Scoring in Minnesota Whist is simple and based on tricks taken:
/// - High (Grand) Hand: Team that granded scores 1 point per trick over 6
/// - High Hand (opponent granded): Non-granding team scores 2 points per trick over 6
/// - Low (Nula) Hand: Team scores 1 point for every trick under 7
///
/// Game is played to 13 points (typically).
class MinnesotaWhistScoring {
  // Private constructor to prevent instantiation
  MinnesotaWhistScoring._();

  /// Default winning score for Minnesota Whist
  static const int defaultWinningScore = 13;

  /// Calculate points for a hand based on tricks taken
  ///
  /// Parameters:
  /// - tricksWonByGrandingTeam: Number of tricks won by the team that granded
  /// - handType: Whether this was a high (grand) or low (nula) hand
  /// - grandingTeam: Which team made the grand bid
  ///
  /// Returns a map of team -> points scored for this hand
  static Map<Team, int> scoreHand({
    required int tricksWonByGrandingTeam,
    required BidType handType,
    required Team grandingTeam,
  }) {
    final tricksWonByOpponents = 13 - tricksWonByGrandingTeam;

    final scores = <Team, int>{
      Team.northSouth: 0,
      Team.eastWest: 0,
    };

    final opponentTeam =
        grandingTeam == Team.northSouth ? Team.eastWest : Team.northSouth;

    if (handType == BidType.high) {
      // High (Grand) hand: Need 7+ tricks to score
      if (tricksWonByGrandingTeam >= 7) {
        // Granding team succeeded
        scores[grandingTeam] = tricksWonByGrandingTeam - 6;
      } else {
        // Opponents won - they score 2 points per trick over 6
        scores[opponentTeam] = (tricksWonByOpponents - 6) * 2;
      }
    } else {
      // Low (Nula) hand: Want to take 6 or fewer tricks
      if (tricksWonByGrandingTeam <= 6) {
        // Granding team succeeded - score 1 point per trick under 7
        scores[grandingTeam] = 7 - tricksWonByGrandingTeam;
      } else {
        // Granding team failed - opponents score 1 point per trick under 7
        scores[opponentTeam] = 7 - tricksWonByOpponents;
      }
    }

    return scores;
  }

  /// Alternative scoring: All players bid red (Low hand, no one granded)
  /// The team that takes more tricks loses points
  static Map<Team, int> scoreAllLowHand({
    required int tricksWonByNorthSouth,
  }) {
    final tricksWonByEastWest = 13 - tricksWonByNorthSouth;

    final scores = <Team, int>{
      Team.northSouth: 0,
      Team.eastWest: 0,
    };

    // Team with more tricks loses 1 point per trick over 6
    if (tricksWonByNorthSouth > tricksWonByEastWest) {
      scores[Team.northSouth] = -(tricksWonByNorthSouth - 6);
    } else if (tricksWonByEastWest > tricksWonByNorthSouth) {
      scores[Team.eastWest] = -(tricksWonByEastWest - 6);
    }
    // If tied at 6-6 (rare in 13-trick game), no points scored

    return scores;
  }

  /// Check if a team has won the game
  static bool hasWon(int score, {int winningScore = defaultWinningScore}) {
    return score >= winningScore;
  }

  /// Get a description of the hand result
  static String getHandResultDescription({
    required int tricksWonByGrandingTeam,
    required BidType handType,
    required Team grandingTeam,
    required Map<Team, int> pointsScored,
  }) {
    final opponentTeam =
        grandingTeam == Team.northSouth ? Team.eastWest : Team.northSouth;

    if (handType == BidType.high) {
      if (tricksWonByGrandingTeam >= 7) {
        final points = pointsScored[grandingTeam]!;
        return '${_teamName(grandingTeam)} granded HIGH and won $tricksWonByGrandingTeam tricks. +$points points';
      } else {
        final points = pointsScored[opponentTeam]!;
        return '${_teamName(grandingTeam)} granded HIGH but only won $tricksWonByGrandingTeam tricks. ${_teamName(opponentTeam)} scores +$points points (×2 multiplier)';
      }
    } else {
      if (tricksWonByGrandingTeam <= 6) {
        final points = pointsScored[grandingTeam]!;
        return '${_teamName(grandingTeam)} granded LOW and won only $tricksWonByGrandingTeam tricks. +$points points';
      } else {
        final points = pointsScored[opponentTeam]!;
        return '${_teamName(grandingTeam)} granded LOW but won $tricksWonByGrandingTeam tricks. ${_teamName(opponentTeam)} scores +$points points';
      }
    }
  }

  static String _teamName(Team team) {
    return team == Team.northSouth ? 'North-South' : 'East-West';
  }
}
