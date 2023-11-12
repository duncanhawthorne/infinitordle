import 'dart:math';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class Flips {

  double getFlipAngle(abIndex, boardNumber) {
    return max(0, getPermFlipAngle(abIndex) - getFlourishFlipAngle(abIndex) - getFlourishBoardFlipAngle(boardNumber));
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
      return game.abCardFlourishFlipAngles[abRow][i];
    }
  }

  double getFlourishBoardFlipAngle(boardNumber) {
    if (!game.boardFlourishFlipAngles.contains(boardNumber)) {
      return 0;
    } else {
      return 0.5;
    }
  }

}
