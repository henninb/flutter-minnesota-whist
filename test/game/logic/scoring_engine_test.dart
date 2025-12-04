import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/game/logic/scoring_engine.dart';
import 'package:minnesota_whist/src/game/models/game_models.dart';

/// Mock scoring engine for testing the abstract base class
class MockScoringEngine extends ScoringEngine {
  const MockScoringEngine();

  @override
  HandScore scoreHand({
    BidType? handType,
    Team? contractingTeam,
    int? tricksWonByContractingTeam,
    Map<String, dynamic>? additionalParams,
  }) {
    // Simple mock: 1 point per trick over 6
    final tricks = tricksWonByContractingTeam ?? 0;
    final points = tricks > 6 ? tricks - 6 : 0;

    final teamNSPoints = contractingTeam == Team.northSouth ? points : 0;
    final teamEWPoints = contractingTeam == Team.eastWest ? points : 0;

    return HandScore(
      teamNSPoints: teamNSPoints,
      teamEWPoints: teamEWPoints,
      description: 'Mock scoring: $points points',
      additionalData: additionalParams,
    );
  }

  @override
  GameOverStatus? checkGameOver({
    required int teamNSScore,
    required int teamEWScore,
    int? winningScore,
  }) {
    final target = winningScore ?? 13;

    if (teamNSScore >= target && teamEWScore >= target) {
      // Both teams reached target - higher wins
      return teamNSScore > teamEWScore
          ? GameOverStatus.teamNSWins
          : GameOverStatus.teamEWWins;
    }

    if (teamNSScore >= target) return GameOverStatus.teamNSWins;
    if (teamEWScore >= target) return GameOverStatus.teamEWWins;

    return null; // Game continues
  }

  @override
  String getGameOverMessage(
    GameOverStatus status,
    int scoreNS,
    int scoreEW,
  ) {
    switch (status) {
      case GameOverStatus.teamNSWins:
        return 'North-South wins $scoreNS to $scoreEW';
      case GameOverStatus.teamEWWins:
        return 'East-West wins $scoreEW to $scoreNS';
      case GameOverStatus.draw:
        return 'Game ends in a draw';
    }
  }

  @override
  String getScoreDescription(HandScore score) {
    return score.description;
  }
}

