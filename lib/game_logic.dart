import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'helper.dart';

class Game {
  //State to save
  List<String> _targetWords = ["x"];
  List<String> _enteredWords = ["x"];
  List<int> _winRecordBoards = [-1];
  List<int> _firstKnowledge = [-1];

  final pushUpStepsNotifier = ValueNotifier(-1);
  int get pushUpSteps => pushUpStepsNotifier.value;
  set pushUpSteps(int value) => pushUpStepsNotifier.value = value;

  bool _expandingBoard = false;
  bool _expandingBoardEver = false;

  //Other state non-saved
  final currentTypingNotifiers =
      List<ValueNotifier<String>>.generate(cols, (i) => ValueNotifier(""));
  final highlightedBoardNotifier = ValueNotifier(0);

  //transitive state
  final temporaryVisualOffsetForSlideNotifier = ValueNotifier(0);
  String _gameEncodedLastCache = "";
  final abCardFlourishFlipAnglesNotifier = _CustomMapNotifier(); //{}.obs;
  final boardFlourishFlipRowsNotifiers =
      List<ValueNotifier<int>>.generate(cols, (i) => ValueNotifier(100));
  final illegalFiveLetterWordNotifier = ValueNotifier(false);
  final targetWordsChangedNotifier = ValueNotifier(0);
  final currentRowChangedNotifier = ValueNotifier(0);

  void initiateBoard() {
    _targetWords = _getNewTargetWords(numBoards);
    _enteredWords = [];
    _winRecordBoards = [];
    _firstKnowledge = _getBlankFirstKnowledge(numBoards);
    pushUpSteps = 0;
    _expandingBoard = false;
    _expandingBoardEver = false;

    _setCurrentTyping("");
    highlightedBoard = -1;

    temporaryVisualOffsetForSlide = 0;
    //gameEncodedLastCache = ""; Don't reset else new d/l will show as change
    for (int item in abCardFlourishFlipAnglesNotifier.value.keys) {
      abCardFlourishFlipAnglesNotifier.remove(item);
    }
    _clearBoardFlourishFlipRows();
    illegalFiveLetterWord = false;
    targetWordsChangedNotifier.value++;
    currentRowChangedNotifier.value++;

    if (cheatMode) {
      _cheatInitiate();
    }
    setStateGlobal();
  }

  void onKeyboardTapped(String letter) {
    _printCheatTargetWords();
    fixTitle();

    if (letter == " ") {
      //Ignore pressing of non-keys
    } else if (letter == "<") {
      //Backspace key
      if (currentTypingString.isNotEmpty) {
        //There is text to delete
        String origTyping =
            currentTypingString.substring(0, currentTypingString.length);
        _setCurrentTyping(
            currentTypingString.substring(0, currentTypingString.length - 1));
        if (origTyping.length == cols && !_isLegalWord(origTyping)) {
          illegalFiveLetterWord = false;
        }
      }
    } else if (letter == ">") {
      //Submit guess
      if (currentTypingString.length == cols) {
        //Full word entered, so can submit
        if (_isLegalWord(currentTypingString) &&
            abCurrentRowInt < abLiveNumRowsPerBoard) {
          //Legal word so can enter the word
          //Note, not necessarily correct word
          _handleLegalWordEntered();
        }
      }
    } else {
      //pressing regular letter key
      if (currentTypingString.length < cols) {
        //Space to add extra letter
        _setCurrentTyping(currentTypingString + letter);
        if (currentTypingString.length == cols &&
            !_isLegalWord(currentTypingString)) {
          illegalFiveLetterWord = true;
        }
      }
    }
  }

  void _handleLegalWordEntered() {
    // set some local variable to ensure threadsafe
    int cardAbRowPreGuessToFix = abCurrentRowInt;
    int firstKnowledgeToFix = extraRows + pushOffBoardRows;
    int maxAbRowOfBoard = abLiveNumRowsPerBoard;

    _enteredWords.add(currentTypingString);
    _setCurrentTyping("");
    _winRecordBoards.add(-2); //Add now, fix value later
    currentRowChangedNotifier.value++;
    if (fbAnalytics) {
      analytics!.logLevelUp(level: _enteredWords.length);
    }

    //Test if it is correct word
    int winningBoardToFix =
        _getWinningBoardFromWordEnteredInAbRow(cardAbRowPreGuessToFix);
    bool isWin = winningBoardToFix != -1;

    if (!isWin) {
      _winRecordBoards[cardAbRowPreGuessToFix] = -1; //Confirm no win
    }

    save.saveKeys();
    //setStateGlobal(); //non-ephemeral state change, so needs setState even with GetX .obs

    _gradualRevealAbRow(cardAbRowPreGuessToFix);
    _handleWinLoseState(cardAbRowPreGuessToFix, winningBoardToFix,
        firstKnowledgeToFix, isWin, maxAbRowOfBoard);
  }

