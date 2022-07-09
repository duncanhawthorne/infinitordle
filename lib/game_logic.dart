import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';

void onKeyboardTapped(int index) {
  var ss = globalFunctions[0];
  var showResetConfirmScreen = globalFunctions[1];

  cheatPrintTargetWords();
  //print(gUser);

  if (keyboardList[index] == " ") {
    //ignore pressing of non-keys

  } else if (keyboardList[index] == "<") {
    //backspace
    if (typeCountInWord > 0) {
      typeCountInWord--;
      gameboardEntries[currentWord * 5 + typeCountInWord] = "";
      ss(); // setState(() {});
    }
  } else if (keyboardList[index] == ">") {
    //submit guess
    if (typeCountInWord == 5) {
      //&& threadsafeBlockNewWord == false
      //ignore if not completed whole word
      String enteredWordLocal = gameboardEntries
          .sublist(currentWord * 5, (currentWord + 1) * 5)
          .join(""); //local variable to ensure threadsafe
      if (quickIn(legalWords, enteredWordLocal)) {
        //(legalWords.contains(enteredWordLocal)) {
        //Legal word, but not necessarily correct word

        //Legal word so step forward
        resetColorsCache();
        currentWord++;
        int currentWordLocal = currentWord;
        typeCountInWord = 0;

        if (onStreakForKeyboardIndicatorCache) {
          //purely for the visual indicator on the return key. Test this every legal word, rather than every correct word
          onStreakForKeyboardIndicatorCache = streak();
        }

        saveKeys();

        //Made a guess flip over the cards to see the colors
        for (int i = 0; i < 5; i++) {
          //delayedFlipOnAbsoluteCard(currentWordLocal.toInt(), i, "f");
          Future.delayed(
              Duration(milliseconds: delayMult * i * (durMult == 1 ? 100 : 250)), () {
            //flip to reveal the colors with pleasing animation
            flipCardReal((currentWordLocal.toInt() - 1) * 5 + i, "f");
            ss(); //setState(() {});
          });
        }

        //Test if it is correct word
        bool oneMatchingWordLocal = false;
        oneMatchingWordForResetScreenCache = false;
        int oneMatchingWordBoardLocal =
        -1; //local variable to ensure threadsafe
        for (var board = 0; board < numBoards; board++) {
          if (detectBoardSolvedByRow(board, currentWord)) {
            //threadsafeBlockNewWord = true;
            oneMatchingWordLocal = true;
            oneMatchingWordForResetScreenCache = true;
            oneMatchingWordBoardLocal = board;
          }
        }

        //Code for losing game
        if (!oneMatchingWordLocal && currentWord >= numRowsPerBoard) {
          //didn't get it in time
          showResetConfirmScreen();
        }

        if (!infMode && oneMatchingWordLocal) {
          //Code for totally winning game across all boards
          bool totallySolvedLocal = true;
          for (var i = 0; i < numBoards; i++) {
            if (!detectBoardSolvedByRow(i, currentWord)) {
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
              //Undo the visual slide (and do this instanteously)
              oneStepState = 0;
              //Actually erase a row and step back, so state matches visual illusion above
              oneStepBack(currentWordLocal);
              ss(); //setState(() {});

              Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                //include inside other future so definitely happens after rather relying on race
                //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                //Log the word just got in success words, which gets green to shown
                logWinAndGetNewWord(
                    enteredWordLocal, oneMatchingWordBoardLocal);
                ss(); //setState(() {});

                if (streak()) {
                  Future.delayed(Duration(milliseconds: delayMult * 750), () {
                    if (currentWord > 0) {
                      //Slide the cards back visually, creating the illusion of stepping back
                      oneStepState = 1;
                      ss(); //setState(() {});
                      Future.delayed(Duration(milliseconds: durMult * 250),
                              () {
                            //Undo the visual slide (and do this instanteously)
                            oneStepState = 0;
                            //Actually erase a row and step back, so state matches visual illusion above
                            oneStepBack(currentWordLocal);
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
        for (var i = 0; i < 5; i++) {
          gameboardEntries[currentWord * 5 + i] = "";
        }
        typeCountInWord = 0;
        ss(); //setState(() {});
      }
    }
  } else if (true) {
    //pressing regular key, as other options already dealt with above
    if (typeCountInWord < 5 && currentWord < numRowsPerBoard) {
      //still typing out word, else ignore
      gameboardEntries[currentWord * 5 + typeCountInWord] =
      keyboardList[index];
      typeCountInWord++;

      //doing this once rather than live inside the widget for speed
      oneLegalWordForRedCardsCache = false;
      if (typeCountInWord == 5) {
        //ignore if not completed whole word
        if (quickIn(
            legalWords,
            gameboardEntries
                .sublist(currentWord * 5, (currentWord + 1) * 5)
                .join(""))) {
          // (legalWords.contains(gameboardEntries.sublist(currentWord * 5, (currentWord + 1) * 5).join(""))) {
          oneLegalWordForRedCardsCache = true;
        }
      }
      ss(); //setState(() {});
    }
  }
//    });
}