void main() {
  group('ScoringEngine', () {
    late MockScoringEngine scoringEngine;

    setUp(() {
      scoringEngine = const MockScoringEngine();
    });

    group('HandScore', () {
      test('creates score with team points and description', () {
        const score = HandScore(
          teamNSPoints: 3,
          teamEWPoints: 0,
          description: 'North-South scores 3 points',
        );

        expect(score.teamNSPoints, equals(3));
        expect(score.teamEWPoints, equals(0));
        expect(score.description, equals('North-South scores 3 points'));
        expect(score.additionalData, isNull);
      });

      test('supports negative points', () {
        const score = HandScore(
          teamNSPoints: -2,
          teamEWPoints: 0,
          description: 'North-South loses 2 points',
        );

        expect(score.teamNSPoints, equals(-2));
      });

      test('supports additional data', () {
        final additionalData = {
          'tricksTaken': 12,
          'grandingTeam': 'NS',
          'succeeded': true,
        };

        final score = HandScore(
          teamNSPoints: 6,
          teamEWPoints: 0,
          description: 'Grand succeeded',
          additionalData: additionalData,
        );

        expect(score.additionalData, equals(additionalData));
        expect(score.additionalData?['tricksTaken'], equals(12));
      });

      test('toString returns description', () {
        const score = HandScore(
          teamNSPoints: 1,
          teamEWPoints: 0,
          description: 'Test description',
        );

        expect(score.toString(), equals('Test description'));
      });
    });

    group('GameOverStatus enum', () {
      test('has expected values', () {
        expect(GameOverStatus.values.length, equals(3));
        expect(GameOverStatus.values, contains(GameOverStatus.teamNSWins));
        expect(GameOverStatus.values, contains(GameOverStatus.teamEWWins));
        expect(GameOverStatus.values, contains(GameOverStatus.draw));
      });
    });

    group('MockScoringEngine implementation', () {
      test('scoreHand returns zero points for 6 tricks', () {
        final score = scoringEngine.scoreHand(
          handType: BidType.high,
          contractingTeam: Team.northSouth,
          tricksWonByContractingTeam: 6,
        );

        expect(score.teamNSPoints, equals(0));
        expect(score.teamEWPoints, equals(0));
      });

      test('scoreHand awards points for tricks over 6', () {
        final score = scoringEngine.scoreHand(
          handType: BidType.high,
          contractingTeam: Team.northSouth,
          tricksWonByContractingTeam: 9,
        );

        expect(score.teamNSPoints, equals(3));
        expect(score.teamEWPoints, equals(0));
      });

      test('scoreHand awards points to correct team', () {
        final score = scoringEngine.scoreHand(
          handType: BidType.high,
          contractingTeam: Team.eastWest,
          tricksWonByContractingTeam: 10,
        );

        expect(score.teamNSPoints, equals(0));
        expect(score.teamEWPoints, equals(4));
      });

      test('scoreHand includes description', () {
        final score = scoringEngine.scoreHand(
          handType: BidType.high,
          contractingTeam: Team.northSouth,
          tricksWonByContractingTeam: 8,
        );

        expect(score.description, contains('2 points'));
      });

      test('scoreHand passes through additional parameters', () {
        final additionalParams = {'allBidLow': true};

        final score = scoringEngine.scoreHand(
          handType: BidType.low,
          contractingTeam: Team.northSouth,
          tricksWonByContractingTeam: 5,
          additionalParams: additionalParams,
        );

        expect(score.additionalData, equals(additionalParams));
      });

      test('checkGameOver returns null when game continues', () {
        final status = scoringEngine.checkGameOver(
          teamNSScore: 8,
          teamEWScore: 5,
        );

        expect(status, isNull);
      });

      test('checkGameOver detects North-South win', () {
        final status = scoringEngine.checkGameOver(
          teamNSScore: 13,
          teamEWScore: 7,
        );

        expect(status, equals(GameOverStatus.teamNSWins));
      });

      test('checkGameOver detects East-West win', () {
        final status = scoringEngine.checkGameOver(
          teamNSScore: 10,
          teamEWScore: 13,
        );

        expect(status, equals(GameOverStatus.teamEWWins));
      });

      test('checkGameOver handles both teams reaching target', () {
        final status = scoringEngine.checkGameOver(
          teamNSScore: 15,
          teamEWScore: 13,
        );

        expect(status, equals(GameOverStatus.teamNSWins));
      });

      test('checkGameOver respects custom winning score', () {
        final status = scoringEngine.checkGameOver(
          teamNSScore: 10,
          teamEWScore: 5,
          winningScore: 10,
        );

        expect(status, equals(GameOverStatus.teamNSWins));
      });

      test('getGameOverMessage returns correct message for NS win', () {
        final message = scoringEngine.getGameOverMessage(
          GameOverStatus.teamNSWins,
          13,
          8,
        );

        expect(message, equals('North-South wins 13 to 8'));
      });

      test('getGameOverMessage returns correct message for EW win', () {
        final message = scoringEngine.getGameOverMessage(
          GameOverStatus.teamEWWins,
          9,
          13,
        );

        expect(message, equals('East-West wins 13 to 9'));
      });

      test('getGameOverMessage handles draw', () {
        final message = scoringEngine.getGameOverMessage(
          GameOverStatus.draw,
          13,
          13,
        );

        expect(message, equals('Game ends in a draw'));
      });

      test('getScoreDescription returns score description', () {
        const score = HandScore(
          teamNSPoints: 2,
          teamEWPoints: 0,
          description: 'Test score description',
        );

        final description = scoringEngine.getScoreDescription(score);
        expect(description, equals('Test score description'));
      });
    });
  });
}
