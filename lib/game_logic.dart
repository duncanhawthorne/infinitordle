import 'dart:math';
import 'dart:convert';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/google_logic.dart';

class Game {
  //State to save
  List<dynamic> targetWords = ["x"]; //gets overridden by loadKeys()
  List<dynamic> enteredWords = ["x"];
  List<dynamic> winRecordBoards = [-1];
  var currentTyping = "x";
  List<dynamic> firstKnowledge = ["x"];
  int pushUpSteps = -1;
  bool expandingBoard = false;
  bool expandingBoardEver = false;

  void initiateBoard() {
    targetWords = getNewTargetWords(numBoards);
    enteredWords = [];
    winRecordBoards = [];
    currentTyping = "";
    firstKnowledge = getBlankFirstKnowledge(numBoards);
    pushUpSteps = 0;
    expandingBoard = false;
    expandingBoardEver = false;
    if (cheatMode) {
      cheatInitiate();
    }
  }

  //Other state
  bool aboutToWinCache = false;
  int temporaryVisualOffsetForSlide = 0;
  String gameEncodedLast = "";
  int highlightedBoard = -1;

  void onKeyboardTapped(int index) {
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
        if (isLegalWord(enteredWordLocal)) {
          //Legal word, but not necessarily correct word

          //Legal word so step forward
          int cardAbRowPreGuess = getAbCurrentRowInt();
          currentTyping = "";

          enteredWords.add(enteredWordLocal);
          //to avoid a race condition with delayed code, add to winRecordBoards immediately as a fail, and then change it later to a win
          winRecordBoards.add(-2);
          int winRecordBoardsIndexToFix = winRecordBoards.length - 1;

          //Made a guess flip over the cards to see the colors
          flips.gradualRevealAbRow(cardAbRowPreGuess);

          //Test if it is correct word
          bool isWin = false;
          aboutToWinCache = false;
          int winningBoard = -1; //local variable to ensure threadsafe
          for (var board = 0; board < numBoards; board++) {
            if (getTargetWordForBoard(board) == enteredWordLocal) {
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
          if (!isWin && getAbCurrentRowInt() >= getAbLiveNumRowsPerBoard()) {
            //didn't get it in time
            Future.delayed(
                const Duration(
                    milliseconds: gradualRevealDelay * 5 + durMult * 500), () {
              showResetConfirmScreen();
            });
          }

          if (!infMode && isWin) {
            //Code for totally winning game across all boards
            bool totallySolvedLocal = true;
            for (var i = 0; i < numBoards; i++) {
              if (!getDetectBoardSolvedByABRow(i, getAbCurrentRowInt())) {
                totallySolvedLocal = false;
              }
            }
            if (totallySolvedLocal) {
              //ScaffoldMessenger.of(context)
              //    .showSnackBar(SnackBar(content: Text(appTitle)));
            }
          }

          if (infMode && isWin) {
            Future.delayed(const Duration(milliseconds: delayMult * 1500), () {
              //Give time for above code to show visually, so we have flipped
              //Slide the cards back visually, creating the illusion of stepping back
              temporaryVisualOffsetForSlide = 1;
              ss(); //setState(() {});
              Future.delayed(const Duration(milliseconds: durMult * 250), () {
                //Undo the visual slide (and do this instantaneously)
                temporaryVisualOffsetForSlide = 0;
                //Actually erase a row and step back, so state matches visual illusion above
                takeOneStepBack();

                ss(); //setState(() {});

                Future.delayed(const Duration(milliseconds: delayMult * 1000),
                    () {
                  //include inside other future so definitely happens after rather relying on race
                  //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                  //Log the word just got in success words, which gets green to shown
                  logWinAndSetNewWord(winRecordBoardsIndexToFix, winningBoard);
                  ss(); //setState(() {});

                  if (getIsStreak()) {
                    Future.delayed(
                        const Duration(milliseconds: delayMult * 750), () {
                      if (getGbCurrentRowInt() > 0) {
                        //GB
                        //Slide the cards back visually, creating the illusion of stepping back
                        temporaryVisualOffsetForSlide = 1;
                        ss(); //setState(() {});
                        Future.delayed(
                            const Duration(milliseconds: durMult * 250), () {
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
    pushUpSteps++;
    //flips.initiateFlipState(); //fix any loose states
    save.saveKeys();
  }

  void logWinAndSetNewWord(winRecordBoardsIndexToFix, winningBoard) {
    //Log the word just got in success words, which gets green to show
    //Fix the fact that we stored a -1 in this place temporarily
    winRecordBoards[winRecordBoardsIndexToFix] = winningBoard;
    firstKnowledge[winningBoard] = enteredWords.length -
        (numRowsPerBoard -
            (getAbLiveNumRowsPerBoard() - getAbCurrentRowInt())) -
        1;
    //Create new target word for the board
    targetWords[winningBoard] = getTargetWord();

    //flips.initiateFlipState();
    save.saveKeys();
  }

  void cheatInitiate() {
    //Speed initialise known entries using cheat mode for debugging
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

  void resetBoard() {
    p("Reset board");
    initiateBoard();
    resetCaches();
    //flips.initiateFlipState();
    analytics.logLevelStart(levelName: "Reset");
    save.saveKeys();
  }

  String getCardLetterAtAbIndex(abIndex) {
    int rowOfAbIndex = abIndex ~/ 5;
    try {
      String letter = "";
      if (rowOfAbIndex > getAbCurrentRowInt()) {
        letter = "";
      } else if (rowOfAbIndex == getAbCurrentRowInt()) {
        if (currentTyping.length > (abIndex % 5)) {
          letter = currentTyping.substring(abIndex % 5, (abIndex % 5) + 1);
        } else {
          letter = "";
        }
      } else {
        letter = enteredWords[rowOfAbIndex][abIndex % 5];
      }
      return letter;
    } catch (e) {
      p(["Crash getCardLetterAtAbIndex", abIndex, e]);
      return "";
    }
  }

  bool getTestHistoricalAbWin(rowOfAbIndex, boardNumber) {
    if (rowOfAbIndex > 0 &&
        winRecordBoards.length > rowOfAbIndex &&
        winRecordBoards[rowOfAbIndex] == boardNumber) {
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

  var streakCache = {};
  bool getIsStreak() {
    if (!streakCache.containsKey(winRecordBoards.length)) {
      streakCache = {}; //reset cache
      streakCache[winRecordBoards.length] = isStreakReal();
    }
    return streakCache[winRecordBoards.length];
  }

  bool isStreakReal() {
    bool isStreak = true;
    if (winRecordBoards.length < 3) {
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
    return isStreak;
  }

  String getCurrentTyping() {
    return currentTyping;
  }

  bool getDetectBoardSolvedByABRow(boardNumber, maxAbRowToCheck) {
    for (var abRow = getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);
        abRow < min(getAbCurrentRowInt(), maxAbRowToCheck);
        abRow++) {
      bool result = true;
      for (var column = 0; column < 5; column++) {
        int abIndex = abRow * 5 + column;
        if (cardColors.getAbCardColor(abIndex, boardNumber) != green) {
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
    if (gameEncoded == "") {
      p(["loadFromEncodedState empty"]);
    } else if (gameEncoded != gameEncodedLast) {
      try {
        Map<String, dynamic> gameTmp = {};
        gameTmp = json.decode(gameEncoded);

        String tmpgUser = gameTmp["gUser"] ?? "Default";
        if (tmpgUser != g.getUser() && tmpgUser != "Default") {
          //Error state, so set gUser properly and redo loadKeys from firebase
          g.setUser(tmpgUser);
          save.loadKeys();
          return;
        }

        targetWords = gameTmp["targetWords"] ?? getNewTargetWords(numBoards);
        enteredWords = gameTmp["enteredWords"] ?? [];
        winRecordBoards = gameTmp["winRecordBoards"] ?? [];
        firstKnowledge =
            gameTmp["firstKnowledge"] ?? getBlankFirstKnowledge(numBoards);
        pushUpSteps = gameTmp["pushUpSteps"] ?? 0;
        expandingBoard = gameTmp["expandingBoard"] ?? false;
        expandingBoardEver = gameTmp["expandingBoardEver"] ?? false;

        //TRANSITIONARY logic from old variable naming convention
        int offsetRollback = gameTmp["offsetRollback"] ?? 0;
        if (offsetRollback != 0) {
          p(["One-off migration"]);
          pushUpSteps = offsetRollback;
        }
        //TRANSITIONARY logic from old variable naming convention
      } catch (error) {
        p(["loadFromEncodedState error", error]);
        //resetBoardReal(true);
      }
      gameEncodedLast = gameEncoded;
      resetCaches(); // saveOrLoadKeysCountCache++; flips.initiateFlipState();
    }
  }

  String getEncodeCurrentGameState() {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["targetWords"] = targetWords;
    gameTmp["gUser"] = g.getUser();

    gameTmp["enteredWords"] = enteredWords;
    gameTmp["winRecordBoards"] = winRecordBoards;
    gameTmp["firstKnowledge"] = firstKnowledge;
    gameTmp["pushUpSteps"] = pushUpSteps;
    gameTmp["expandingBoard"] = expandingBoard;
    gameTmp["expandingBoardEver"] = expandingBoardEver;

    return json.encode(gameTmp);
  }

  void printCheatTargetWords() {
    if (cheatMode) {
      p([
        targetWords,
        enteredWords,
        winRecordBoards,
        currentTyping,
        firstKnowledge,
        getPushOffBoardRows(),
        getExtraRows(),
        pushUpSteps,
        getAbLiveNumRowsPerBoard(),
      ]);
    }
  }

  bool getAboutToWinCache() {
    return aboutToWinCache;
  }

  int getPushOffBoardRows() {
    if (expandingBoard) {
      return firstKnowledge.cast<int>().reduce(min);
    } else {
      return pushUpSteps;
    }
  }

  int getExtraRows() {
    return pushUpSteps - getPushOffBoardRows();
  }

  String getTargetWordForBoard(boardNumber) {
    if (boardNumber < targetWords.length) {
    } else {
      p("getCurrentTargetWordForBoard error");
      targetWords = getNewTargetWords(numBoards);
    }
    return targetWords[boardNumber];
  }

  bool getExpandingBoard() {
    return expandingBoard;
  }

  void setExpandingBoard(tf) {
    expandingBoard = tf;
  }

  bool getExpandingBoardEver() {
    return expandingBoardEver;
  }

  void setExpandingBoardEver(tf) {
    expandingBoardEver = tf;
  }

  int getGbLiveNumRowsPerBoard() {
    //GB
    return numRowsPerBoard + getExtraRows();
  }

  int getAbLiveNumRowsPerBoard() {
    return numRowsPerBoard + getExtraRows() + getPushOffBoardRows();
  }

  int getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) {
    if (!expandingBoard) {
      return getPushOffBoardRows();
    }
    if (boardNumber < firstKnowledge.length) {
      return firstKnowledge[boardNumber];
    } else {
      firstKnowledge = getBlankFirstKnowledge(numBoards);
      p("getFirstVisualRowToShowOnBoard error");
      return 0;
    }
  }

  List<int> getFirstAbRowToShowOnBoardDueToKnowledgeAll() {
    return [
      getFirstAbRowToShowOnBoardDueToKnowledge(0),
      getFirstAbRowToShowOnBoardDueToKnowledge(1),
      getFirstAbRowToShowOnBoardDueToKnowledge(2),
      getFirstAbRowToShowOnBoardDueToKnowledge(3)
    ];
  }

  int getGbCurrentRowInt() {
    //GB
    return getGBRowFromABRow(getAbCurrentRowInt());
  }

  int getAbCurrentRowInt() {
    return enteredWords.length;
  }

  String getTargetWord() {
    return finalWords[random.nextInt(finalWords.length)];
  }

  List getNewTargetWords(numberOfBoards) {
    var starterList = [];
    for (var i = 0; i < numberOfBoards; i++) {
      starterList.add(getTargetWord());
    }
    return starterList;
  }

  List getCurrentTargetWords() {
    return targetWords;
  }

  int getTemporaryVisualOffsetForSlide() {
    return temporaryVisualOffsetForSlide;
  }

  int getHighlightedBoard() {
    return highlightedBoard;
  }

  void setHighlightedBoard(hb) {
    highlightedBoard = hb;
  }

  List getFirstKnowledge() {
    return firstKnowledge;
  }
}
