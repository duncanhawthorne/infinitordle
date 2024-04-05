import 'dart:math';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class Flips {
  double getFlipAngle(abIndex, boardNumber) {
    int abRow = abIndex ~/ cols;
    double cardFlipAngle =
        getPermFlipAngle(abIndex) - getFlourishFlipAngle(abIndex);
    double boardFlipAngle = 0;
    if (abRow <= game.getAbCurrentRowInt()) {
      //only test this if relevant, to help GetX hack .obs
      boardFlipAngle = getFlourishBoardFlipAngle(boardNumber);
    }
    return max(0, cardFlipAngle - boardFlipAngle);
  }

  double getPermFlipAngle(abIndex) {
    int abRow = abIndex ~/ cols;
    if (abRow >= game.getAbCurrentRowInt()) {
      return 0;
    } else {
      return 0.5;
    }
  }

  double getFlourishFlipAngle(abIndex) {
    int abRow = abIndex ~/ cols;
    int i = abIndex % cols;
    if (!game.abCardFlourishFlipAngles.containsKey(abRow)) {
      return 0;
    } else {
      return game.abCardFlourishFlipAngles[abRow][i].value;
    }
  }

  double getFlourishBoardFlipAngle(boardNumber) {
    if (game.getBoardFlourishFlipAngle(boardNumber) == -1) {
      return 0;
    } else {
      return 0.5;
    }
  }
}
