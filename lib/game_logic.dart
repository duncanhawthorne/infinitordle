import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_colors.dart';
import 'constants.dart';
import 'firebase_saves.dart';
import 'google/google.dart';
import 'helper.dart';
import 'popup_screens.dart';
import 'wordlist.dart';

const List<String> _cheatEnteredWordsInitial = <String>[
  "maple",
  "windy",
  "scour",
  "fight",
  "kebab"
];
const List<String> _cheatTargetWordsInitial = <String>[
  "scoff",
  "brunt",
  "armor",
  "tabby"
];
const List<String> _legalWords = kLegalWordsList;
const List<String> _winnableWords = kWinnableWordsList;
const int _visualCatchUpTime = delayMult * 750;
const int _gradualRevealRowTime =
    gradualRevealDelayTime * (cols - 1) + flipTime;
final Random _random = Random();

class Game extends ValueNotifier<int> {
  Game() : super(0) {
    _userChangeListener();
  }

  //getters / setters
  List<dynamic> get targetWords => _targetWords;

  int get pushUpSteps => pushUpStepsNotifier.value;

  set pushUpSteps(int value) => pushUpStepsNotifier.value = value;

  bool get expandingBoard => expandingBoardNotifier.value;

  set expandingBoard(bool val) => expandingBoardNotifier.value = val;

  bool get expandingBoardEver => _expandingBoardEver;

  String get currentTypingString => currentTypingNotifiers
      .map((ValueNotifier<String> element) => element.value)
      .reduce((String value, String element) => value + element);

  int get highlightedBoard => highlightedBoardNotifier.value;

  set highlightedBoard(int value) => highlightedBoardNotifier.value = value;

  int get temporaryVisualOffsetForSlide =>
      temporaryVisualOffsetForSlideNotifier.value;

  set temporaryVisualOffsetForSlide(int value) =>
      temporaryVisualOffsetForSlideNotifier.value = value;

  bool get illegalFiveLetterWord => illegalFiveLetterWordNotifier.value;

  set illegalFiveLetterWord(bool tf) =>
      illegalFiveLetterWordNotifier.value = tf;

  //State to save
  final List<String> _targetWords = <String>["x"];
  final List<String> _enteredWords = <String>["x"];
  final List<int> _winRecordBoards = <int>[-1];
  final List<int> _firstKnowledge = <int>[-1];

  final ValueNotifier<int> pushUpStepsNotifier = ValueNotifier<int>(-1);
  ValueNotifier<bool> expandingBoardNotifier = ValueNotifier<bool>(false);
  bool _expandingBoardEver = false;

  //Other state non-saved
  final List<ValueNotifier<String>> currentTypingNotifiers =
      List<ValueNotifier<String>>.generate(
          cols, (int i) => ValueNotifier<String>(""));
  final ValueNotifier<int> highlightedBoardNotifier = ValueNotifier<int>(0);

  //transitive state
  final ValueNotifier<int> temporaryVisualOffsetForSlideNotifier =
      ValueNotifier<int>(0);
  String _gameEncodedLastCache = "";
  final CustomMapNotifier abCardFlourishFlipAnglesNotifier =
      CustomMapNotifier(); //{}.obs;
  final List<ValueNotifier<int>> boardFlourishFlipRowsNotifiers =
      List<ValueNotifier<int>>.generate(
          cols, (int i) => ValueNotifier<int>(100));
  final ValueNotifier<bool> illegalFiveLetterWordNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<int> targetWordsChangedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> currentRowChangedNotifier = ValueNotifier<int>(0);

  void initiateBoard() {
    _copyTo(_targetWords, _getNewTargetWords(numBoards));
    _copyTo(_enteredWords, <String>[]);
    _copyTo(_winRecordBoards, <int>[]);
    _copyTo(_firstKnowledge, _getBlankFirstKnowledge(numBoards));
    pushUpSteps = 0;
    expandingBoard = false;
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
    _stateChange();
  }

