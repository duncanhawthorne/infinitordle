import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'constants.dart';
import 'game_flips.dart';
import 'game_ephemeral.dart';
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

  set _temporaryVisualOffsetForSlide(int value) =>
      temporaryVisualOffsetForSlideNotifier.value = value;

  bool get illegalFiveLetterWord => illegalFiveLetterWordNotifier.value;

  set _illegalFiveLetterWord(bool tf) =>
      illegalFiveLetterWordNotifier.value = tf;

  //transitive state
  final ValueNotifier<int> temporaryVisualOffsetForSlideNotifier =
      ValueNotifier<int>(0);

  final ValueNotifier<bool> illegalFiveLetterWordNotifier = ValueNotifier<bool>(
    false,
  );

  /// Resets the game state and initiates a new board.
  void initiateBoard() {
    gameS.initiateBoardState();

    gameE.initiateBoardEphemeral();

    _temporaryVisualOffsetForSlide = 0;
    //gameEncodedLastCache = ""; Don't reset else new d/l will show as change
    gameF.initiateBoardFlips();
    _illegalFiveLetterWord = false;

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
          _illegalFiveLetterWord = false;
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
          _illegalFiveLetterWord = true;
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

    gameF.gradualRevealAbRow(cardAbRowPreGuessToFix);
    _handleWinLoseState(
      cardAbRowPreGuessToFix,
      winningBoardToFix,
      firstKnowledgeToFix,
      isWin,
      maxAbRowOfBoard,
    );
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
        gameS.saveState(),
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
      await gameS.saveState();
    } else if (infMode && isWin) {
      await _handleWinningWordEntered(
        cardAbRowPreGuessToFix,
        winningBoardToFix,
        firstKnowledgeToFix,
      );
    } else {
      await gameS.saveState();
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
    _temporaryVisualOffsetForSlide = 1;

    // Delay for sliding cards up to have taken effect
    await _sleep(slideTime);

    // Undo the visual slide (and do this instantaneously)
    _temporaryVisualOffsetForSlide = 0;

    // Actually move the cards up, so state matches visual illusion above
    gameS.takeOneStepBack();

    // Pause, so can temporarily see new position
    await _sleep(_visualCatchUpTime);
  }

  /// Animates the flipping and resetting of a solved board.
  Future<void> _unflipSwapFlip(
    int cardAbRowPreGuessToFix,
    int winningBoardToFix,
    int firstKnowledgeToFix,
  ) async {
    //unflip
    gameF.setBoardFlourishFlipRow(winningBoardToFix, cardAbRowPreGuessToFix);
    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime - flipTime);

    // Log the win officially, and get a new word
    gameS.logWinAndSetNewWordState(
      cardAbRowPreGuessToFix,
      winningBoardToFix,
      firstKnowledgeToFix,
    );

    _stateChange();

    //flip
    gameF.setBoardFlourishFlipRow(winningBoardToFix, -1);

    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime);
  }

  /// Triggers update notification for listeners.
  void _stateChange() {
    notifyListeners();
  }
}

/// Global singleton instance of [GameOrchestrator].
final GameOrchestrator gameO = GameOrchestrator();

Future<void> _sleep(int delayAfterMult) async {
  await Future<void>.delayed(Duration(milliseconds: delayAfterMult), () {});
}

bool _isLegalWord(String word) {
  return word.length == cols && _legalWordsSet.contains(word);
}
