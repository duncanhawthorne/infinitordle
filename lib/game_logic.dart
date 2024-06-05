import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class CustomMapNotifier extends ValueNotifier<Map<int, List<double>>> {
  CustomMapNotifier() : super({});

  void set(int abRow, int column, double tvalue) {
    if (!value.containsKey(abRow)) {
      value[abRow] = List<double>.generate(cols, (i) => 0.0);
    }
    value[abRow]![column] = tvalue;
    notifyListeners();
  }

  void remove(int key) {
    if (value.containsKey(key)) {
      value.remove(key);
    }
    notifyListeners();
  }
}

class Game {
  //State to save
  List<dynamic> targetWords = ["x"];
  List<dynamic> enteredWords = ["x"];
  List<dynamic> winRecordBoards = [-1];
  List<dynamic> firstKnowledge = ["x"];

  //int pushUpSteps = -1;
  final pushUpStepsNotifier = ValueNotifier(-1);

  int get pushUpSteps => pushUpStepsNotifier.value;

  set pushUpSteps(int value) => pushUpStepsNotifier.value = value;
  bool expandingBoard = false;
  bool expandingBoardEver = false;

  //Other state non-saved
  final currentTyping =
      List<ValueNotifier<String>>.generate(cols, (i) => ValueNotifier(""));
  final highlightedBoard = ValueNotifier(0);

  //transitive state
  bool aboutToWinCache = false;
  final temporaryVisualOffsetForSlide = ValueNotifier(0);
  String gameEncodedLastCache = "";
  var abCardFlourishFlipAngles = CustomMapNotifier(); //{}.obs;
  final boardFlourishFlipRows =
      List<ValueNotifier<int>>.generate(cols, (i) => ValueNotifier(100));
  final illegalFiveLetterWord = ValueNotifier(false);
  final targetWordsChangedNotifier = ValueNotifier(0);
  final currentRowChangedNotifier = ValueNotifier(0);

  void initiateBoard() {
    targetWords = getNewTargetWords(numBoards);
    enteredWords = [];
    winRecordBoards = [];
    firstKnowledge = getBlankFirstKnowledge(numBoards);
    pushUpSteps = 0;
    expandingBoard = false;
    expandingBoardEver = false;

    setCurrentTyping("");
    setHighlightedBoard(-1);

    aboutToWinCache = false;
    setTemporaryVisualOffsetForSlide(0);
    //gameEncodedLastCache = ""; Don't reset else new d/l will show as change
    for (var item in abCardFlourishFlipAngles.value.keys) {
      abCardFlourishFlipAngles.remove(item);
    }
    clearBoardFlourishFlipRows();
    setIllegalFiveLetterWord(false);
    targetWordsChangedNotifier.value++;
    currentRowChangedNotifier.value++;

    if (cheatMode) {
      cheatInitiate();
    }
    setStateGlobal();
  }

  void onKeyboardTapped(String letter) {
    printCheatTargetWords();
    fixTitle();

    if (letter == " ") {
      //Ignore pressing of non-keys
    } else if (letter == "<") {
      //Backspace key
      if (getCurrentTyping().isNotEmpty) {
        //There is text to delete
        String origTyping =
            getCurrentTyping().substring(0, getCurrentTyping().length);
        setCurrentTyping(
            getCurrentTyping().substring(0, getCurrentTyping().length - 1));
        if (origTyping.length == cols && !isLegalWord(origTyping)) {
          setIllegalFiveLetterWord(false);
        }
      }
    } else if (letter == ">") {
      //Submit guess
      if (getCurrentTyping().length == cols) {
        //Full word entered, so can submit
        if (isLegalWord(getCurrentTyping()) &&
            getAbCurrentRowInt() < getAbLiveNumRowsPerBoard()) {
          //Legal word so can enter the word
          //Note, not necessarily correct word
          handleLegalWordEntered();
        }
      }
    } else {
      //pressing regular letter key
      if (getCurrentTyping().length < cols) {
        //Space to add extra letter
        setCurrentTyping(getCurrentTyping() + letter);
        if (getCurrentTyping().length == cols &&
            !isLegalWord(getCurrentTyping())) {
          setIllegalFiveLetterWord(true);
        }
      }
    }
  }

