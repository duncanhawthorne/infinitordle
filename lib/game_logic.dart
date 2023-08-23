import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';

void onKeyboardTapped(int index) {
  var ss = globalFunctions[0];
  var showResetConfirmScreen = globalFunctions[1];
  String letter = keyboardList[index];

  cheatPrintTargetWords();

  if (letter == " ") {
    //ignore pressing of non-keys

  } else if (letter == "<") {
    //backspace
    // ignore: prefer_is_empty
    if (currentTyping.length > 0) {
      //typeCountInWord > 0
      currentTyping = currentTyping.substring(0, currentTyping.length - 1);
      ss(); // setState(() {});
    }
  } else if (letter == ">") {
    //submit guess
    if (currentTyping.length == 5) {
      //typeCountInWord == 5
      //&& threadsafeBlockNewWord == false
      //ignore if not completed whole word
      //due to "delay" functions, need to take local copies of various global variable so they are still "right" when the delayed functions run
      String enteredWordLocal = currentTyping;
      if (listContains(legalWords, enteredWordLocal)) {
        //Legal word, but not necessarily correct word

        //Legal word so step forward
        int cardRowPreGuess = getVCurrentRowBeingTypedInt();
        currentTyping = "";

        enteredWords.add(enteredWordLocal);
        //to avoid a race condition with delayed code, add to winRecordBoards immediately as a fail, and then change it later to a win
        winRecordBoards.add(-2);
        int winRecordBoardsIndexToFix = winRecordBoards.length - 1;

        //Made a guess flip over the cards to see the colors
        gradualRevealRow(cardRowPreGuess);

        //Test if it is correct word
        bool isWin = false;
        aboutToWinCache = false;
        int winningBoard = -1; //local variable to ensure threadsafe
        for (var board = 0; board < numBoards; board++) {
          if (targetWords[board] == enteredWordLocal) {
            //(detectBoardSolvedByRow(board, currentWord)) {
            //threadsafeBlockNewWord = true;
            isWin = true;
            aboutToWinCache = true;
            winningBoard = board;
          }
        }

        if (!isWin) {
          //change -2 to -1 to confirm no win
          winRecordBoards[winRecordBoardsIndexToFix] = -1;
        }

        saveKeys();

        //Code for losing game
        if (!isWin && getVCurrentRowBeingTypedInt() >= numRowsPerBoard) {
          //didn't get it in time
          Future.delayed(Duration(milliseconds: gradualRevealDelay * 5 + durMult * 500), () {
            showResetConfirmScreen();
          });
        }

        if (!infMode && isWin) {
          //Code for totally winning game across all boards
          bool totallySolvedLocal = true;
          for (var i = 0; i < numBoards; i++) {
            if (!detectBoardSolvedByRow(i, getVCurrentRowBeingTypedInt())) {
              totallySolvedLocal = false;
            }
          }
          if (totallySolvedLocal) {
            //ScaffoldMessenger.of(context)
            //    .showSnackBar(SnackBar(content: Text(appTitle)));
          }
        }

        if (infMode && isWin) {
          Future.delayed(Duration(milliseconds: delayMult * 1500), () {
            //Give time for above code to show visually, so we have flipped
            //Slide the cards back visually, creating the illusion of stepping back
            visualOffset = 1;
            ss(); //setState(() {});
            Future.delayed(Duration(milliseconds: durMult * 250), () {
              //Undo the visual slide (and do this instantaneously)
              visualOffset = 0;
              //Actually erase a row and step back, so state matches visual illusion above
              oneStepBack();

              ss(); //setState(() {});

              Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                //include inside other future so definitely happens after rather relying on race
                //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                //Log the word just got in success words, which gets green to shown
                logWinAndGetNewWord(winRecordBoardsIndexToFix, winningBoard);
                ss(); //setState(() {});

                if (isStreak()) {
                  Future.delayed(Duration(milliseconds: delayMult * 750), () {
                    if (getVCurrentRowBeingTypedInt() > 0) {
                      //Slide the cards back visually, creating the illusion of stepping back
                      visualOffset = 1;
                      ss(); //setState(() {});
                      Future.delayed(Duration(milliseconds: durMult * 250), () {
                        //Undo the visual slide (and do this instantaneously)
                        visualOffset = 0;
                        //Actually erase a row and step back, so state matches visual illusion above
                        oneStepBack();

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
    } else {
      //not 5 letters long so ignore
    }
  } else if (true) {
    //pressing regular key, as other options already dealt with above
    if (currentTyping.length < 5) {
      //&& getVisualCurrentRowInt() < numRowsPerBoard
      //still typing out word, else ignore
      currentTyping = currentTyping + letter;
      ss(); //setState(() {});
    }
  }
//    });
}

void gradualRevealRow(row) {
  //flip to reveal the colors with pleasing animation
  var ss = globalFunctions[0];
  //var gradualRevealDelay = delayMult * (durMult == 1 ? 100 : 250);
  for (int i = 0; i < 5; i++) {
    //delayedFlipOnCard(row, i);
    Future.delayed(Duration(milliseconds: gradualRevealDelay * i), () {
      if (getCardLetterAtVIndex(row * 5 + i) != "") {
        //if have stepped back during delay may end up flipping wrong card so do this safety test
        flipCard(row * 5 + i, "f");
        ss(); // setState(() {});
      }
    });
  }
}
