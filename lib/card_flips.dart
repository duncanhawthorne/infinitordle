import 'dart:math';

import 'constants.dart';
import 'game_logic.dart';
import 'game_orchestrator.dart';

/// Manages the flip animations and states for cards on the game boards.
class Flips {
  Flips({required this.game});

  final Game game;

  /// Calculates the current flip angle (in 0.0-1.0 range) for a specific card.
  /// [abIndex] is the absolute card index, [boardNumber] identifies the board.
  double getFlipAngle(int abIndex, int boardNumber) {
    final int abRow = abIndex ~/ cols;
    final double cardFlipAngle =
        _getPermFlipAngle(abIndex) - _getFlourishFlipAngle(abIndex);
    final double boardFlipAngle =
        abRow <= gameS.abCurrentRowInt
            ? _getFlourishBoardFlipAngle(boardNumber)
            : 0;
    return max(0, cardFlipAngle - boardFlipAngle);
  }

  /// Returns 0.5 (flipped) if the row has been entered, otherwise 0.
  double _getPermFlipAngle(int abIndex) {
    final int abRow = abIndex ~/ cols;
    return abRow >= gameS.abCurrentRowInt ? 0 : 0.5;
  }

  /// Retrieves the temporary flourish flip angle from the game logic notifier.
  double _getFlourishFlipAngle(int abIndex) {
    final int abRow = abIndex ~/ cols;
    final int col = abIndex % cols;
    if (!game.abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
      return 0;
    } else {
      return game.abCardFlourishFlipAnglesNotifier.value[abRow]![col];
    }
  }

  /// Returns 0.5 if the entire board is undergoing a flourish flip, otherwise 0.
  double _getFlourishBoardFlipAngle(int boardNumber) {
    return game.getBoardFlourishFlipRow(boardNumber) == -1 ? 0 : 0.5;
  }
}

/// Global instance of [Flips] to be used across the app.
final Flips flips = Flips(game: game);
