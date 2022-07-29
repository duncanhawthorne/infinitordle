import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';

void onKeyboardTapped(int index) {
  var ss = globalFunctions[0];
  var showResetConfirmScreen = globalFunctions[1];

  cheatPrintTargetWords();

  if (keyboardList[index] == " ") {
    //ignore pressing of non-keys

  } else if (keyboardList[index] == "<") {
    //backspace
    // ignore: prefer_is_empty
    if (currentTyping.length > 0) {
      //typeCountInWord > 0
      currentTyping = currentTyping.substring(0, currentTyping.length - 1);
      ss(); // setState(() {});
    }
  } else if (keyboardList[index] == ">") {
    //submit guess
    if (currentTyping.length == 5) {
      //typeCountInWord == 5
      //&& threadsafeBlockNewWord == false
      //ignore if not completed whole word
      String enteredWordLocal =
          currentTyping; //local variable to ensure threadsafe
      if (quickIn(legalWords, enteredWordLocal)) {
        //Legal word, but not necessarily correct word

        //Legal word so step forward
        int visualCurrentRowIntLocalPreGuess = getVisualCurrentRowInt();
        currentTyping = "";

        enteredWords.add(enteredWordLocal);
        winRecordBoards.add(
            -1); //to avoid a race condition with delayed code, add this immediately, and then change it later
        int masterEnteredWordPositionLocalAfterGuess = winRecordBoards.length;

        saveKeys();

        //Made a guess flip over the cards to see the colors
        for (int i = 0; i < 5; i++) {
          delayedFlipOnAbsoluteCard(visualCurrentRowIntLocalPreGuess, i, "f", ss);
        }

        //Test if it is correct word
        bool oneMatchingWordLocal = false;
        oneMatchingWordForResetScreenCache = false;
        int oneMatchingWordBoardLocal =
            -1; //local variable to ensure threadsafe
        for (var board = 0; board < numBoards; board++) {
          if (targetWords[board] == enteredWordLocal) {
            //(detectBoardSolvedByRow(board, currentWord)) {
            //threadsafeBlockNewWord = true;
            oneMatchingWordLocal = true;
            oneMatchingWordForResetScreenCache = true;
            oneMatchingWordBoardLocal = board;
          }
        }

        //Code for losing game
        if (!oneMatchingWordLocal &&
            getVisualCurrentRowInt() >= numRowsPerBoard) {
          //didn't get it in time
          showResetConfirmScreen();
        }

        if (!infMode && oneMatchingWordLocal) {
          //Code for totally winning game across all boards
          bool totallySolvedLocal = true;
          for (var i = 0; i < numBoards; i++) {
            if (!detectBoardSolvedByRow(i, getVisualCurrentRowInt())) {
              totallySolvedLocal = false;
            }
          }
          if (totallySolvedLocal) {
            //ScaffoldMessenger.of(context)
            //    .showSnackBar(SnackBar(content: Text(appTitle)));
          }
        }

        if (infMode && oneMatchingWordLocal) {
          Future.delayed(Duration(milliseconds: delayMult * 1500), () {
            //Give time for above code to show visually, so we have flipped
            //Slide the cards back visually, creating the illusion of stepping back
            visualOneStepState = 1;
            ss(); //setState(() {});
            Future.delayed(Duration(milliseconds: durMult * 250), () {
              //Undo the visual slide (and do this instantaneously)
              visualOneStepState = 0;
              //Actually erase a row and step back, so state matches visual illusion above
              oneStepBack(visualCurrentRowIntLocalPreGuess);

              ss(); //setState(() {});

              Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                //include inside other future so definitely happens after rather relying on race
                //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                //Log the word just got in success words, which gets green to shown
                logWinAndGetNewWord(
                    masterEnteredWordPositionLocalAfterGuess, oneMatchingWordBoardLocal);
                ss(); //setState(() {});

                if (isStreak()) {
                  Future.delayed(Duration(milliseconds: delayMult * 750), () {
                    if (getVisualCurrentRowInt() > 0) {
                      //Slide the cards back visually, creating the illusion of stepping back
                      visualOneStepState = 1;
                      ss(); //setState(() {});
                      Future.delayed(Duration(milliseconds: durMult * 250), () {
                        //Undo the visual slide (and do this instantaneously)
                        visualOneStepState = 0;
                        //Actually erase a row and step back, so state matches visual illusion above
                        oneStepBack(visualCurrentRowIntLocalPreGuess);

                        ss(); //setState(() {});
                      });
                    }
                  });
                }
              });
            });
          });
        }
      } else {
        //not a legal word so do nothing
        /*
        //not a legal word so clear text
        currentTyping = "";
        ss(); //setState(() {});
         */
      }
    }
  } else if (true) {
    //pressing regular key, as other options already dealt with above
    if (currentTyping.length < 5 &&
        getVisualCurrentRowInt() < numRowsPerBoard) {
      //still typing out word, else ignore
      currentTyping = currentTyping + keyboardList[index];
      ss(); //setState(() {});
    }
  }
//    });
}

void delayedFlipOnAbsoluteCard(
    int getVisualCurrentRowIntLocal, int i, toFOrB, ss) {
  Future.delayed(
      Duration(milliseconds: delayMult * i * (durMult == 1 ? 100 : 250)), () {
    if (getVisualGBLetterAtIndexEntered(
            (getVisualCurrentRowIntLocal) * 5 + i) !=
        "") {
      //if have stepped back during delay may end up flipping wrong card so do this safety test
      //flip to reveal the colors with pleasing animation
      flipCardReal((getVisualCurrentRowIntLocal) * 5 + i, toFOrB);
      ss(); // setState(() {});
    }
  });
}