  void handleLegalWordEntered() {
    // set some local variable to ensure threadsafe
    int cardAbRowPreGuessToFix = getAbCurrentRowInt();
    int firstKnowledgeToFix = getExtraRows() + getPushOffBoardRows();
    int maxAbRowOfBoard = getAbLiveNumRowsPerBoard();

    enteredWords.add(getCurrentTyping());
    setCurrentTyping("");
    winRecordBoards.add(-2); //Add now, fix value later
    currentRowChangedNotifier.value++;
    if (fbAnalytics) {
      analytics!.logLevelUp(level: enteredWords.length);
    }

    //Test if it is correct word
    int winningBoardToFix =
        getWinningBoardFromWordEnteredInAbRow(cardAbRowPreGuessToFix);
    bool isWin = winningBoardToFix != -1;

    if (!isWin) {
      winRecordBoards[cardAbRowPreGuessToFix] = -1; //Confirm no win
    }

    save.saveKeys();
    //setStateGlobal(); //non-ephemeral state change, so needs setState even with GetX .obs

    gradualRevealAbRow(cardAbRowPreGuessToFix);
    handleWinLoseState(cardAbRowPreGuessToFix, winningBoardToFix,
        firstKnowledgeToFix, isWin, maxAbRowOfBoard);
  }

  void gradualRevealAbRow(abRow) {
    // flip to reveal the colors with pleasing animation
    for (int i = 0; i < cols; i++) {
      setAbCardFlourishFlipAngle(abRow, i, 0.5);
    }
    //setStateGlobal();
    for (int i = 0; i < cols; i++) {
      Future.delayed(Duration(milliseconds: gradualRevealDelayTime * i), () {
        setAbCardFlourishFlipAngle(abRow, i, 0.0);
        if (i == cols - 1) {
          if (abCardFlourishFlipAngles.value.containsKey(abRow)) {
            // Due to delays check still exists before remove
            abCardFlourishFlipAngles.remove(abRow);
            //setStateGlobal(); //needed even with getx .obs to refresh keyboard
          }
        }
        //setStateGlobal();
      });
    }
  }

