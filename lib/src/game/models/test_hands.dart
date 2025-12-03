import 'card.dart';

/// Represents a pre-configured test hand scenario for Minnesota Whist.
///
/// Used for testing and debugging specific game situations with known hands.
/// Each scenario provides 13 cards representing a specific strategic situation.
class TestHandScenario {
  const TestHandScenario({
    required this.name,
    required this.description,
    required this.cards,
  });

  /// Name of the test scenario
  final String name;

  /// Description of what this scenario tests
  final String description;

  /// The 13 cards in this test hand
  final List<PlayingCard> cards;
}

/// Collection of pre-configured test hands for Minnesota Whist
class TestHands {
  /// List of all available test scenarios
  static const List<TestHandScenario> scenarios = [
    // Strong high hand (mostly high cards, good for HIGH bid)
    TestHandScenario(
      name: 'High Powerhouse',
      description: 'Strong hand with aces and high cards - bid BLACK (HIGH)',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.clubs),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.jack, suit: Suit.spades),
        PlayingCard(rank: Rank.jack, suit: Suit.diamonds),
        PlayingCard(rank: Rank.ten, suit: Suit.clubs),
        PlayingCard(rank: Rank.nine, suit: Suit.spades),
        PlayingCard(rank: Rank.eight, suit: Suit.hearts),
        PlayingCard(rank: Rank.seven, suit: Suit.clubs),
      ],
    ),

    // Weak low hand (mostly low cards, good for LOW bid)
    TestHandScenario(
      name: 'Low Master',
      description: 'Weak hand with low cards - bid RED (LOW)',
      cards: [
        PlayingCard(rank: Rank.two, suit: Suit.spades),
        PlayingCard(rank: Rank.two, suit: Suit.hearts),
        PlayingCard(rank: Rank.two, suit: Suit.diamonds),
        PlayingCard(rank: Rank.two, suit: Suit.clubs),
        PlayingCard(rank: Rank.three, suit: Suit.spades),
        PlayingCard(rank: Rank.three, suit: Suit.hearts),
        PlayingCard(rank: Rank.four, suit: Suit.diamonds),
        PlayingCard(rank: Rank.four, suit: Suit.clubs),
        PlayingCard(rank: Rank.five, suit: Suit.spades),
        PlayingCard(rank: Rank.five, suit: Suit.hearts),
        PlayingCard(rank: Rank.six, suit: Suit.diamonds),
        PlayingCard(rank: Rank.six, suit: Suit.clubs),
        PlayingCard(rank: Rank.seven, suit: Suit.spades),
      ],
    ),

    // Mixed hand (medium strength)
    TestHandScenario(
      name: 'Balanced Hand',
      description: 'Mixed strength - consider partner and position',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        PlayingCard(rank: Rank.jack, suit: Suit.clubs),
        PlayingCard(rank: Rank.ten, suit: Suit.spades),
        PlayingCard(rank: Rank.nine, suit: Suit.hearts),
        PlayingCard(rank: Rank.eight, suit: Suit.diamonds),
        PlayingCard(rank: Rank.seven, suit: Suit.diamonds),
        PlayingCard(rank: Rank.six, suit: Suit.spades),
        PlayingCard(rank: Rank.five, suit: Suit.clubs),
        PlayingCard(rank: Rank.four, suit: Suit.hearts),
        PlayingCard(rank: Rank.three, suit: Suit.diamonds),
        PlayingCard(rank: Rank.two, suit: Suit.spades),
      ],
    ),

    // Long suit hand (spades powerhouse)
    TestHandScenario(
      name: 'Spades Long',
      description: 'Long spade suit with high cards - strong HIGH bid',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.jack, suit: Suit.spades),
        PlayingCard(rank: Rank.ten, suit: Suit.spades),
        PlayingCard(rank: Rank.nine, suit: Suit.spades),
        PlayingCard(rank: Rank.eight, suit: Suit.spades),
        PlayingCard(rank: Rank.seven, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.jack, suit: Suit.hearts),
        PlayingCard(rank: Rank.ten, suit: Suit.hearts),
      ],
    ),

    // Void suit hand (strategic)
    TestHandScenario(
      name: 'Void Diamonds',
      description: 'No diamonds - can sluff or ruff strategically',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.jack, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        PlayingCard(rank: Rank.king, suit: Suit.clubs),
        PlayingCard(rank: Rank.queen, suit: Suit.clubs),
        PlayingCard(rank: Rank.jack, suit: Suit.clubs),
        PlayingCard(rank: Rank.ten, suit: Suit.clubs),
        PlayingCard(rank: Rank.nine, suit: Suit.clubs),
      ],
    ),

    // All low cards (extreme LOW bid)
    TestHandScenario(
      name: 'Ultra Low',
      description: 'Extremely weak hand - perfect for LOW bid',
      cards: [
        PlayingCard(rank: Rank.two, suit: Suit.spades),
        PlayingCard(rank: Rank.three, suit: Suit.spades),
        PlayingCard(rank: Rank.four, suit: Suit.spades),
        PlayingCard(rank: Rank.five, suit: Suit.spades),
        PlayingCard(rank: Rank.two, suit: Suit.hearts),
        PlayingCard(rank: Rank.three, suit: Suit.hearts),
        PlayingCard(rank: Rank.four, suit: Suit.hearts),
        PlayingCard(rank: Rank.two, suit: Suit.diamonds),
        PlayingCard(rank: Rank.three, suit: Suit.diamonds),
        PlayingCard(rank: Rank.four, suit: Suit.diamonds),
        PlayingCard(rank: Rank.two, suit: Suit.clubs),
        PlayingCard(rank: Rank.three, suit: Suit.clubs),
        PlayingCard(rank: Rank.four, suit: Suit.clubs),
      ],
    ),

    // All high cards (extreme HIGH bid)
    TestHandScenario(
      name: 'Supreme Slam',
      description: 'All high cards - dominant HIGH bid hand',
      cards: [
        PlayingCard(rank: Rank.ace, suit: Suit.spades),
        PlayingCard(rank: Rank.ace, suit: Suit.hearts),
        PlayingCard(rank: Rank.ace, suit: Suit.diamonds),
        PlayingCard(rank: Rank.ace, suit: Suit.clubs),
        PlayingCard(rank: Rank.king, suit: Suit.spades),
        PlayingCard(rank: Rank.king, suit: Suit.hearts),
        PlayingCard(rank: Rank.king, suit: Suit.diamonds),
        PlayingCard(rank: Rank.king, suit: Suit.clubs),
        PlayingCard(rank: Rank.queen, suit: Suit.spades),
        PlayingCard(rank: Rank.queen, suit: Suit.hearts),
        PlayingCard(rank: Rank.queen, suit: Suit.diamonds),
        PlayingCard(rank: Rank.queen, suit: Suit.clubs),
        PlayingCard(rank: Rank.jack, suit: Suit.spades),
      ],
    ),
  ];

  /// Get a test hand by name (case insensitive)
  static TestHandScenario? getByName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return scenarios.firstWhere(
        (scenario) => scenario.name.toLowerCase() == lowerName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a test hand by index
  static TestHandScenario? getByIndex(int index) {
    if (index < 0 || index >= scenarios.length) return null;
    return scenarios[index];
  }
}
