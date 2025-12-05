import 'package:flutter_test/flutter_test.dart';
import 'package:minnesota_whist/src/game/variants/classic_whist_variant.dart';
import 'package:minnesota_whist/src/game/variants/game_variant.dart';
import 'package:minnesota_whist/src/game/logic/scoring_engine.dart';
import 'package:minnesota_whist/src/game/models/game_models.dart';

void main() {
  group('ClassicWhistVariant', () {
    late ClassicWhistVariant variant;

    setUp(() {
      variant = const ClassicWhistVariant();
    });

    group('basic properties', () {
      test('has correct name', () {
        expect(variant.name, 'Classic Whist');
      });

      test('has short description', () {
        expect(variant.shortDescription, isNotEmpty);
        expect(variant.shortDescription.toLowerCase(), contains('trump'));
      });

      test('has full description', () {
        expect(variant.description, isNotEmpty);
        expect(variant.description.length, greaterThan(variant.shortDescription.length));
      });

      test('has icon', () {
        expect(variant.icon, isNotNull);
      });
    });

    group('bidding configuration', () {
      test('does not use bidding', () {
        expect(variant.usesBidding, false);
      });

      test('returns null for bidding engine', () {
        final engine = variant.createBiddingEngine(Position.north);
        expect(engine, isNull);
      });

      test('has bidding rules explanation', () {
        final rules = variant.getBiddingRules();
        expect(rules, isNotEmpty);
        expect(rules.toLowerCase(), contains('no bidding'));
      });
    });

    group('trump configuration', () {
      test('uses last card trump selection', () {
        expect(variant.trumpSelectionMethod, TrumpSelectionMethod.lastCard);
      });

      test('has correct trick count', () {
        expect(variant.tricksPerHand, 13);
      });
    });

    group('scoring configuration', () {
      test('creates scoring engine', () {
        final engine = variant.createScoringEngine();
        expect(engine, isNotNull);
        expect(engine, isA<ClassicWhistScoringEngine>());
      });

      test('has winning score of 7', () {
        expect(variant.winningScore, 7);
      });

      test('has scoring rules explanation', () {
        final rules = variant.getScoringRules();
        expect(rules, isNotEmpty);
        expect(rules.toLowerCase(), contains('book'));
        expect(rules, contains('6'));
      });
    });

    group('special features', () {
      test('has no special cards', () {
        expect(variant.hasSpecialCards, false);
        expect(variant.specialCardCount, 0);
        expect(variant.specialCardsLabel, isEmpty);
      });

      test('does not allow claiming tricks', () {
        expect(variant.allowsClaimingTricks, false);
      });
    });

    group('documentation', () {
      test('has quick reference', () {
        final ref = variant.getQuickReference();
        expect(ref, isNotEmpty);
        expect(ref.toLowerCase(), contains('trump'));
        expect(ref.toLowerCase(), contains('book'));
      });

      test('has full rules text', () {
        final rules = variant.getRulesText();
        expect(rules, isNotEmpty);
        expect(rules, contains('Classic Whist'));
        expect(rules.toLowerCase(), contains('trick'));
        expect(rules.toLowerCase(), contains('book'));
      });

      test('rules mention key differences from Minnesota Whist', () {
        final rules = variant.getRulesText();
        expect(rules.toLowerCase(), contains('minnesota whist'));
        expect(rules.toLowerCase(), contains('no bidding'));
      });
    });
  });

  group('ClassicWhistScoringEngine', () {
    late ClassicWhistScoringEngine engine;

    setUp(() {
      engine = const ClassicWhistScoringEngine();
    });

    HandScore scoreWithTricks(int ns, int ew) {
      return engine.scoreHand(
        additionalParams: {
          'northSouthTricks': ns,
          'eastWestTricks': ew,
        },
      );
    }

    group('book scoring (6 tricks or less)', () {
      test('scores 0 points for exactly 6 tricks', () {
        final result = scoreWithTricks(6, 7);
        expect(result.teamNSPoints, 0);
        expect(result.description, contains('book or less'));
      });

      test('scores 0 points for fewer than 6 tricks', () {
        final result = scoreWithTricks(4, 9);
        expect(result.teamNSPoints, 0);
        expect(result.description, contains('book or less'));
      });

      test('scores 0 points for 0 tricks', () {
        final result = scoreWithTricks(0, 13);
        expect(result.teamNSPoints, 0);
      });
    });

    group('odd trick scoring (7+ tricks)', () {
      test('scores 1 point for 7 tricks (1 odd trick)', () {
        final result = scoreWithTricks(7, 6);
        expect(result.teamNSPoints, 1);
        expect(result.description, contains('1 odd tricks'));
        expect(result.description, contains('1 points'));
      });

      test('scores 3 points for 9 tricks (3 odd tricks)', () {
        final result = scoreWithTricks(9, 4);
        expect(result.teamNSPoints, 3);
        expect(result.description, contains('3 odd tricks'));
        expect(result.description, contains('3 points'));
      });

      test('scores 7 points for all 13 tricks (7 odd tricks)', () {
        final result = scoreWithTricks(13, 0);
        expect(result.teamNSPoints, 7);
        expect(result.description, contains('7 odd tricks'));
        expect(result.description, contains('7 points'));
      });

      test('scores 2 points for 8 tricks (2 odd tricks)', () {
        final result = scoreWithTricks(8, 5);
        expect(result.teamNSPoints, 2);
        expect(result.description, contains('2 odd tricks'));
      });
    });

    group('both teams scoring', () {
      test('scores correctly when teams split 7-6', () {
        final result = scoreWithTricks(7, 6);
        expect(result.teamNSPoints, 1); // 7 - 6 = 1
        expect(result.teamEWPoints, 0); // 6 = book
      });

      test('scores correctly when teams split 10-3', () {
        final result = scoreWithTricks(10, 3);
        expect(result.teamNSPoints, 4); // 10 - 6 = 4
        expect(result.teamEWPoints, 0); // 3 < 6 = 0
      });

      test('neither team scores when both at book', () {
        final result = scoreWithTricks(6, 6);
        expect(result.teamNSPoints, 0);
        expect(result.teamEWPoints, 0);
      });
    });

    group('explanation text', () {
      test('includes trick calculation in explanation', () {
        final result = scoreWithTricks(9, 4);
        expect(result.description, contains('9 tricks'));
        expect(result.description, contains('6 (book)'));
        expect(result.description, contains('3 odd tricks'));
      });

      test('explains both teams', () {
        final result = scoreWithTricks(8, 5);
        expect(result.description, contains('North-South'));
        expect(result.description, contains('East-West'));
      });

      test('shows book or less message for low scores', () {
        final result = scoreWithTricks(4, 9);
        expect(result.description, contains('book or less'));
      });
    });

    group('game over logic', () {
      test('returns null when neither team reaches target', () {
        final status = engine.checkGameOver(
          teamNSScore: 5,
          teamEWScore: 4,
          winningScore: 7,
        );
        expect(status, isNull);
      });

      test('returns NS wins when NS reaches target first', () {
        final status = engine.checkGameOver(
          teamNSScore: 7,
          teamEWScore: 5,
          winningScore: 7,
        );
        expect(status, GameOverStatus.teamNSWins);
      });

      test('returns EW wins when EW reaches target first', () {
        final status = engine.checkGameOver(
          teamNSScore: 4,
          teamEWScore: 7,
          winningScore: 7,
        );
        expect(status, GameOverStatus.teamEWWins);
      });

      test('returns higher score when both reach target', () {
        final status = engine.checkGameOver(
          teamNSScore: 8,
          teamEWScore: 7,
          winningScore: 7,
        );
        expect(status, GameOverStatus.teamNSWins);
      });

      test('returns draw when both reach target with same score', () {
        final status = engine.checkGameOver(
          teamNSScore: 7,
          teamEWScore: 7,
          winningScore: 7,
        );
        expect(status, GameOverStatus.draw);
      });
    });

    group('game over messages', () {
      test('generates NS win message', () {
        final msg = engine.getGameOverMessage(GameOverStatus.teamNSWins, 7, 5);
        expect(msg.toLowerCase(), contains('north-south'));
        expect(msg.toLowerCase(), contains('wins'));
        expect(msg, contains('7'));
        expect(msg, contains('5'));
      });

      test('generates EW win message', () {
        final msg = engine.getGameOverMessage(GameOverStatus.teamEWWins, 4, 7);
        expect(msg.toLowerCase(), contains('east-west'));
        expect(msg.toLowerCase(), contains('wins'));
        expect(msg, contains('7'));
        expect(msg, contains('4'));
      });

      test('generates draw message', () {
        final msg = engine.getGameOverMessage(GameOverStatus.draw, 7, 7);
        expect(msg.toLowerCase(), contains('draw'));
        expect(msg, contains('7'));
      });
    });

    group('scoring explanation', () {
      test('provides scoring system explanation', () {
        final explanation = engine.explainScoring();
        expect(explanation, isNotEmpty);
        expect(explanation.toLowerCase(), contains('book'));
        expect(explanation, contains('6'));
        expect(explanation.toLowerCase(), contains('odd trick'));
      });

      test('includes examples in explanation', () {
        final explanation = engine.explainScoring();
        expect(explanation, contains('7 tricks'));
        expect(explanation, contains('9 tricks'));
        expect(explanation, contains('13 tricks'));
      });
    });

    group('edge cases', () {
      test('handles maximum score (all tricks)', () {
        final result = scoreWithTricks(13, 0);
        expect(result.teamNSPoints, 7);
        expect(result.teamEWPoints, 0);
      });

      test('handles minimum score (no tricks)', () {
        final result = scoreWithTricks(0, 13);
        expect(result.teamNSPoints, 0);
        expect(result.teamEWPoints, 7);
      });

      test('handles typical split (7-6)', () {
        final result = scoreWithTricks(7, 6);
        expect(result.teamNSPoints, 1);
        expect(result.teamEWPoints, 0);
      });

      test('handles large advantage (11-2)', () {
        final result = scoreWithTricks(11, 2);
        expect(result.teamNSPoints, 5); // 11 - 6 = 5
        expect(result.teamEWPoints, 0);
      });
    });

    group('mathematical properties', () {
      test('points increase linearly with tricks above 6', () {
        for (int tricks = 7; tricks <= 13; tricks++) {
          final result = scoreWithTricks(tricks, 13 - tricks);
          expect(result.teamNSPoints, tricks - 6);
        }
      });

      test('maximum possible points is 7', () {
        final result = scoreWithTricks(13, 0);
        expect(result.teamNSPoints, 7);
        expect(result.teamNSPoints, lessThanOrEqualTo(7));
      });

      test('book constant is 6', () {
        expect(ClassicWhistScoringEngine.bookSize, 6);
      });

      test('points per odd trick is 1', () {
        expect(ClassicWhistScoringEngine.pointsPerOddTrick, 1);
      });
    });
  });
}
