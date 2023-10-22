import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

import 'dart:math';
import 'dart:convert';
import 'package:infinitordle/saves.dart';
import 'package:infinitordle/card_colors.dart';
import 'package:infinitordle/card_flips.dart';

class Game {
  var targetWords = []; //gets overridden by loadKeys()
  var enteredWords = [];
  var winRecordBoards = [];
  var currentTyping = "";
  int offsetRollback = 0;

  bool aboutToWinCache = false;

  void onKeyboardTapped(int index) {
    //var ss = globalFunctions[0];
    //var showResetConfirmScreen = globalFunctions[1];
    String letter = keyboardList[index];

    printCheatTargetWords();

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
        if (isListContains(legalWords, enteredWordLocal)) {
          //Legal word, but not necessarily correct word

          //Legal word so step forward
          int cardRowPreGuess = getVisualCurrentRowInt();
          currentTyping = "";

          enteredWords.add(enteredWordLocal);
          //to avoid a race condition with delayed code, add to winRecordBoards immediately as a fail, and then change it later to a win
          winRecordBoards.add(-2);
          int winRecordBoardsIndexToFix = winRecordBoards.length - 1;

          //Made a guess flip over the cards to see the colors
          flips.gradualRevealRow(cardRowPreGuess);

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

          save.saveKeys();

          //Code for losing game
          if (!isWin && getVisualCurrentRowInt() >= numRowsPerBoard) {
            //didn't get it in time
            Future.delayed(
                Duration(milliseconds: gradualRevealDelay * 5 + durMult * 500),
                () {
              showResetConfirmScreen();
            });
          }

          if (!infMode && isWin) {
            //Code for totally winning game across all boards
            bool totallySolvedLocal = true;
            for (var i = 0; i < numBoards; i++) {
              if (!getDetectBoardSolvedByRow(i, getVisualCurrentRowInt())) {
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
              temporaryVisualOffsetForSlide = 1;
              ss(); //setState(() {});
              Future.delayed(Duration(milliseconds: durMult * 250), () {
                //Undo the visual slide (and do this instantaneously)
                temporaryVisualOffsetForSlide = 0;
                //Actually erase a row and step back, so state matches visual illusion above
                takeOneStepBack();

                ss(); //setState(() {});

                Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                  //include inside other future so definitely happens after rather relying on race
                  //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                  //Log the word just got in success words, which gets green to shown
                  logWinAndSetNewWord(winRecordBoardsIndexToFix, winningBoard);
                  ss(); //setState(() {});

                  if (getIsStreak()) {
                    Future.delayed(Duration(milliseconds: delayMult * 750), () {
                      if (getVisualCurrentRowInt() > 0) {
                        //Slide the cards back visually, creating the illusion of stepping back
                        temporaryVisualOffsetForSlide = 1;
                        ss(); //setState(() {});
                        Future.delayed(Duration(milliseconds: durMult * 250),
                            () {
                          //Undo the visual slide (and do this instantaneously)
                          temporaryVisualOffsetForSlide = 0;
                          //Actually erase a row and step back, so state matches visual illusion above
                          takeOneStepBack();

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

  void takeOneStepBack() {
    //Erase a row and step back
    for (var j = 0; j < infNumBacksteps; j++) {
      //Reverse flip the card on the next row back to backside (after earlier having flipped them the right way)
      offsetRollback++;
      //for (var j = 0; j < 5; j++) {
      //  flipCard(getVisualCurrentRowInt() * 5 + j, "b");
      //}
    }
    flips.initiateFlipState(); //in case anything is in the wrong state, fix here
    save.saveKeys();
  }

  void logWinAndSetNewWord(winRecordBoardsIndexToFix, winningBoard) {
    //Log the word just got in success words, which gets green to show
    //Fix the fact that we stored a -1 in this place temporarily
    winRecordBoards[winRecordBoardsIndexToFix] = winningBoard;
    //Create new target word for the board
    targetWords[winningBoard] = getTargetWord();
    save.saveKeys();
  }

  void resetBoard(save) {
    p("Reset board");
    //initialise on reset
    enteredWords = [];
    currentTyping = "";
    offsetRollback = 0;
    winRecordBoards = [];

    targetWords = getTargetWords(numBoards);

    //speed initialise entries using cheat mode for debugging
    if (cheatMode) {
      for (var j = 0; j < numBoards; j++) {
        if (cheatTargetWordsInitial.length > j) {
          targetWords[j] = cheatTargetWordsInitial[j];
        } else {
          targetWords[j] = getTargetWord();
        }
      }
      for (var j = 0; j < cheatEnteredWordsInitial.length; j++) {
        enteredWords.add(cheatEnteredWordsInitial[j]);
        winRecordBoards.add(-1);
      }
    }

    flips.initiateFlipState();

    if (save) {
      p("Reset board called with instruction to save keys, and now saving keys");
      save.saveKeys();
    } else {
      //only runs at startup
      saveOrLoadKeysCountCache++;
    }
  }

  String getCardLetterAtIndex(index) {
    int rowOfIndex = index ~/ 5;
    try {
      String letter = "";
      if (rowOfIndex > getVisualCurrentRowInt()) {
        letter = "";
      } else if (rowOfIndex == getVisualCurrentRowInt()) {
        if (currentTyping.length > (index % 5)) {
          letter = currentTyping.substring(index % 5, (index % 5) + 1);
        } else {
          letter = "";
        }
      } else {
        letter = enteredWords[index ~/ 5 + offsetRollback][index % 5];
      }
      return letter;
    } catch (e) {
      p(["getVisualGBLetterAtIndexEntered", index, e]);
      return "";
    }
  }

  bool getTestHistoricalWin(rowOfIndex, boardNumber) {
    if (rowOfIndex + offsetRollback > 0 &&
        winRecordBoards.length > rowOfIndex + offsetRollback &&
        winRecordBoards[rowOfIndex + offsetRollback] == boardNumber) {
      return true;
    }
    return false;
  }

  List getWinWords() {
    var log = [];
    for (var i = 0; i < winRecordBoards.length; i++) {
      if (winRecordBoards[i] != -1) {
        log.add(enteredWords[i]);
      }
    }
    return log;
  }

  bool onStreakCache = false;
  int onStreakTestedStateCache = 0;
  bool getIsStreak() {
    if (onStreakTestedStateCache == saveOrLoadKeysCountCache) {
      return onStreakCache;
    } else {
      //blank the cache
      onStreakTestedStateCache = saveOrLoadKeysCountCache;
      onStreakCache = false;
    }

    bool isStreak = true;

    if (winRecordBoards.isEmpty) {
      isStreak = false;
    } else {
      for (int q = 0; q < 3; q++) {
        if (winRecordBoards.length - 1 - q < 0 ||
            winRecordBoards[winRecordBoards.length - 1 - q] != -1) {
          isStreak = true;
        } else {
          isStreak = false;
          break;
        }
      }
    }
    onStreakCache = isStreak;

    return isStreak;
  }

  int getVisualCurrentRowInt() {
    return enteredWords.length - offsetRollback;
  }

  String getCurrentTyping() {
    return currentTyping;
  }

  String getTargetWordForBoard(boardNumber) {
    return targetWords[boardNumber];
  }

  bool getDetectBoardSolvedByRow(boardNumber, maxRowToCheck) {
    for (var q = 0; q < min(getVisualCurrentRowInt(), maxRowToCheck); q++) {
      bool result = true;
      for (var j = 0; j < 5; j++) {
        if (cardColors.getCardColor(q * 5 + j, boardNumber) != green) {
          result = false;
        }
      }
      if (result) {
        return true;
      }
    }
    return false;
  }

  void loadFromEncodedState(gameEncoded) {
    //print("loadKeysReal"+gameEncoded);
    if (gameEncoded == "") {
      //first time through or error state
      //print("ge empty");
      //resetBoardReal(true);
    } else if (gameEncoded != gameEncodedLast) {
      try {
        Map<String, dynamic> gameTmp = {};
        gameTmp = json.decode(gameEncoded);

        String tmpgUser = gameTmp["gUser"] ?? "Default";
        if (tmpgUser != gUser && tmpgUser != "Default") {
          //print("redoing load keys");
          //Error state, so set gUser properly and redo loadKeys from firebase
          gUser = tmpgUser;
          save.loadKeys();
          return;
        }

        targetWords = gameTmp["targetWords"] ?? getTargetWords(numBoards);

        enteredWords = gameTmp["enteredWords"] ?? [];
        offsetRollback = gameTmp["offsetRollback"] ?? 0;
        winRecordBoards = gameTmp["winRecordBoards"] ?? [];
      } catch (error) {
        p(["ERROR", error]);
        //resetBoardReal(true);
      }
      flips.initiateFlipState();
      gameEncodedLast = gameEncoded;
      saveOrLoadKeysCountCache++;
    }
  }

  String getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["targetWords"] = targetWords;
    gameTmp["gUser"] = gUser;

    gameTmp["enteredWords"] = enteredWords;
    gameTmp["offsetRollback"] = offsetRollback;
    gameTmp["winRecordBoards"] = winRecordBoards;

    return json.encode(gameTmp);
  }

  void printCheatTargetWords() {
    if (cheatMode) {
      // ignore: avoid_print
      p([
        targetWords,
        enteredWords,
        winRecordBoards,
        currentTyping,
        offsetRollback
      ]);
    }
  }

  bool getAboutToWinCache() {
    return aboutToWinCache;
  }

}

Game game = Game();
