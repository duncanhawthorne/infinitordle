import 'dart:math';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class Flips {
  var abCardFlourishFlipAngles = {};

  double getFlipAngle(abIndex) {
    return max(0, getPermFlipAngle(abIndex) - getFlourishFlipAngle(abIndex));
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
    if (!abCardFlourishFlipAngles.containsKey(abRow)) {
      return 0;
    } else {
      return abCardFlourishFlipAngles[abRow][i];
    }
  }

  void gradualRevealAbRow(abRow) {
    // flip to reveal the colors with pleasing animation
    for (int i = 0; i < cols; i++) {
      if (!abCardFlourishFlipAngles.containsKey(abRow)) {
        abCardFlourishFlipAngles[abRow] = List.filled(cols, 0.0);
      }
      abCardFlourishFlipAngles[abRow][i] = 0.5;
      Future.delayed(Duration(milliseconds: gradualRevealDelay * i), () {
        abCardFlourishFlipAngles[abRow][i] = 0.0;
        if (i == cols - 1) {
          abCardFlourishFlipAngles.remove(abRow);
        }
        ss();
      });
    }
  }
}