  void _gradualRevealAbRow(int abRow) {
    // flip to reveal the colors with pleasing animation
    for (int i = 0; i < cols; i++) {
      _setAbCardFlourishFlipAngle(abRow, i, 0.5);
    }
    //setStateGlobal();
    for (int i = 0; i < cols; i++) {
      Future.delayed(Duration(milliseconds: gradualRevealDelayTime * i), () {
        _setAbCardFlourishFlipAngle(abRow, i, 0.0);
        if (i == cols - 1) {
          if (abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
            // Due to delays check still exists before remove
            abCardFlourishFlipAnglesNotifier.remove(abRow);
            //setStateGlobal(); //needed even with getx .obs to refresh keyboard
          }
        }
        //setStateGlobal();
      });
    }
  }

  Future<void> _handleWinLoseState(
      int cardAbRowPreGuessToFix,
      int winningBoardToFix,
      int firstKnowledgeToFix,
      bool isWin,
      int maxAbRowOfBoard) async {
    //Delay for visual changes to have taken effect
    await _sleep(gradualRevealRowTime + visualCatchUpTime);

    //Code for losing game
    if (!isWin && cardAbRowPreGuessToFix + 1 >= maxAbRowOfBoard) {
      //All rows full, game over
      showResetConfirmScreen();
    }

    if (!infMode && isWin) {
      //Code for totally winning game across all boards
      bool totallySolvedLocal = true;
      for (int i = 0; i < numBoards; i++) {
        if (!getDetectBoardSolvedByABRow(i, cardAbRowPreGuessToFix + 1)) {
          totallySolvedLocal = false;
        }
      }
      if (totallySolvedLocal) {
        // Leave the screen as is
      }
    }

    if (infMode && isWin) {
      _handleWinningWordEntered(
          cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);
    }
  }

  Future<void> _handleWinningWordEntered(int cardAbRowPreGuessToFix,
      int winningBoardToFix, int firstKnowledgeToFix) async {
    //Slide up and increment firstKnowledge
    await _slideUpAnimation();
    firstKnowledgeToFix++;

    if (_getReadyForStreakAbRowReal(cardAbRowPreGuessToFix)) {
      // Streak, so need to take another step back

      //Slide up and increment firstKnowledge
      await _slideUpAnimation();
      firstKnowledgeToFix++;
    }

    await _unflipSwapFlip(
        cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);
  }

  Future<void> _slideUpAnimation() async {
    //Slide the cards up visually, creating the illusion of stepping up
    temporaryVisualOffsetForSlide = 1;
    //setStateGlobal();

    // Delay for sliding cards up to have taken effect
    await _sleep(slideTime);

    // Undo the visual slide (and do this instantaneously)
    temporaryVisualOffsetForSlide = 0;

    // Actually move the cards up, so state matches visual illusion above
    _takeOneStepBack();

    // Pause, so can temporarily see new position
    await _sleep(visualCatchUpTime);
  }

  void _takeOneStepBack() {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables
    pushUpSteps++;
    save.saveKeys();
    //setStateGlobal();
  }

  Future<void> _unflipSwapFlip(int cardAbRowPreGuessToFix,
      int winningBoardToFix, int firstKnowledgeToFix) async {
    //unflip
    _setBoardFlourishFlipRow(winningBoardToFix, cardAbRowPreGuessToFix);
    //setStateGlobal();
    await _sleep(flipTime);
    await _sleep(visualCatchUpTime - flipTime);

    // Log the win officially, and get a new word
    _logWinAndSetNewWord(
        cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);

    //flip
    _setBoardFlourishFlipRow(winningBoardToFix, -1);
    //setStateGlobal();
    await _sleep(flipTime);
    await _sleep(visualCatchUpTime);
  }

