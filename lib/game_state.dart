import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_colors.dart';
import 'constants.dart';
import 'firebase_saves.dart';
import 'game_ephemeral.dart';
import 'google/google.dart';
import 'wordlist.dart';

const List<String> _cheatEnteredWordsInitial = <String>[
  "maple",
  "windy",
  "scour",
  "fight",
  "kebab",
];
const List<String> _cheatTargetWordsInitial = <String>[
  "scoff",
  "brunt",
  "armor",
  "tabby",
];
const List<String> _winnableWords = kWinnableWordsList;

final Random _random = Random();

/// Core game state for Infinitordle.
class GameState extends ChangeNotifier {
  GameState() {
    _userChangeListener();
  }

  static final Logger _log = Logger('GS');

  String get currentTypingString =>
      gameE.currentTypingString;

  //getters / setters
  List<String> get targetWords => _targetWords;

  int get pushUpSteps => pushUpStepsNotifier.value;

  set pushUpSteps(int value) => pushUpStepsNotifier.value = value;

  bool get expandingBoard => expandingBoardNotifier.value;

  set expandingBoard(bool val) => expandingBoardNotifier.value = val;

  bool get expandingBoardEver => _expandingBoardEver;

  //State to save
  final List<String> _targetWords = <String>["x"];
  final List<String> _enteredWords = <String>["x"];
  final List<int> _winRecordBoards = <int>[-1];
  final List<int> _firstKnowledge = <int>[-1];

  final ValueNotifier<int> pushUpStepsNotifier = ValueNotifier<int>(-1);
  ValueNotifier<bool> expandingBoardNotifier = ValueNotifier<bool>(false);
  bool _expandingBoardEver = false;


  //transitive state
  String _gameEncodedLastCache = "";
  final CustomMapNotifier abCardFlourishFlipAnglesNotifier =
      CustomMapNotifier(); //{}.obs;
  final List<ValueNotifier<int>> boardFlourishFlipRowsNotifiers =
      List<ValueNotifier<int>>.generate(
        cols,
        (int i) => ValueNotifier<int>(100),
      );
  final ValueNotifier<bool> illegalFiveLetterWordNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<int> targetWordsChangedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> currentRowChangedNotifier = ValueNotifier<int>(0);

  /// Resets the game state and initiates a new board.
  void initiateBoardState() {
    _copyTo(_targetWords, _getNewTargetWords(numBoards));
    _copyTo(_enteredWords, <String>[]);
    _copyTo(_winRecordBoards, <int>[]);
    _copyTo(_firstKnowledge, _getBlankFirstKnowledge(numBoards));
    pushUpSteps = 0;
    expandingBoard = false;
    _expandingBoardEver = false;

    //gameEncodedLastCache = ""; Don't reset else new d/l will show as change
    targetWordsChangedNotifier.value++;
    currentRowChangedNotifier.value++;

    if (cheatMode) {
      _cheatInitiate();
    }
    _stateChange();
  }

  /// Processes a legally entered 5-letter word guess.
  int handleLegalWordEnteredState() {
    // set some local variable to ensure threadsafe
    final int cardAbRowPreGuessToFix = gameS.abCurrentRowInt; //FIXME CALCED TWICE

    _enteredWords.add(currentTypingString);
    _winRecordBoards.add(-2); //Add now, fix value later

    currentRowChangedNotifier.value++;
    if (fBase.fbAnalytics) {
      fBase.analytics!.logLevelUp(level: _enteredWords.length);
    }

    //Test if it is correct word
    final int winningBoardToFix = _getWinningBoardFromWordEnteredInAbRow(
      cardAbRowPreGuessToFix,
    );
    final bool isWin = winningBoardToFix != -1; //FIXME CALCED TWICE

    if (!isWin) {
      _winRecordBoards[cardAbRowPreGuessToFix] = -1; //Confirm no win
    }

    return winningBoardToFix;
  }


  /// Records a win and generates a new target word for the board.
  void logWinAndSetNewWord(
    int winRecordBoardsIndexToFix,
    int winningBoardToFix,
    int firstKnowledgeToFix,
  ) {
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

    saveToFirebaseAndFilesystem();
    //setStateGlobal();
  }

  /// Initial state for debugging with cheat mode.
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

