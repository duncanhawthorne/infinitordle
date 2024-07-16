import 'dart:math';

import 'constants.dart';
import 'helper.dart';

class Flips {
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
    if (abRow >= game.abCurrentRowInt) {
      return 0;
    } else {
      return 0.5;
    }
  }

  double _getFlourishFlipAngle(int abIndex) {
    int abRow = abIndex ~/ cols;
    int i = abIndex % cols;
    if (!game.abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
      return 0;
    } else {
      return game.abCardFlourishFlipAnglesNotifier.value[abRow]![i];
    }
  }

  double _getFlourishBoardFlipAngle(int boardNumber) {
    if (game.getBoardFlourishFlipRow(boardNumber) == -1) {
      return 0;
    } else {
      return 0.5;
    }
  }
}