  void _logWinAndSetNewWord(int winRecordBoardsIndexToFix,
      int winningBoardToFix, int firstKnowledgeToFix) {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables

    // Log the word just entered as a win in the official record
    // Fix the fact that we stored a -1 in this place temporarily
    if (_winRecordBoards.length > winRecordBoardsIndexToFix) {
      _winRecordBoards[winRecordBoardsIndexToFix] = winningBoardToFix;
    }

    // Update first knowledge for scroll back
    _firstKnowledge[winningBoardToFix] = firstKnowledgeToFix;

    // Create new target word for the board
    _targetWords[winningBoardToFix] = _getNewTargetWord();
    targetWordsChangedNotifier.value++;

    save.saveKeys();
    //setStateGlobal();
  }

  void _cheatInitiate() {
    // Speed initialise known entries using cheat mode for debugging
    for (int j = 0; j < numBoards; j++) {
      if (cheatTargetWordsInitial.length > j) {
        _targetWords[j] = cheatTargetWordsInitial[j];
      } else {
        _targetWords[j] = _getNewTargetWord();
      }
    }
    for (int j = 0; j < cheatEnteredWordsInitial.length; j++) {
      _enteredWords.add(cheatEnteredWordsInitial[j]);
      _winRecordBoards.add(-1);
    }
  }

  void resetBoard() {
    p("Reset board");
    initiateBoard();
    if (fbAnalytics) {
      analytics!.logLevelStart(levelName: "Reset");
      analytics!.logLevelUp(level: _enteredWords.length);
    }
    save.saveKeys();
  }

  void toggleExpandingBoardState() {
    if (_expandingBoard) {
      _expandingBoard = false;
    } else {
      _expandingBoard = true;
      _expandingBoardEver = true;
    }
    save.saveKeys();
    setStateGlobal();
  }

  void toggleHighlightedBoard(int boardNumber) {
    if (highlightedBoard == boardNumber) {
      highlightedBoard = -1; //if already set turn off
    } else {
      highlightedBoard = boardNumber;
    }
    //No need to save as local state
  }

  String getCardLetterAtAbIndex(int abIndex) {
    int abRow = abIndex ~/ cols;
    int col = abIndex % cols;
    try {
      String letter = "";
      if (abRow > abCurrentRowInt) {
        letter = "";
      } else if (abRow == abCurrentRowInt) {
        letter = _getCurrentTypingAtCol(col);
      } else {
        letter = _enteredWords[abRow][col];
      }
      return letter;
    } catch (e) {
      p(["Crash getCardLetterAtAbIndex", abIndex, e]);
      return "";
    }
  }

  bool getTestHistoricalAbWin(int abRow, int boardNumber) {
    if (abRow > 0 &&
        _winRecordBoards.length > abRow &&
        _winRecordBoards[abRow] == boardNumber) {
      return true;
    }
    return false;
  }

  bool _getReadyForStreakAbRowReal(int abRow) {
    bool isStreak = true;
    if (abRow < 2) {
      isStreak = false;
    } else {
      for (int q = 0; q < 2; q++) {
        if (abRow - 1 - q < 0 || _winRecordBoards[abRow - 1 - q] != -1) {
          isStreak = true;
        } else {
          isStreak = false;
          break;
        }
      }
    }
    return isStreak;
  }

  bool get readyForStreakCurrentRow =>
      _getReadyForStreakAbRowReal(abCurrentRowInt);