  /// Resets the game and saves the new state.
  void resetBoard() {
    _log.info("Reset board");
    initiateBoardState();
    if (fBase.fbAnalytics) {
      fBase.analytics!.logLevelStart(levelName: "Reset");
      fBase.analytics!.logLevelUp(level: _enteredWords.length);
    }
    saveToFirebaseAndFilesystem();
  }

  /// Toggles between normal and expanding board layout.
  void toggleExpandingBoardState() {
    if (expandingBoard) {
      expandingBoard = false;
    } else {
      expandingBoard = true;
      _expandingBoardEver = true;
    }
    saveToFirebaseAndFilesystem();
    _stateChange();
  }

  /// Returns the letter at a specific grid index.
  String getCardLetterAtAbIndex(int abIndex) {
    final int abRow = abIndex ~/ cols;
    final int col = abIndex % cols;
    try {
      if (abRow > abCurrentRowInt) {
        return "";
      } else if (abRow == abCurrentRowInt) {
        return gameE.getCurrentTypingAtCol(col);
      } else {
        return _enteredWords[abRow][col];
      }
    } catch (e) {
      _log.severe("Crash getCardLetterAtAbIndex $abIndex $e");
      return "";
    }
  }

  /// Checks if a specific board was won at a specific row index.
  bool getTestHistoricalAbWin(int abRow, int boardNumber) {
    return abRow > 0 &&
        _winRecordBoards.length > abRow &&
        _winRecordBoards[abRow] == boardNumber;
  }

  /// Logic to determine if a streak bonus (jump up) is applicable.
  bool getReadyForStreakAbRowReal(int abRow) {
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

  /// Getter for streak readiness of current row.
  bool get readyForStreakCurrentRow =>
      getReadyForStreakAbRowReal(abCurrentRowInt);

  /// Checks if a board has been solved within a given number of rows.
  bool getDetectBoardSolvedByABRow(int boardNumber, int maxAbRowToCheck) {
    for (
      int abRow = getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);
      abRow < min(abCurrentRowInt, maxAbRowToCheck);
      abRow++
    ) {
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

  /// Identifies which board (if any) matched the newly entered word.
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

  /// Loads game state from a JSON encoded string.
  void _loadFromEncodedState(String gameEncoded) {
    if (gameEncoded == "") {
      _log.severe("loadFromEncodedState empty");
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
          _log.severe("users dont match $tmpgUser ${g.gUser}");
          _stateChange();
          //don't load up
          return;
        }

        _copyTo(
          _targetWords,
          List<String>.from(
            gameTmp["targetWords"] ?? _getNewTargetWords(numBoards),
          ),
        );
        targetWordsChangedNotifier.value++;

        if (_targetWords.length != numBoards) {
          resetBoard();
          return;
        }

        _copyTo(
          _enteredWords,
          List<String>.from(gameTmp["enteredWords"] ?? <String>[]),
        );
        currentRowChangedNotifier.value++;

        _copyTo(
          _winRecordBoards,
          List<int>.from(gameTmp["winRecordBoards"] ?? <int>[]),
        );
        _copyTo(
          _firstKnowledge,
          List<int>.from(
            gameTmp["firstKnowledge"] ?? _getBlankFirstKnowledge(numBoards),
          ),
        );
        pushUpSteps = gameTmp["pushUpSteps"] ?? 0;
        expandingBoard = gameTmp["expandingBoard"] ?? false;
        _expandingBoardEver = gameTmp["expandingBoardEver"] ?? false;

        //TRANSITIONAL logic from old variable naming convention
        final int offsetRollback = gameTmp["offsetRollback"] ?? 0;
        if (offsetRollback != 0) {
          _log.severe("One-off migration");
          pushUpSteps = offsetRollback;
        }
        //TRANSITIONAL logic from old variable naming convention
      } catch (error) {
        _log.severe("loadFromEncodedState error $error");
      }
      _gameEncodedLastCache = gameEncoded;
      saveToFirebaseAndFilesystem();
      _stateChange();
    }
  }

