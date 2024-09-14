import 'dart:math';

import 'constants.dart';
import 'game_logic.dart';

class Flips {
  Flips({required this.game});

  final Game game;

  double getFlipAngle(int abIndex, int boardNumber) {
    int abRow = abIndex ~/ cols;
    double cardFlipAngle =
        _getPermFlipAngle(abIndex) - _getFlourishFlipAngle(abIndex);
    double boardFlipAngle = 0;
    if (abRow <= game.abCurrentRowInt) {
      boardFlipAngle = _getFlourishBoardFlipAngle(boardNumber);
    }
    return max(0, cardFlipAngle - boardFlipAngle);
  }

  double _getPermFlipAngle(int abIndex) {
    int abRow = abIndex ~/ cols;
    return abRow >= game.abCurrentRowInt ? 0 : 0.5;
  }

  double _getFlourishFlipAngle(int abIndex) {
    int abRow = abIndex ~/ cols;
    int col = abIndex % cols;
    if (!game.abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
      return 0;
    } else {
      return game.abCardFlourishFlipAnglesNotifier.value[abRow]![col];
    }
  }

  double _getFlourishBoardFlipAngle(int boardNumber) {
    return game.getBoardFlourishFlipRow(boardNumber) == -1 ? 0 : 0.5;
  }
}

final Flips flips = Flips(game: game);
