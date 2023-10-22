import 'package:infinitordle/constants.dart';
import 'package:infinitordle/game_logic.dart';

class Flips {

  var cardFlipAngles =
  List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);

  double getFlipAngle(index) {
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
    for (var j = 0; j < numRowsPerBoard * 5; j++) {
      if (game.getVisualCurrentRowInt() > (j ~/ 5)) {
        flipCard(j, "f");
      } else {
        flipCard(j, "b");
      }
    }
  }

  void flipCard(index, toFOrB) {
    if (toFOrB == "b") {
      cardFlipAngles[index] = 0;
    } else {
      cardFlipAngles[index] = 0.5;
    }
  }

}

Flips flips = Flips();