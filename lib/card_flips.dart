import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class Flips {
  var cardFlipAngles = List<double>.generate(
      (game.getLiveNumRowsPerBoard() * 5 * numBoards), (i) => 0);

  double getFlipAngle(index) {
    if (index >= cardFlipAngles.length) {
      p("getFlipAngle reset");
      p([game.getLiveNumRowsPerBoard() * 5 * numBoards, index]);
      initiateFlipState();
      return 0;
    }
    return cardFlipAngles[index];
  }

  void gradualRevealRow(row) {
    //flip to reveal the colors with pleasing animation
    //var ss = globalFunctions[0];
    //var gradualRevealDelay = delayMult * (durMult == 1 ? 100 : 250);
    for (int i = 0; i < 5; i++) {
      //delayedFlipOnCard(row, i);
      Future.delayed(Duration(milliseconds: gradualRevealDelay * i), () {
        if (game.getCardLetterAtIndex(row * 5 + i) != "") {
          //if have stepped back during delay may end up flipping wrong card so do this safety test
          flipCard(row * 5 + i, "f");
          ss(); // setState(() {});
        }
      });
    }
  }

  void initiateFlipState() {
    cardFlipAngles = List<double>.generate(
        (game.getLiveNumRowsPerBoard() * 5 * numBoards), (i) => 0);
    for (var j = 0; j < game.getLiveNumRowsPerBoard() * 5; j++) {
      if (game.getVisualCurrentRowInt() > (j ~/ 5)) {
        flipCard(j, "f");
      } else {
        flipCard(j, "b");
      }
    }
    //ap(cardFlipAngles);
  }

  void flipCard(index, toFOrB) {
    if (index >= cardFlipAngles.length) {
      initiateFlipState();
    }
    if (toFOrB == "b") {
      cardFlipAngles[index] = 0;
    } else {
      cardFlipAngles[index] = 0.5;
    }
  }
}


