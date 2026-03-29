import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'constants.dart';
import 'game_ephemeral.dart';
import 'game_io.dart';
import 'game_state.dart';
import 'popup_screens.dart';
import 'wordlist.dart';

const Set<String> _legalWordsSet = <String>{...kLegalWordsList};

const int _visualCatchUpTime = delayMult * 750;
const int _gradualRevealRowTime =
    gradualRevealDelayTime * (cols - 1) + flipTime;

/// Game orchestrator for Infinitordle.
class GameOrchestrator extends ChangeNotifier {
  GameOrchestrator();

  // ignore: unused_field
  static final Logger _log = Logger('OR');

  int get temporaryVisualOffsetForSlide =>
      temporaryVisualOffsetForSlideNotifier.value;

  set temporaryVisualOffsetForSlide(int value) =>
      temporaryVisualOffsetForSlideNotifier.value = value;

  bool get illegalFiveLetterWord => illegalFiveLetterWordNotifier.value;

  set illegalFiveLetterWord(bool tf) =>
      illegalFiveLetterWordNotifier.value = tf;

  //transitive state
  final ValueNotifier<int> temporaryVisualOffsetForSlideNotifier =
      ValueNotifier<int>(0);

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

  /// Resets the game state and initiates a new board.
  void initiateBoard() {
    gameS.initiateBoardState();

    gameE.initiateBoardEphemeral();

    temporaryVisualOffsetForSlide = 0;
    //gameEncodedLastCache = ""; Don't reset else new d/l will show as change
    for (int item in abCardFlourishFlipAnglesNotifier.value.keys) {
      abCardFlourishFlipAnglesNotifier.remove(item);
    }
    _clearBoardFlourishFlipRows();
    illegalFiveLetterWord = false;

    _stateChange();
  }

  /// Handles user input from the on-screen keyboard.
  void onKeyboardTapped(String letter) {
    gameS.printCheatTargetWords();
    final String typingPreTap = gameE.currentTypingString;
    if (letter == kNonKey) {
      //Ignore pressing of non-keys
    } else if (letter == kBackspace) {
      //Backspace key
      if (typingPreTap.isNotEmpty) {
        //There is text to delete
        gameE.setCurrentTyping(
          typingPreTap.substring(0, typingPreTap.length - 1),
        );
        if (illegalFiveLetterWord) {
          illegalFiveLetterWord = false;
        }
      }
    } else if (letter == kEnter) {
      //Submit guess
      if (typingPreTap.length == cols) {
        //Full word entered, so can submit
        if (_isLegalWord(typingPreTap) &&
            gameS.abCurrentRowInt < gameS.abLiveNumRowsPerBoard) {
          //Legal word so can enter the word
          //Note, not necessarily correct word
          _handleLegalWordEntered();
        }
      }
    } else {
      //pressing regular letter key
      if (typingPreTap.length < cols) {
        //Space to add extra letter
        gameE.setCurrentTyping(typingPreTap + letter);
        final String typingPostTap = gameE.currentTypingString;
        if (typingPostTap.length == cols && !_isLegalWord(typingPostTap)) {
          illegalFiveLetterWord = true;
        }
      }
    }
  }

  /// Processes a legally entered 5-letter word guess.
  void _handleLegalWordEntered() {
    // set some local variable to ensure threadsafe
    final int cardAbRowPreGuessToFix =
        gameS.abCurrentRowInt; //FIXME CALCED TWICE
    final int firstKnowledgeToFix = gameS.extraRows + gameS.pushOffBoardRows;
    final int maxAbRowOfBoard = gameS.abLiveNumRowsPerBoard;

    final int winningBoardToFix = gameS.handleLegalWordEnteredState(
      gameE.currentTypingString,
    );
    final bool isWin = winningBoardToFix != -1; //FIXME CALCED TWICE
    gameE.setCurrentTyping("");

    _gradualRevealAbRow(cardAbRowPreGuessToFix);
    _handleWinLoseState(
      cardAbRowPreGuessToFix,
      winningBoardToFix,
      firstKnowledgeToFix,
      isWin,
      maxAbRowOfBoard,
    );
  }