  bool getDetectBoardSolvedByABRow(int boardNumber, int maxAbRowToCheck) {
    for (int abRow = getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);
        abRow < min(abCurrentRowInt, maxAbRowToCheck);
        abRow++) {
      bool result = true;
      for (int column = 0; column < cols; column++) {
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

  int _getWinningBoardFromWordEnteredInAbRow(int cardAbRowPreGuessToFix) {
    //bool isWin = false;
    int winningBoardToFix = -1;
    for (int board = 0; board < numBoards; board++) {
      if (getCurrentTargetWordForBoard(board) ==
          _enteredWords[cardAbRowPreGuessToFix]) {
        //isWin = true;
        winningBoardToFix = board;
      }
    }
    return winningBoardToFix;
  }

  void loadFromEncodedState(String gameEncoded, bool sync) {
    if (gameEncoded == "") {
      p(["loadFromEncodedState empty"]);
      setStateGlobal();
    } else if (gameEncoded != _gameEncodedLastCache) {
      try {
        Map<String, dynamic> gameTmp = {};
        gameTmp = json.decode(gameEncoded);

        String tmpgUser = gameTmp["gUser"] ?? "Default";
        if (tmpgUser != g.gUser && tmpgUser != "Default") {
          //Error state, so set gUser properly and redo loadKeys from firebase
          g.gUser = tmpgUser;
          save.loadKeys();
          setStateGlobal();
          return;
        }

        _targetWords = gameTmp["targetWords"] ?? _getNewTargetWords(numBoards);

        if (_targetWords.length != numBoards) {
          resetBoard();
          return;
        }

        _enteredWords = gameTmp["enteredWords"] ?? [];
        _winRecordBoards = gameTmp["winRecordBoards"] ?? [];
        _firstKnowledge =
            gameTmp["firstKnowledge"] ?? _getBlankFirstKnowledge(numBoards);
        pushUpSteps = gameTmp["pushUpSteps"] ?? 0;
        _expandingBoard = gameTmp["expandingBoard"] ?? false;
        _expandingBoardEver = gameTmp["expandingBoardEver"] ?? false;

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
      _gameEncodedLastCache = gameEncoded;
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
    gameTmp["targetWords"] = _targetWords;
    gameTmp["gUser"] = g.gUser;

    gameTmp["enteredWords"] = _enteredWords;
    gameTmp["winRecordBoards"] = _winRecordBoards;
    gameTmp["firstKnowledge"] = _firstKnowledge;
    gameTmp["pushUpSteps"] = pushUpSteps;
    gameTmp["expandingBoard"] = _expandingBoard;
    gameTmp["expandingBoardEver"] = _expandingBoardEver;

    return json.encode(gameTmp);
  }

  void _printCheatTargetWords() {
    if (cheatMode) {
      p([
        _targetWords,
        _enteredWords,
        _winRecordBoards,
        currentTypingString,
        _firstKnowledge,
        pushOffBoardRows,
        extraRows,
        pushUpSteps,
        abLiveNumRowsPerBoard,
        abCurrentRowInt,
      ]);
    }
  }

  String getCurrentTargetWordForBoard(int boardNumber) {
    if (boardNumber < _targetWords.length) {
    } else {
      p("getCurrentTargetWordForBoard error");
      _targetWords = _getNewTargetWords(numBoards);
    }
    return _targetWords[boardNumber];
  }

  String _getNewTargetWord() {
    String a = _targetWords[0];
    while (_targetWords.contains(a) || _enteredWords.contains(a)) {
      // Ensure a word we have never seen before
      a = winnableWords[random.nextInt(winnableWords.length)];
    }
    return a;
  }

  List<String> _getNewTargetWords(int numberOfBoards) {
    List<String> starterList = [];
    for (int i = 0; i < numberOfBoards; i++) {
      starterList.add(_getNewTargetWord());
    }
    return starterList;
  }

  List<String> getWinWords() {
    List<String> log = [];
    for (int i = 0; i < _winRecordBoards.length; i++) {
      if (_winRecordBoards[i] != -1) {
        log.add(_enteredWords[i]);
      }
    }
    return log;
  }

  int getFirstAbRowToShowOnBoardDueToKnowledge(int boardNumber) {
    if (_firstKnowledge.length != numBoards) {
      _firstKnowledge = _getBlankFirstKnowledge(numBoards);
      p("getFirstVisualRowToShowOnBoard error");
    }
    if (!_expandingBoard) {
      return pushOffBoardRows;
    } else if (boardNumber < _firstKnowledge.length) {
      return _firstKnowledge[boardNumber];
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
    for (int key in abCardFlourishFlipAnglesNotifier.value.keys) {
      for (int i = 0; i < cols; i++) {
        if (abCardFlourishFlipAnglesNotifier.value[key]![i] > 0) {
          count++;
        }
      }
      //count = (abCardFlourishFlipAngles[key]).where((x) => x > 0.0 ?? false).length + count;
    }
    return _enteredWords.length * cols - count;
  }

  void _setAbCardFlourishFlipAngle(int abRow, int column, double value) {
    abCardFlourishFlipAnglesNotifier.set(abRow, column, value);
    /*
    if (!abCardFlourishFlipAngles.containsKey(abRow)) {
      abCardFlourishFlipAngles[abRow] =
      List<RxDouble>.generate(cols, (i) => 0.0.obs);
    }
    abCardFlourishFlipAngles[abRow][column].value = value;

     */
  }

  void _clearBoardFlourishFlipRows() {
    for (int i = 0; i < boardFlourishFlipRowsNotifiers.length; i++) {
      _setBoardFlourishFlipRow(i, -1);
    }
  }

  // PRETTY MUCH PURE GETTERS AND SETTERS

  int get gbLiveNumRowsPerBoard => numRowsPerBoard + extraRows;

  int get abLiveNumRowsPerBoard =>
      numRowsPerBoard + extraRows + pushOffBoardRows;

  int get pushOffBoardRows =>
      _expandingBoard ? _firstKnowledge.cast<int>().reduce(min) : pushUpSteps;

  int get extraRows => pushUpSteps - pushOffBoardRows;

  int get abCurrentRowInt => _enteredWords.length;

  bool isBoardNormalHighlighted(int boardNumber) {
    return highlightedBoard == -1 || highlightedBoard == boardNumber;
  }

  void _setCurrentTyping(String text) {
    for (int i = 0; i < cols; i++) {
      if (i < text.length) {
        currentTypingNotifiers[i].value = text.substring(i, i + 1);
      } else {
        currentTypingNotifiers[i].value = "";
      }
    }
  }

  set illegalFiveLetterWord(bool tf) =>
      illegalFiveLetterWordNotifier.value = tf;

  set temporaryVisualOffsetForSlide(int value) =>
      temporaryVisualOffsetForSlideNotifier.value = value;

  set highlightedBoard(value) => highlightedBoardNotifier.value = value;

  void _setBoardFlourishFlipRow(int i, int val) {
    boardFlourishFlipRowsNotifiers[i].value = val;
  }

  bool get gameOver =>
      abCurrentRowInt >= abLiveNumRowsPerBoard &&
      _winRecordBoards.isNotEmpty &&
      _winRecordBoards[_winRecordBoards.length - 1] == -1;

  // PURE GETTERS

  bool get expandingBoard => _expandingBoard;

  bool get expandingBoardEver => _expandingBoardEver;

  List<dynamic> get targetWords => _targetWords;

  int get temporaryVisualOffsetForSlide =>
      temporaryVisualOffsetForSlideNotifier.value;

  int get highlightedBoard => highlightedBoardNotifier.value;

  get currentTypingString => currentTypingNotifiers
      .map((ValueNotifier<String> element) => element.value)
      .reduce((String value, String element) => value + element);

  String _getCurrentTypingAtCol(int col) {
    return currentTypingNotifiers[col].value;
  }

  bool get isIllegalFiveLetterWord => illegalFiveLetterWordNotifier.value;

  int getBoardFlourishFlipRow(int i) {
    return boardFlourishFlipRowsNotifiers[i].value;
  }
}

class _CustomMapNotifier extends ValueNotifier<Map<int, List<double>>> {
  _CustomMapNotifier() : super({});

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

List<int> _getBlankFirstKnowledge(int numberOfBoards) {
  return List.filled(numberOfBoards, 0);
}

Future<void> _sleep(int delayAfterMult) async {
  await Future.delayed(Duration(milliseconds: delayAfterMult), () {});
}

// Memoisation
class _LegalWord {
  Map<String, bool> legalWordCache = {};

  bool call(String word) {
    if (word.length != cols) {
      return false;
    }
    if (!legalWordCache.containsKey(word)) {
      if (legalWordCache.length > 3) {
        //reset cache to keep it short
        legalWordCache = {};
      }
      legalWordCache[word] = _isListContains(legalWords, word);
    }
    return legalWordCache[word]!; //null
  }
}

_LegalWord _isLegalWord = _LegalWord();

bool _isListContains(List<String> list, String bit) {
  //sorted list so this is faster than doing contains
  return binarySearch(list, bit) != -1;
}