  /// Encodes current game state into a JSON string.
  String _getEncodeCurrentGameState() {
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

  /// Utility for debug printing target words.
  void printCheatTargetWords() {
    if (cheatMode) {
      _log.fine(<dynamic>[
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

  /// Returns the target word for a specific board.
  String getCurrentTargetWordForBoard(int boardNumber) {
    if (boardNumber < _targetWords.length) {
    } else {
      _log.severe("getCurrentTargetWordForBoard error");
      _copyTo(_targetWords, _getNewTargetWords(numBoards));
    }
    return _targetWords[boardNumber];
  }

  /// Randomly selects a new target word not currently in use or recently guessed.
  String _getNewTargetWord() {
    String newTargetWord = _targetWords[0];
    while (_targetWords.contains(newTargetWord) ||
        _enteredWords.contains(newTargetWord)) {
      // Ensure a word we have never seen before
      newTargetWord = _winnableWords[_random.nextInt(_winnableWords.length)];
    }
    return newTargetWord;
  }

  /// Generates initial target words for all boards.
  List<String> _getNewTargetWords(int numberOfBoards) {
    final List<String> starterList = <String>[];
    for (int i = 0; i < numberOfBoards; i++) {
      starterList.add(_getNewTargetWord());
    }
    return starterList;
  }

  /// Returns a list of words that successfully solved boards.
  List<String> getWinWords() {
    final List<String> log = <String>[];
    for (int i = 0; i < _winRecordBoards.length; i++) {
      if (_winRecordBoards[i] != -1) {
        log.add(_enteredWords[i]);
      }
    }
    return log;
  }

  /// Calculates which row index is the first that should be visible for a board.
  int getFirstAbRowToShowOnBoardDueToKnowledge(int boardNumber) {
    if (_firstKnowledge.length != numBoards) {
      _copyTo(_firstKnowledge, _getBlankFirstKnowledge(numBoards));
      _log.severe("getFirstVisualRowToShowOnBoard error 1");
    }
    if (!expandingBoard) {
      return pushOffBoardRows;
    } else if (boardNumber < _firstKnowledge.length) {
      return _firstKnowledge[boardNumber];
    } else {
      _log.severe("getFirstVisualRowToShowOnBoard error 2");
      return 0;
    }
  }

  /// Returns the index of the last card relevant for coloring keys.
  int getLastCardToConsiderForKeyColors() {
    return _enteredWords.length * cols -
        abCardFlourishFlipAnglesNotifier.numberNotYetFlourishFlipped;
  }


  //setters

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

  /// Triggers update notification for listeners.
  void _stateChange() {
    notifyListeners();
    //setStateGlobal();
  }

  final List<String> _recentSnapshotsCache = <String>[];

  /// Loads game state from a Firebase snapshot.
  void loadFirebaseSnapshot(String? snapshotCurrentOrNull) {
    _log.info("loadFirebaseSnapshot");
    if (snapshotCurrentOrNull != null) {
      final String snapshotCurrent = snapshotCurrentOrNull;
      if (g.signedIn && !_recentSnapshotsCache.contains(snapshotCurrent)) {
        if (snapshotCurrent != _getEncodeCurrentGameState()) {
          _loadFromEncodedState(snapshotCurrent);
        }
        _recentSnapshotsCache.add(snapshotCurrent);
        if (_recentSnapshotsCache.length > 5) {
          _recentSnapshotsCache.removeAt(0);
        }
      }
    }
  }

  /// Listens to user auth changes to reload state.
  void _userChangeListener() {
    _loadFromFirebaseOrFilesystem(); //initial
    g.gUserNotifier.addListener(() {
      _loadFromFirebaseOrFilesystem();
      fBase.firebaseChangeListener(g.gUser, callback: loadFirebaseSnapshot);
    });
  }

  /// Loads state from either Firebase or local shared preferences.
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

  /// Saves state to local shared preferences and Firebase if possible.
  Future<void> saveToFirebaseAndFilesystem() async {
    final String gameEncoded = _getEncodeCurrentGameState();

    // save locally
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (fBase.firebaseOn && g.signedIn) {
      await fBase.firebasePush(g, gameEncoded);
    }
  }
}

/// Global singleton instance of [GameState].
final GameState gameS = GameState();

/// Notifier for managing card flip flourish animations.
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

void _copyTo<T>(List<T> to, List<T> from) {
  to
    ..clear()
    ..addAll(from);
}
