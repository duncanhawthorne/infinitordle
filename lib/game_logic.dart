import 'dart:math';
import 'dart:convert';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class Game {
  //State to save
  List<dynamic> targetWords = ["x"];
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
  String gameEncodedLastCache = "";
  int highlightedBoard = -1; //non-saved state
  var abCardFlourishFlipAngles = {};

  void onKeyboardTapped(int index) {
    String letter = keyboardList[index];
    printCheatTargetWords();
    fixTitle();

    if (letter == " ") {
      //Ignore pressing of non-keys
    } else if (letter == "<") {
      //Backspace key
      if (currentTyping.isNotEmpty) {
        //There is text to delete
        currentTyping = currentTyping.substring(0, currentTyping.length - 1);
        ss();
      }
    } else if (letter == ">") {
      //Submit guess
      if (currentTyping.length == cols) {
        //Full word entered, so can submit
        if (isLegalWord(currentTyping)) {
          //Legal word so can enter the word
          //Note, not necessarily correct word
          handleLegalWordEntered();
        }
      }
    } else {
      //pressing regular letter key
      if (currentTyping.length < cols) {
        //Space to add extra letter
        currentTyping = currentTyping + letter;
        ss();
      }
    }
  }

  void handleLegalWordEntered() {
    // set some local variable to ensure threadsafe
    int cardAbRowPreGuessToFix = getAbCurrentRowInt();
    int firstKnowledgeToFix = getExtraRows() + getPushOffBoardRows();

    enteredWords.add(currentTyping);
    currentTyping = "";
    winRecordBoards.add(-2); //Add now, fix value later
    gradualRevealAbRow(cardAbRowPreGuessToFix);
    analytics.logLevelUp(level: enteredWords.length);

    //Test if it is correct word
    bool isWin = false;
    aboutToWinCache = false;
    int winningBoardToFix = -1;
    for (var board = 0; board < numBoards; board++) {
      if (getCurrentTargetWordForBoard(board) ==
          enteredWords[cardAbRowPreGuessToFix]) {
        isWin = true;
        aboutToWinCache = true;
        winningBoardToFix = board;
      }
    }

    if (!isWin) {
      winRecordBoards[cardAbRowPreGuessToFix] = -1; //Confirm no win
    }

    save.saveKeys();

    //Code for losing game
    if (!isWin && getAbCurrentRowInt() >= getAbLiveNumRowsPerBoard()) {
      //All rows full, game over
      Future.delayed(
          const Duration(milliseconds: gradualRevealDelay * cols + durMult * 500),
          () {
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
        // Leave the screen as is
      }
    }

    if (infMode && isWin) {
      handleWinningWordEntered(
          cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);
    }
  }

  void handleWinningWordEntered(
      cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix) {
    Future.delayed(const Duration(milliseconds: delayMult * 1500), () {
      //Delay for flips.gradualRevealAbRow to have taken effect

      if (getGbCurrentRowInt() <= 0) {
        // If current row would type in next is row zero
        // Then don't slide up
        // Else after slide would be off top of gameboard
        // Possible due to delay functions from previous entries
        // Or if switch from expanding board to non-expanding
        // But still log win in any event
        logWinAndSetNewWord(
            cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);
        //ss();
      } else {
        // Not at very top of board, so can do sliding

        // Slide the cards up visually, creating the illusion of stepping up
        temporaryVisualOffsetForSlide = 1;
        ss();

        Future.delayed(const Duration(milliseconds: durMult * 250), () {
          // Delay for sliding cards up to have taken effect

          // Undo the visual slide illusion (and do this instantaneously)
          temporaryVisualOffsetForSlide = 0;

          // Actually move the cards up, so state matches visual illusion above
          takeOneStepBack();
          //ss();

          // Cards are now in the right place and state matches visuals

          Future.delayed(const Duration(milliseconds: delayMult * 1000), () {
            // Pause, so can temporarily see position after stepped back

            // Log the win (show row green), and get a new word
            logWinAndSetNewWord(
                cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);
            //ss();

            if (getIsStreak()) {
              // Streak, so need to take another step back

              Future.delayed(const Duration(milliseconds: delayMult * 750), () {
                // Pause, so can temporarily see new position

                if (getGbCurrentRowInt() > 0) {
                  // Check not at top of board
                  // Current row would type in next must not be row zero
                  // Else after slide would be off top of gameboard

                  //Slide the cards up visually, creating the illusion of stepping up
                  temporaryVisualOffsetForSlide = 1;
                  ss();

                  Future.delayed(const Duration(milliseconds: durMult * 250),
                      () {
                    // Delay for sliding cards up to have taken effect

                    // Undo the visual slide (and do this instantaneously)
                    temporaryVisualOffsetForSlide = 0;

                    // Actually move the cards up, so state matches visual illusion above
                    takeOneStepBack();
                    //ss();

                    // Cards are now in the right place and state matches visuals
                  });
                }
              });
            }
          });
        });
      }
    });
  }

  void takeOneStepBack() {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables
    pushUpSteps++;
    save.saveKeys();
    ss();
  }

  void logWinAndSetNewWord(
      winRecordBoardsIndexToFix, winningBoardToFix, firstKnowledgeToFix) {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables

    // Log the word just entered as a win, which gets green to show
    // Fix the fact that we stored a -1 in this place temporarily
    winRecordBoards[winRecordBoardsIndexToFix] = winningBoardToFix;

    // Update first knowledge for scroll back
    firstKnowledge[winningBoardToFix] = firstKnowledgeToFix;

    // Create new target word for the board
    targetWords[winningBoardToFix] = getNewTargetWord();

    save.saveKeys();
    ss();
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

  void cheatInitiate() {
    // Speed initialise known entries using cheat mode for debugging
    for (var j = 0; j < numBoards; j++) {
      if (cheatTargetWordsInitial.length > j) {
        targetWords[j] = cheatTargetWordsInitial[j];
      } else {
        targetWords[j] = getNewTargetWord();
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
    analytics.logLevelStart(levelName: "Reset");
    analytics.logLevelUp(level: enteredWords.length);
    save.saveKeys();
  }

  void flipExpandingBoardState() {
    if (expandingBoard) {
      expandingBoard = false;
    } else {
      expandingBoard = true;
      expandingBoardEver = true;
    }
    save.saveKeys();
    ss();
  }

  void flipHighlightedBoard(boardNumber) {
    if (highlightedBoard == boardNumber) {
      highlightedBoard = -1; //if already set turn off
    } else {
      highlightedBoard = boardNumber;
    }
    //No need to save as local state
    ss();
  }

  String getCardLetterAtAbIndex(abIndex) {
    int rowOfAbIndex = abIndex ~/ cols;
    try {
      String letter = "";
      if (rowOfAbIndex > getAbCurrentRowInt()) {
        letter = "";
      } else if (rowOfAbIndex == getAbCurrentRowInt()) {
        if (currentTyping.length > (abIndex % cols)) {
          letter = currentTyping.substring(abIndex % cols, (abIndex % cols) + 1);
        } else {
          letter = "";
        }
      } else {
        letter = enteredWords[rowOfAbIndex][abIndex % cols];
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

  var streakCache = {};
  bool getIsStreak() {
    if (!streakCache.containsKey(winRecordBoards.length)) {
      streakCache = {};
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

  bool getDetectBoardSolvedByABRow(boardNumber, maxAbRowToCheck) {
    for (var abRow = getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);
        abRow < min(getAbCurrentRowInt(), maxAbRowToCheck);
        abRow++) {
      bool result = true;
      for (var column = 0; column < cols; column++) {
        int abIndex = abRow * cols + column;
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
    } else if (gameEncoded != gameEncodedLastCache) {
      try {
        Map<String, dynamic> gameTmp = {};
        gameTmp = json.decode(gameEncoded);

        String tmpgUser = gameTmp["gUser"] ?? "Default";
        if (tmpgUser != g.getUser() && tmpgUser != "Default") {
          //Error state, so set gUser properly and redo loadKeys from firebase
          g.setUser(tmpgUser);
          save.loadKeys();
          ss();
          return;
        }

        targetWords = gameTmp["targetWords"] ?? getNewTargetWords(numBoards);

        if (targetWords.length != numBoards) {
          resetBoard();
          return;
        }

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
      }
      gameEncodedLastCache = gameEncoded;
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

  String getCurrentTargetWordForBoard(boardNumber) {
    if (boardNumber < targetWords.length) {
    } else {
      p("getCurrentTargetWordForBoard error");
      targetWords = getNewTargetWords(numBoards);
    }
    return targetWords[boardNumber];
  }

  String getNewTargetWord() {
    String a = targetWords[0];
    while (targetWords.contains(a) || enteredWords.contains(a)) {
      // Ensure a word we have never seen before
      a = finalWords[random.nextInt(finalWords.length)];
    }
    return a;
  }

  List getNewTargetWords(numberOfBoards) {
    var starterList = [];
    for (var i = 0; i < numberOfBoards; i++) {
      starterList.add(getNewTargetWord());
    }
    return starterList;
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

  int getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) {
    if (firstKnowledge.length != numBoards) {
      firstKnowledge = getBlankFirstKnowledge(numBoards);
      p("getFirstVisualRowToShowOnBoard error");
    }
    if (!expandingBoard) {
      return getPushOffBoardRows();
    } else if (boardNumber < firstKnowledge.length) {
      return firstKnowledge[boardNumber];
    } else {
      p("getFirstVisualRowToShowOnBoard error");
      return 0;
    }
  }

  List<int> getFirstAbRowToShowOnBoardDueToKnowledgeAll() {
    return List<int>.generate(
        numBoards, (i) => getFirstAbRowToShowOnBoardDueToKnowledge(i));
  }

  // PRETTY MUCH PURE GETTERS AND SETTERS

  int getAbLiveNumRowsPerBoard() {
    return numRowsPerBoard + getExtraRows() + getPushOffBoardRows();
  }

  int getGbLiveNumRowsPerBoard() {
    return numRowsPerBoard + getExtraRows();
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

  int getAbCurrentRowInt() {
    return enteredWords.length;
  }

  int getGbCurrentRowInt() {
    return getGBRowFromABRow(getAbCurrentRowInt());
  }

  // PURE GETTERS

  bool getAboutToWinCache() {
    return aboutToWinCache;
  }

  bool getExpandingBoard() {
    return expandingBoard;
  }

  bool getExpandingBoardEver() {
    return expandingBoardEver;
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

  List getFirstKnowledge() {
    return firstKnowledge;
  }

  String getCurrentTyping() {
    return currentTyping;
  }
}
