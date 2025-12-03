# Minnesota Whist

A Flutter implementation of the classic Minnesota Whist card game.

## About Minnesota Whist

Minnesota Whist is a partnership trick-taking card game for four players using a standard 52-card deck. The game features a unique bidding system where players simultaneously place one card face-down to indicate whether their team will attempt to win (HIGH bid - black card) or lose (LOW bid - red card) tricks.

### Key Features

- **52-Card Standard Deck**: Uses a complete 2-Ace deck in all four suits
- **Unique Bidding System**: Players bid by placing a black (♠♣) or red (♥♦) card face-down
  - Black card = HIGH bid (team tries to win as many tricks as possible)
  - Red card = LOW bid (team tries to lose as many tricks as possible)
- **Partnership Play**: North-South vs East-West teams
- **13 Tricks Per Hand**: Each player receives 13 cards
- **First to 13 Points Wins**: Quick, strategic gameplay

### How to Play

1. **Deal**: Each player receives 13 cards from a 52-card deck
2. **Bidding**: All players simultaneously select one card from their hand to indicate their bid:
   - Black card (spades/clubs) = HIGH - your team wants to win tricks
   - Red card (hearts/diamonds) = LOW - your team wants to lose tricks
   - The bid card is removed from your hand for the round
3. **Partnership Formation**:
   - If bids split 3-1, the lone bidder plays solo (becomes dummy)
   - If all 4 bid the same color, no hand is played
4. **Play**: The granding team (majority bidders) leads first
5. **Scoring**: Teams score points based on tricks won/lost relative to their bid
6. **Win Condition**: First team to reach 13 points wins the game

## Getting Started

This is a Flutter application. To run it:

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Minnesota Whist Rules (Wikipedia)](https://en.wikipedia.org/wiki/Minnesota_whist)
- [Minnesota Whist Rules (Pagat)](https://www.pagat.com/whist/minwhist.html)

## License

This project is open source and available under the MIT License.