  void onKeyboardTapped(String letter) {
    _printCheatTargetWords();

    if (letter == " ") {
      //Ignore pressing of non-keys
    } else if (letter == "<") {
      //Backspace key
      if (currentTypingString.isNotEmpty) {
        //There is text to delete
        final String origTyping =
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
    final int cardAbRowPreGuessToFix = abCurrentRowInt;
    final int firstKnowledgeToFix = extraRows + pushOffBoardRows;
    final int maxAbRowOfBoard = abLiveNumRowsPerBoard;

    _enteredWords.add(currentTypingString);
    _setCurrentTyping("");
    _winRecordBoards.add(-2); //Add now, fix value later
    currentRowChangedNotifier.value++;
    if (fBase.fbAnalytics) {
      fBase.analytics!.logLevelUp(level: _enteredWords.length);
    }

    //Test if it is correct word
    final int winningBoardToFix =
        _getWinningBoardFromWordEnteredInAbRow(cardAbRowPreGuessToFix);
    final bool isWin = winningBoardToFix != -1;

    if (!isWin) {
      _winRecordBoards[cardAbRowPreGuessToFix] = -1; //Confirm no win
    }

    //save.saveKeys();
    //setStateGlobal(); //non-ephemeral state change, so needs setState

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
      Future<Null>.delayed(Duration(milliseconds: gradualRevealDelayTime * i),
          () {
        _setAbCardFlourishFlipAngle(abRow, i, 0.0);
        if (i == cols - 1) {
          if (abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
            // Due to delays check still exists before remove
            abCardFlourishFlipAnglesNotifier.remove(abRow);
            //setStateGlobal(); //needed to refresh keyboard
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
    await _sleep(_gradualRevealRowTime + _visualCatchUpTime);

    //Code for losing game
    if (!isWin && cardAbRowPreGuessToFix + 1 >= maxAbRowOfBoard) {
      //All rows full, game over
      unawaited(_saveToFirebaseAndFilesystem());
      unawaited(showMainPopupScreen());
    } else if (!infMode && isWin) {
      //Code for totally winning game across all boards
      unawaited(_saveToFirebaseAndFilesystem());
      bool totallySolvedLocal = true;
      for (int i = 0; i < numBoards; i++) {
        if (!getDetectBoardSolvedByABRow(i, cardAbRowPreGuessToFix + 1)) {
          totallySolvedLocal = false;
        }
      }
      if (totallySolvedLocal) {
        // Leave the screen as is
      }
    } else if (infMode && isWin) {
      unawaited(_handleWinningWordEntered(
          cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix));
    } else {
      unawaited(_saveToFirebaseAndFilesystem());
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
    await _sleep(_visualCatchUpTime);
  }

  void _takeOneStepBack() {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables
    pushUpSteps++;
    //save.saveKeys();
    //setStateGlobal();
  }

  Future<void> _unflipSwapFlip(int cardAbRowPreGuessToFix,
      int winningBoardToFix, int firstKnowledgeToFix) async {
    //unflip
    _setBoardFlourishFlipRow(winningBoardToFix, cardAbRowPreGuessToFix);
    //setStateGlobal();
    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime - flipTime);

    // Log the win officially, and get a new word
    _logWinAndSetNewWord(
        cardAbRowPreGuessToFix, winningBoardToFix, firstKnowledgeToFix);

    //flip
    _setBoardFlourishFlipRow(winningBoardToFix, -1);
    //setStateGlobal();
    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime);
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

    _saveToFirebaseAndFilesystem();
    //setStateGlobal();
  }

  void _cheatInitiate() {
    // Speed initialise known entries using cheat mode for debugging
    for (int i = 0; i < numBoards; i++) {
      if (_cheatTargetWordsInitial.length > i) {
        _targetWords[i] = _cheatTargetWordsInitial[i];
      } else {
        _targetWords[i] = _getNewTargetWord();
      }
    }
    for (int i = 0; i < _cheatEnteredWordsInitial.length; i++) {
      _enteredWords.add(_cheatEnteredWordsInitial[i]);
      _winRecordBoards.add(-1);
    }
  }

  void resetBoard() {
    logGlobal("Reset board");
    initiateBoard();
    if (fBase.fbAnalytics) {
      fBase.analytics!.logLevelStart(levelName: "Reset");
      fBase.analytics!.logLevelUp(level: _enteredWords.length);
    }
    _saveToFirebaseAndFilesystem();
  }

  void toggleExpandingBoardState() {
    if (expandingBoard) {
      expandingBoard = false;
    } else {
      expandingBoard = true;
      _expandingBoardEver = true;
    }
    _saveToFirebaseAndFilesystem();
    _stateChange();
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
    final int abRow = abIndex ~/ cols;
    final int col = abIndex % cols;
    try {
      if (abRow > abCurrentRowInt) {
        return "";
      } else if (abRow == abCurrentRowInt) {
        return _getCurrentTypingAtCol(col);
      } else {
        return _enteredWords[abRow][col];
      }
    } catch (e) {
      logGlobal(<Object>["Crash getCardLetterAtAbIndex", abIndex, e]);
      return "";
    }
  }

  bool getTestHistoricalAbWin(int abRow, int boardNumber) {
    return abRow > 0 &&
        _winRecordBoards.length > abRow &&
        _winRecordBoards[abRow] == boardNumber;
  }

  bool _getReadyForStreakAbRowReal(int abRow) {
    if (abRow < 2) {
      return false;
    }
    for (int q = 0; q < 2; q++) {
      if (!(abRow - 1 - q < 0 || _winRecordBoards[abRow - 1 - q] != -1)) {
        return false;
      }
    }
    return true;
  }

  bool get readyForStreakCurrentRow =>
      _getReadyForStreakAbRowReal(abCurrentRowInt);

  bool getDetectBoardSolvedByABRow(int boardNumber, int maxAbRowToCheck) {
    for (int abRow = getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);
        abRow < min(abCurrentRowInt, maxAbRowToCheck);
        abRow++) {
      bool result = true;
      for (int column = 0; column < cols; column++) {
        final int abIndex = abRow * cols + column;
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
    int winningBoardToFix = -1;
    for (int board = 0; board < numBoards; board++) {
      if (getCurrentTargetWordForBoard(board) ==
          _enteredWords[cardAbRowPreGuessToFix]) {
        winningBoardToFix = board;
      }
    }
    return winningBoardToFix;
  }

  void _loadFromEncodedState(String gameEncoded) {
    if (gameEncoded == "") {
      logGlobal(<String>["loadFromEncodedState empty"]);
      _stateChange();
    } else if (gameEncoded != _gameEncodedLastCache) {
      try {
        Map<String, dynamic> gameTmp = <String, dynamic>{};
        gameTmp = json.decode(gameEncoded);

        final String tmpgUser = gameTmp["gUser"] ?? "Default";
        if (tmpgUser != g.gUser && tmpgUser != "Default") {
          //Error state, so set gUser properly and redo loadKeys from firebase
          //g.forceResetUserTo(tmpgUser);
          //_loadFromFirebaseOrFilesystem();
          logGlobal(<String>["users dont match", tmpgUser, g.gUser]);
          _stateChange();
          //don't load up
          return;
        }

        _copyTo(_targetWords,
            gameTmp["targetWords"] ?? _getNewTargetWords(numBoards));
        targetWordsChangedNotifier.value++;

        if (_targetWords.length != numBoards) {
          resetBoard();
          return;
        }

        _copyTo(_enteredWords, gameTmp["enteredWords"] ?? <String>[]);
        currentRowChangedNotifier.value++;

        _copyTo(_winRecordBoards, gameTmp["winRecordBoards"] ?? <int>[]);
        _copyTo(_firstKnowledge,
            gameTmp["firstKnowledge"] ?? _getBlankFirstKnowledge(numBoards));
        pushUpSteps = gameTmp["pushUpSteps"] ?? 0;
        expandingBoard = gameTmp["expandingBoard"] ?? false;
        _expandingBoardEver = gameTmp["expandingBoardEver"] ?? false;

        //TRANSITIONAL logic from old variable naming convention
        final int offsetRollback = gameTmp["offsetRollback"] ?? 0;
        if (offsetRollback != 0) {
          logGlobal(<String>["One-off migration"]);
          pushUpSteps = offsetRollback;
        }
        //TRANSITIONAL logic from old variable naming convention
      } catch (error) {
        logGlobal(<Object>["loadFromEncodedState error", error]);
      }
      _gameEncodedLastCache = gameEncoded;
      _saveToFirebaseAndFilesystem();
      _stateChange();
    }
  }

  String getEncodeCurrentGameState() {
    final Map<String, dynamic> gameStateTmp = <String, dynamic>{};
    gameStateTmp["targetWords"] = _targetWords;
    gameStateTmp["gUser"] = g.gUser;

    gameStateTmp["enteredWords"] = _enteredWords;
    gameStateTmp["winRecordBoards"] = _winRecordBoards;
    gameStateTmp["firstKnowledge"] = _firstKnowledge;
    gameStateTmp["pushUpSteps"] = pushUpSteps;
    gameStateTmp["expandingBoard"] = expandingBoard;
    gameStateTmp["expandingBoardEver"] = _expandingBoardEver;

    return json.encode(gameStateTmp);
  }

  void _printCheatTargetWords() {
    if (cheatMode) {
      logGlobal(<dynamic>[
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
      logGlobal("getCurrentTargetWordForBoard error");
      _copyTo(_targetWords, _getNewTargetWords(numBoards));
    }
    return _targetWords[boardNumber];
  }

  String _getNewTargetWord() {
    String newTargetWord = _targetWords[0];
    while (_targetWords.contains(newTargetWord) ||
        _enteredWords.contains(newTargetWord)) {
      // Ensure a word we have never seen before
      newTargetWord = _winnableWords[_random.nextInt(_winnableWords.length)];
    }
    return newTargetWord;
  }

  List<String> _getNewTargetWords(int numberOfBoards) {
    final List<String> starterList = <String>[];
    for (int i = 0; i < numberOfBoards; i++) {
      starterList.add(_getNewTargetWord());
    }
    return starterList;
  }

  List<String> getWinWords() {
    final List<String> log = <String>[];
    for (int i = 0; i < _winRecordBoards.length; i++) {
      if (_winRecordBoards[i] != -1) {
        log.add(_enteredWords[i]);
      }
    }
    return log;
  }

  int getFirstAbRowToShowOnBoardDueToKnowledge(int boardNumber) {
    if (_firstKnowledge.length != numBoards) {
      _copyTo(_firstKnowledge, _getBlankFirstKnowledge(numBoards));
      logGlobal("getFirstVisualRowToShowOnBoard error 1");
    }
    if (!expandingBoard) {
      return pushOffBoardRows;
    } else if (boardNumber < _firstKnowledge.length) {
      return _firstKnowledge[boardNumber];
    } else {
      logGlobal("getFirstVisualRowToShowOnBoard error 2");
      return 0;
    }
  }

  int getLastCardToConsiderForKeyColors() {
    return _enteredWords.length * cols -
        abCardFlourishFlipAnglesNotifier.numberNotYetFlourishFlipped;
  }

  void _setAbCardFlourishFlipAngle(int abRow, int column, double value) {
    abCardFlourishFlipAnglesNotifier.set(abRow, column, value);
  }

  void _clearBoardFlourishFlipRows() {
    for (int i = 0; i < boardFlourishFlipRowsNotifiers.length; i++) {
      _setBoardFlourishFlipRow(i, -1);
    }
  }

  //setters

  void _setCurrentTyping(String text) {
    for (int i = 0; i < cols; i++) {
      if (i < text.length) {
        currentTypingNotifiers[i].value = text.substring(i, i + 1);
      } else {
        currentTypingNotifiers[i].value = "";
      }
    }
  }

  void _setBoardFlourishFlipRow(int i, int val) {
    boardFlourishFlipRowsNotifiers[i].value = val;
  }

  //getters

  int get gbLiveNumRowsPerBoard => numRowsPerBoard + extraRows;

  int get abLiveNumRowsPerBoard =>
      numRowsPerBoard + extraRows + pushOffBoardRows;

  int get pushOffBoardRows =>
      expandingBoard ? _firstKnowledge.cast<int>().reduce(min) : pushUpSteps;

  int get extraRows => pushUpSteps - pushOffBoardRows;

  int get abCurrentRowInt => _enteredWords.length;

  bool get gameOver =>
      abCurrentRowInt >= abLiveNumRowsPerBoard &&
      _winRecordBoards.isNotEmpty &&
      _winRecordBoards[_winRecordBoards.length - 1] == -1;

  bool isBoardNormalHighlighted(int boardNumber) {
    return highlightedBoard == -1 || highlightedBoard == boardNumber;
  }

  String _getCurrentTypingAtCol(int col) {
    return currentTypingNotifiers[col].value;
  }

  int getBoardFlourishFlipRow(int i) {
    return boardFlourishFlipRowsNotifiers[i].value;
  }

  void _stateChange() {
    notifyListeners();
    //notifyListeners(); //setStateGlobal();
  }

  final List<String> _recentSnapshotsCache = <String>[];

  void loadFirebaseSnapshot(Map<String, dynamic>? userDocument) {
    logGlobal("loadFirebaseSnapshot");
    if (userDocument != null) {
      final String snapshotCurrent = userDocument["data"];
      if (g.signedIn && !_recentSnapshotsCache.contains(snapshotCurrent)) {
        if (snapshotCurrent != getEncodeCurrentGameState()) {
          _loadFromEncodedState(snapshotCurrent);
        }
        _recentSnapshotsCache.add(snapshotCurrent);
        if (_recentSnapshotsCache.length > 5) {
          _recentSnapshotsCache.removeAt(0);
        }
      }
    }
  }

  void _userChangeListener() {
    _loadFromFirebaseOrFilesystem(); //initial
    g.gUserNotifier.addListener(() {
      _loadFromFirebaseOrFilesystem();
      _firebaseChangeListener(g.gUser);
    });
  }

  void _firebaseChangeListener(String userId) {
    // ignore: always_specify_types
    StreamSubscription? listener;
    listener = fBase.db!
        .collection('states')
        .doc(userId)
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      //useId is fixed for the duration of listener
      if (g.gUser != userId) {
        listener!.cancel();
        return;
      }
      loadFirebaseSnapshot(snapshot.data());
    });
  }

  Future<void> _loadFromFirebaseOrFilesystem() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!fBase.firebaseOn || !g.signedIn) {
      // load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      // load from firebase
      gameEncoded = await fBase.firebasePull(g);
    }
    _loadFromEncodedState(gameEncoded);
  }

  Future<void> _saveToFirebaseAndFilesystem() async {
    final String gameEncoded = getEncodeCurrentGameState();

    // save locally
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (fBase.firebaseOn && g.signedIn) {
      unawaited(fBase.firebasePush(g, gameEncoded));
    }
  }
}

final Game game = Game();

class CustomMapNotifier extends ValueNotifier<Map<int, List<double>>> {
  CustomMapNotifier() : super(<int, List<double>>{});

  int _numberNonZeroItems() {
    int count = 0;
    for (int key in value.keys) {
      for (int i = 0; i < cols; i++) {
        if (value[key]![i] > 0) {
          count++;
        }
      }
    }
    return count;
  }

  int numberNotYetFlourishFlipped = 0;

  void set(int abRow, int column, double tvalue) {
    if (!value.containsKey(abRow)) {
      value[abRow] = List<double>.generate(cols, (int i) => 0.0);
    }
    value[abRow]![column] = tvalue;
    numberNotYetFlourishFlipped = _numberNonZeroItems();
    notifyListeners();
  }

  void remove(int key) {
    if (value.containsKey(key)) {
      value.remove(key);
    }
    numberNotYetFlourishFlipped = _numberNonZeroItems();
    notifyListeners();
  }
}

List<int> _getBlankFirstKnowledge(int numberOfBoards) {
  return List<int>.filled(numberOfBoards, 0);
}

Future<void> _sleep(int delayAfterMult) async {
  await Future<Null>.delayed(Duration(milliseconds: delayAfterMult), () {});
}

// Memoisation
class _LegalWord {
  Map<String, bool> _legalWordCache = <String, bool>{};

  bool call(String word) {
    if (word.length != cols) {
      return false;
    }
    if (!_legalWordCache.containsKey(word)) {
      if (_legalWordCache.length > 3) {
        //reset cache to keep it short
        _legalWordCache = <String, bool>{};
      }
      _legalWordCache[word] = _isListContains(_legalWords, word);
    }
    return _legalWordCache[word]!; //null
  }
}

_LegalWord _isLegalWord = _LegalWord();

bool _isListContains(List<String> list, String bit) {
  //sorted list so this is faster than doing contains
  return binarySearch(list, bit) != -1;
}

void _copyTo(List<dynamic> to, List<dynamic> from) {
  to.clear();
  for (dynamic item in from) {
    to.add(item);
  }
}
