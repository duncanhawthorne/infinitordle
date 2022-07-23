import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';

void onKeyboardTapped(int index) {
  var ss = globalFunctions[0];
  var showResetConfirmScreen = globalFunctions[1];

  cheatPrintTargetWords();

  //p([enteredWords, currentTyping, offsetRollback, winRecordBoards]);

  //print(gUser);

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
          currentTyping; // gameboardEntries.sublist(currentWord * 5, (currentWord + 1) * 5).join(""); //local variable to ensure threadsafe
      if (quickIn(legalWords, enteredWordLocal)) {
        //(legalWords.contains(enteredWordLocal)) {
        //Legal word, but not necessarily correct word

        //Legal word so step forward
        resetColorsCache();
        int getVisualCurrentRowIntLocal = getVisualCurrentRowInt();
        currentTyping = "";

        enteredWords.add(enteredWordLocal);
        winRecordBoards.add(
            -1); //to avoid a race condition with delayed code, add this immediately, and then change it later
        int masterEnteredWordPositionLocal = winRecordBoards.length;

        if (onStreakForKeyboardIndicatorCache) {
          //purely for the visual indicator on the return key. Test this every legal word, rather than every correct word
          onStreakForKeyboardIndicatorCache = streak();
        }

        saveKeys();

        //Made a guess flip over the cards to see the colors
        for (int i = 0; i < 5; i++) {
          delayedFlipOnAbsoluteCard(getVisualCurrentRowIntLocal, i, "f", ss);
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
            oneStepState = 1;
            ss(); //setState(() {});
            Future.delayed(Duration(milliseconds: durMult * 250), () {
              //Undo the visual slide (and do this instantaneously)
              oneStepState = 0;
              //Actually erase a row and step back, so state matches visual illusion above
              oneStepBack(getVisualCurrentRowIntLocal);

              ss(); //setState(() {});

              Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                //include inside other future so definitely happens after rather relying on race
                //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                //Log the word just got in success words, which gets green to shown
                logWinAndGetNewWord(
                    masterEnteredWordPositionLocal, oneMatchingWordBoardLocal);
                ss(); //setState(() {});

                if (streak()) {
                  Future.delayed(Duration(milliseconds: delayMult * 750), () {
                    if (getVisualCurrentRowInt() > 0) {
                      //Slide the cards back visually, creating the illusion of stepping back
                      oneStepState = 1;
                      ss(); //setState(() {});
                      Future.delayed(Duration(milliseconds: durMult * 250), () {
                        //Undo the visual slide (and do this instantaneously)
                        oneStepState = 0;
                        //Actually erase a row and step back, so state matches visual illusion above
                        oneStepBack(getVisualCurrentRowIntLocal);

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
        //not a legal word so just clear current word
        currentTyping = "";
        ss(); //setState(() {});
      }
    }
  } else if (true) {
    //pressing regular key, as other options already dealt with above
    if (currentTyping.length < 5 &&
        getVisualCurrentRowInt() < numRowsPerBoard) {
      //typeCountInWord < 5
      //still typing out word, else ignore
      currentTyping = currentTyping + keyboardList[index];

      //doing this once rather than live inside the widget for speed
      oneLegalWordForRedCardsCache = false;
      if (currentTyping.length == 5) {
        //typeCountInWord == 5
        //ignore if not completed whole word
        if (quickIn(legalWords, currentTyping)) {
          //gameboardEntries.sublist(currentWord * 5, (currentWord + 1) * 5).join("")
          // (legalWords.contains(gameboardEntries.sublist(currentWord * 5, (currentWord + 1) * 5).join(""))) {
          oneLegalWordForRedCardsCache = true;
        }
      }
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