  /// Animates the reveal of a row's colors letter by letter.
  void _gradualRevealAbRow(int abRow) {
    // flip to reveal the colors with pleasing animation
    for (int i = 0; i < cols; i++) {
      _setAbCardFlourishFlipAngle(abRow, i, 0.5);
    }
    //setStateGlobal();
    for (int i = 0; i < cols; i++) {
      Future<Null>.delayed(
        Duration(milliseconds: gradualRevealDelayTime * i),
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
        },
      );
    }
  }

  /// Handles game flow after a word has been revealed, checking for win or loss.
  Future<void> _handleWinLoseState(
    int cardAbRowPreGuessToFix,
    int winningBoardToFix,
    int firstKnowledgeToFix,
    bool isWin,
    int maxAbRowOfBoard,
  ) async {
    //Delay for visual changes to have taken effect
    await _sleep(_gradualRevealRowTime + _visualCatchUpTime);

    //Code for losing game
    if (!isWin && cardAbRowPreGuessToFix + 1 >= maxAbRowOfBoard) {
      //All rows full, game over
      await Future.wait(<Future<void>>[
        gameI.saveToFirebaseAndFilesystem(),
        showMainPopupScreen(),
      ]);
    } else if (!infMode && isWin) {
      //Code for totally winning game across all boards
      bool totallySolvedLocal = true;
      for (int i = 0; i < numBoards; i++) {
        if (!gameS.getDetectBoardSolvedByABRow(i, cardAbRowPreGuessToFix + 1)) {
          totallySolvedLocal = false;
        }
      }
      if (totallySolvedLocal) {
        // Leave the screen as is
      }
      await gameI.saveToFirebaseAndFilesystem();
    } else if (infMode && isWin) {
      await _handleWinningWordEntered(
        cardAbRowPreGuessToFix,
        winningBoardToFix,
        firstKnowledgeToFix,
      );
    } else {
      await gameI.saveToFirebaseAndFilesystem();
    }
  }

  /// Logic specifically for when a correct word is guessed in infinite mode.
  Future<void> _handleWinningWordEntered(
    int cardAbRowPreGuessToFix,
    int winningBoardToFix,
    int firstKnowledgeToFix,
  ) async {
    //Slide up and increment firstKnowledge
    await _slideUpAnimation();
    firstKnowledgeToFix++;

    if (gameS.getReadyForStreakAbRowReal(cardAbRowPreGuessToFix)) {
      // Streak, so need to take another step back

      //Slide up and increment firstKnowledge
      await _slideUpAnimation();
      firstKnowledgeToFix++;
    }

    await _unflipSwapFlip(
      cardAbRowPreGuessToFix,
      winningBoardToFix,
      firstKnowledgeToFix,
    );
  }

  /// Visual animation for boards sliding up.
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

  /// Increments state to shift boards up.
  void _takeOneStepBack() {
    // This function is run after a delay so need to make sure threadsafe
    // Use variables at the time word was entered rather than live variables
    gameS.pushUpSteps++;
    //save.saveKeys();
    //setStateGlobal();
  }

  /// Animates the flipping and resetting of a solved board.
  Future<void> _unflipSwapFlip(
    int cardAbRowPreGuessToFix,
    int winningBoardToFix,
    int firstKnowledgeToFix,
  ) async {
    //unflip
    _setBoardFlourishFlipRow(winningBoardToFix, cardAbRowPreGuessToFix);
    //setStateGlobal();
    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime - flipTime);

    // Log the win officially, and get a new word
    gameS.logWinAndSetNewWord(
      cardAbRowPreGuessToFix,
      winningBoardToFix,
      firstKnowledgeToFix,
    );

    _stateChange();

    //flip
    _setBoardFlourishFlipRow(winningBoardToFix, -1);

    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime);
  }

  /// Returns the index of the last card relevant for coloring keys.
  int getLastCardToConsiderForKeyColors() {
    return gameS.abCurrentRowInt * cols -
        abCardFlourishFlipAnglesNotifier.numberNotYetFlourishFlipped;
  }

  /// Helper to set card flip angles for flourishing animations.
  void _setAbCardFlourishFlipAngle(int abRow, int column, double value) {
    abCardFlourishFlipAnglesNotifier.set(abRow, column, value);
  }

  /// Resets flourish animation state for all boards.
  void _clearBoardFlourishFlipRows() {
    for (int i = 0; i < boardFlourishFlipRowsNotifiers.length; i++) {
      _setBoardFlourishFlipRow(i, -1);
    }
  }

  //setters

  /// Sets flourish flip animation row for a board.
  void _setBoardFlourishFlipRow(int i, int val) {
    boardFlourishFlipRowsNotifiers[i].value = val;
  }

  /// Returns flourish flip row for a board.
  int getBoardFlourishFlipRow(int i) {
    return boardFlourishFlipRowsNotifiers[i].value;
  }

  /// Triggers update notification for listeners.
  void _stateChange() {
    notifyListeners();
    //setStateGlobal();
  }
}

/// Global singleton instance of [GameOrchestrator].
final GameOrchestrator gameO = GameOrchestrator();

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

Future<void> _sleep(int delayAfterMult) async {
  await Future<Null>.delayed(Duration(milliseconds: delayAfterMult), () {});
}

bool _isLegalWord(String word) {
  return word.length == cols && _legalWordsSet.contains(word);
}
