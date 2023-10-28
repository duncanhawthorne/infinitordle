import 'dart:math';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class Flips {
  var abCardFlourishFlipAngles = {};

  double getFlipAngle(abIndex) {
    return max(0, getPermFlipAngle(abIndex) - getFlourishFlipAngle(abIndex));
  }

  double getPermFlipAngle(abIndex) {
    int abRow = abIndex ~/ 5;
    if (abRow >= game.getAbCurrentRowInt()) {
      return 0;
    } else {
      return 0.5;
    }
  }

  double getFlourishFlipAngle(abIndex) {
    int abRow = abIndex ~/ 5;
    int i = abIndex % 5;
    if (!abCardFlourishFlipAngles.containsKey(abRow)) {
      return 0;
    } else {
      return abCardFlourishFlipAngles[abRow][i];
    }
  }

  void gradualRevealAbRow(abRow) {
    //int abRow = getABRowFromGBRow(gbRow);
    //flip to reveal the colors with pleasing animation
    for (int i = 0; i < 5; i++) {
      if (!abCardFlourishFlipAngles.containsKey(abRow)) {
        abCardFlourishFlipAngles[abRow] = [0.0, 0.0, 0.0, 0.0, 0.0];
      }
      abCardFlourishFlipAngles[abRow][i] = 0.5;
      Future.delayed(Duration(milliseconds: gradualRevealDelay * i), () {
        abCardFlourishFlipAngles[abRow][i] = 0;
        if (i == 4) {
          abCardFlourishFlipAngles.remove(abRow);
        }
        ss();
      });
    }
  }
}