  Future<void> handleWinLoseState(cardAbRowPreGuessToFix, winningBoardToFix,
      firstKnowledgeToFix, isWin, maxAbRowOfBoard) async {
    //Delay for visual changes to have taken effect
    await sleep(gradualRevealRowTime + visualCatchUpTime);

    //Code for losing game
    if (!isWin && cardAbRowPreGuessToFix + 1 >= maxAbRowOfBoard) {
      //All rows full, game over
      showResetConfirmScreen();
    }

    if (!infMode && isWin) {
      //Code for totally winning game across all boards
      bool totallySolvedLocal = true;
      for (var i = 0; i < numBoards; i++) {
        if (!getDetectBoardSolvedByABRow(i, cardAbRowPreGuessToFix + 1)) {
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

  Future<void> handleWinningWordEntered(
      cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix) async {
    //Slide up and increment firstKnowledge
    await slideUpAnimation();
    firstKnowledgeToFix++;

    if (getReadyForStreakAbRowReal(cardAbRowPreGuessToFix)) {
      // Streak, so need to take another step back

      //Slide up and increment firstKnowledge
      await slideUpAnimation();
      firstKnowledgeToFix++;
    }

    await unflipSwapFlip(
        cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);
  }

  Future<void> slideUpAnimation() async {
    //Slide the cards up visually, creating the illusion of stepping up
    setTemporaryVisualOffsetForSlide(1);
    //setStateGlobal();

    // Delay for sliding cards up to have taken effect
    await sleep(slideTime);

    // Undo the visual slide (and do this instantaneously)
    setTemporaryVisualOffsetForSlide(0);

    // Actually move the cards up, so state matches visual illusion above
    takeOneStepBack();

    // Pause, so can temporarily see new position
    await sleep(visualCatchUpTime);
  }

  void takeOneStepBack() {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables
    pushUpSteps++;
    save.saveKeys();
    //setStateGlobal();
  }

  Future<void> unflipSwapFlip(
      cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix) async {
    //unflip
    setBoardFlourishFlipRow(winningBoardToFix, cardAbRowPreGuessToFix);
    //setStateGlobal();
    await sleep(flipTime);
    await sleep(visualCatchUpTime - flipTime);

    // Log the win officially, and get a new word
    logWinAndSetNewWord(
        cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);

    //flip
    setBoardFlourishFlipRow(winningBoardToFix, -1);
    //setStateGlobal();
    await sleep(flipTime);
    await sleep(visualCatchUpTime);
  }

  void logWinAndSetNewWord(
      winRecordBoardsIndexToFix, winningBoardToFix, firstKnowledgeToFix) {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables

    // Log the word just entered as a win in the official record
    // Fix the fact that we stored a -1 in this place temporarily
    if (winRecordBoards.length > winRecordBoardsIndexToFix) {
      winRecordBoards[winRecordBoardsIndexToFix] = winningBoardToFix;
    }

    // Update first knowledge for scroll back
    firstKnowledge[winningBoardToFix] = firstKnowledgeToFix;

    // Create new target word for the board
    targetWords[winningBoardToFix] = getNewTargetWord();
    targetWordsChangedNotifier.value++;

    save.saveKeys();
    //setStateGlobal();
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
    if (fbAnalytics) {
      analytics!.logLevelStart(levelName: "Reset");
      analytics!.logLevelUp(level: enteredWords.length);
    }
    save.saveKeys();
  }

  void toggleExpandingBoardState() {
    if (expandingBoard) {
      expandingBoard = false;
    } else {
      expandingBoard = true;
      expandingBoardEver = true;
    }
    save.saveKeys();
    setStateGlobal();
  }

  void toggleHighlightedBoard(boardNumber) {
    if (getHighlightedBoard() == boardNumber) {
      setHighlightedBoard(-1); //if already set turn off
    } else {
      setHighlightedBoard(boardNumber);
    }
    //No need to save as local state
  }

  String getCardLetterAtAbIndex(abIndex) {
    int abRow = abIndex ~/ cols;
    int col = abIndex % cols;
    try {
      String letter = "";
      if (abRow > getAbCurrentRowInt()) {
        letter = "";
      } else if (abRow == getAbCurrentRowInt()) {
        letter = getCurrentTypingAtCol(col);
      } else {
        letter = enteredWords[abRow][col];
      }
      return letter;
    } catch (e) {
      p(["Crash getCardLetterAtAbIndex", abIndex, e]);
      return "";
    }
  }

  bool getTestHistoricalAbWin(abRow, boardNumber) {
    if (abRow > 0 &&
        winRecordBoards.length > abRow &&
        winRecordBoards[abRow] == boardNumber) {
      return true;
    }
    return false;
  }

  bool getReadyForStreakAbRowReal(abRow) {
    bool isStreak = true;
    if (abRow < 2) {
      isStreak = false;
    } else {
      for (int q = 0; q < 2; q++) {
        if (abRow - 1 - q < 0 || winRecordBoards[abRow - 1 - q] != -1) {
          isStreak = true;
        } else {
          isStreak = false;
          break;
        }
      }
    }
    return isStreak;
  }

  bool getReadyForStreakCurrentRow() {
    return getReadyForStreakAbRowReal(getAbCurrentRowInt());
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

  int getWinningBoardFromWordEnteredInAbRow(cardAbRowPreGuessToFix) {
    //bool isWin = false;
    int winningBoardToFix = -1;
    for (var board = 0; board < numBoards; board++) {
      if (getCurrentTargetWordForBoard(board) ==
          enteredWords[cardAbRowPreGuessToFix]) {
        //isWin = true;
        winningBoardToFix = board;
      }
    }
    return winningBoardToFix;
  }

  void loadFromEncodedState(gameEncoded, sync) {
    if (gameEncoded == "") {
      p(["loadFromEncodedState empty"]);
      setStateGlobal();
    } else if (gameEncoded != gameEncodedLastCache) {
      try {
        Map<String, dynamic> gameTmp = {};
        gameTmp = json.decode(gameEncoded);

        String tmpgUser = gameTmp["gUser"] ?? "Default";
        if (tmpgUser != g.getUser() && tmpgUser != "Default") {
          //Error state, so set gUser properly and redo loadKeys from firebase
          g.setUser(tmpgUser);
          save.loadKeys();
          setStateGlobal();
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

        //TRANSITIONAL logic from old variable naming convention
        int offsetRollback = gameTmp["offsetRollback"] ?? 0;
        if (offsetRollback != 0) {
          p(["One-off migration"]);
          pushUpSteps = offsetRollback;
        }
        //TRANSITIONAL logic from old variable naming convention
      } catch (error) {
        p(["loadFromEncodedState error", error]);
      }
      gameEncodedLastCache = gameEncoded;
      if (sync) {
        setStateGlobal();
      } else {
        //Future.delayed(const Duration(milliseconds: 0), () {
        //  // ASAP but not sync
        //  ss();
        //});
      }
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
        getCurrentTyping(),
        firstKnowledge,
        getPushOffBoardRows(),
        getExtraRows(),
        pushUpSteps,
        getAbLiveNumRowsPerBoard(),
        getAbCurrentRowInt(),
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
      a = winnableWords[random.nextInt(winnableWords.length)];
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

  int getLastCardToConsiderForKeyColors() {
    //if (abCardFlourishFlipAngles.isEmpty) {
    //  return enteredWords.length * cols;
    //}
    int count = 0;
    for (int key in abCardFlourishFlipAngles.value.keys) {
      for (int i = 0; i < cols; i++) {
        if (abCardFlourishFlipAngles.value[key]![i] > 0) {
          count++;
        }
      }
      //count = (abCardFlourishFlipAngles[key]).where((x) => x > 0.0 ?? false).length + count;
    }
    return enteredWords.length * cols - count;
  }

  void setAbCardFlourishFlipAngle(int abRow, int column, double value) {
    abCardFlourishFlipAngles.set(abRow, column, value);
    /*
    if (!abCardFlourishFlipAngles.containsKey(abRow)) {
      abCardFlourishFlipAngles[abRow] =
      List<RxDouble>.generate(cols, (i) => 0.0.obs);
    }
    abCardFlourishFlipAngles[abRow][column].value = value;

     */
  }

  void clearBoardFlourishFlipRows() {
    for (int i = 0; i < boardFlourishFlipRows.length; i++) {
      setBoardFlourishFlipRow(i, -1);
    }
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

  bool isBoardNormalHighlighted(boardNumber) {
    return getHighlightedBoard() == -1 || getHighlightedBoard() == boardNumber;
  }

  void setCurrentTyping(text) {
    for (int i = 0; i < cols; i++) {
      if (i < text.length) {
        currentTyping[i].value = text.substring(i, i + 1);
      } else {
        currentTyping[i].value = "";
      }
    }
  }

  setIllegalFiveLetterWord(tf) {
    illegalFiveLetterWord.value = tf;
  }

  setTemporaryVisualOffsetForSlide(value) {
    temporaryVisualOffsetForSlide.value = value;
  }

  setHighlightedBoard(value) {
    highlightedBoard.value = value;
  }

  void setBoardFlourishFlipRow(i, val) {
    boardFlourishFlipRows[i].value = val;
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
    return temporaryVisualOffsetForSlide.value;
  }

  int getHighlightedBoard() {
    return highlightedBoard.value;
  }

  List getFirstKnowledge() {
    return firstKnowledge;
  }

  String getCurrentTyping() {
    return currentTyping
        .map((var element) => element.value)
        .reduce((value, element) => value + element);
  }

  String getCurrentTypingAtCol(col) {
    return currentTyping[col].value;
  }

  bool isIllegalFiveLetterWord() {
    return illegalFiveLetterWord.value;
  }

  int getBoardFlourishFlipRow(i) {
    return boardFlourishFlipRows[i].value;
  }
}
