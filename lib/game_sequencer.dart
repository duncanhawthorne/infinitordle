import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'constants.dart';
import 'game_flips.dart';
import 'game_ephemeral.dart';
import 'game_state.dart';
import 'popup_screens.dart';

const int _visualCatchUpTime = delayMult * 750;
const int _gradualRevealRowTime =
    gradualRevealDelayTime * (cols - 1) + flipTime;

/// Game orchestrator for Infinitordle.
class GameSequencer {

  // ignore: unused_field
  static final Logger _log = Logger('OR');

  int get temporaryVisualOffsetForSlide =>
      temporaryVisualOffsetForSlideNotifier.value;

  set _temporaryVisualOffsetForSlide(int value) =>
      temporaryVisualOffsetForSlideNotifier.value = value;

  //transitive state
  final ValueNotifier<int> temporaryVisualOffsetForSlideNotifier =
      ValueNotifier<int>(0);

  /// Resets the game state and initiates a new board.
  void initiateBoard() {
    gameState.initiateBoardState();

    gameEphemeral.initiateBoardEphemeral();

    _temporaryVisualOffsetForSlide = 0;
    //gameEncodedLastCache = ""; Don't reset else new d/l will show as change
    gameFlips.initiateBoardFlips();
  }

  /// Handles user input from the on-screen keyboard.
  void onKeyboardTapped(String letter) {
    gameState.printCheatTargetWords();

    if (letter == kNonKey) {
      //Ignore pressing of non-keys
    } else if (letter == kBackspace) {
      gameEphemeral.onBackspaceTapped();
    } else if (letter == kEnter) {
      onEnterTapped();
    } else {
      gameEphemeral.onLetterTapped(letter);
    }
  }

  void onEnterTapped() {
    //Submit guess
    final String typingPreTap = gameEphemeral.currentTypingString;
    if (typingPreTap.length == cols) {
      //Full word entered, so can submit
      if (isLegalWord(typingPreTap) &&
          gameState.abCurrentRowInt < gameState.abLiveNumRowsPerBoard) {
        //Legal word so can enter the word
        //Note, not necessarily correct word
        _handleLegalWordEntered();
      }
    }
  }

  /// Processes a legally entered 5-letter word guess.
  void _handleLegalWordEntered() {
    // set some local variable to ensure threadsafe
    final int cardAbRowPreGuessToFix =
        gameState.abCurrentRowInt; //FIXME CALCED TWICE
    final int firstKnowledgeToFix =
        gameState.extraRows + gameState.pushOffBoardRows;
    final int maxAbRowOfBoard = gameState.abLiveNumRowsPerBoard;

    final int winningBoardToFix = gameState.handleLegalWordEnteredState(
      gameEphemeral.currentTypingString,
    );
    final bool isWin = winningBoardToFix != -1; //FIXME CALCED TWICE
    gameEphemeral.setCurrentTyping("");

    gameFlips.gradualRevealAbRow(cardAbRowPreGuessToFix);
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
        gameState.saveState(),
        showMainPopupScreen(),
      ]);
    } else if (!infMode && isWin) {
      //Code for totally winning game across all boards
      bool totallySolvedLocal = true;
      for (int i = 0; i < numBoards; i++) {
        if (!gameState.getDetectBoardSolvedByABRow(
          i,
          cardAbRowPreGuessToFix + 1,
        )) {
          totallySolvedLocal = false;
        }
      }
      if (totallySolvedLocal) {
        // Leave the screen as is
      }
      await gameState.saveState();
    } else if (infMode && isWin) {
      await _handleWinningWordEntered(
        cardAbRowPreGuessToFix,
        winningBoardToFix,
        firstKnowledgeToFix,
      );
    } else {
      await gameState.saveState();
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

    if (gameState.getReadyForStreakAbRowReal(cardAbRowPreGuessToFix)) {
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
    gameState.takeOneStepBack();

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
    gameFlips.setBoardFlourishFlipRow(
      winningBoardToFix,
      cardAbRowPreGuessToFix,
    );
    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime - flipTime);

    // Log the win officially, and get a new word
    gameState.logWinAndSetNewWordState(
      cardAbRowPreGuessToFix,
      winningBoardToFix,
      firstKnowledgeToFix,
    );

    //flip
    gameFlips.setBoardFlourishFlipRow(winningBoardToFix, -1);

    await _sleep(flipTime);
    await _sleep(_visualCatchUpTime);
  }

}

/// Global singleton instance of [GameSequencer].
final GameSequencer gameSequencer = GameSequencer();

Future<void> _sleep(int delayAfterMult) async {
  await Future<void>.delayed(Duration(milliseconds: delayAfterMult), () {});
}
