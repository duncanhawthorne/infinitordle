import 'package:flutter/foundation.dart';

import 'constants.dart';

/// Ephemeral game state for Infinitordle.
class GameEphemeral {
  GameEphemeral();

  String get currentTypingString => currentTypingNotifiers
      .map((ValueNotifier<String> element) => element.value)
      .join();

  int get highlightedBoard => highlightedBoardNotifier.value;

  set _highlightedBoard(int value) => highlightedBoardNotifier.value = value;

  bool get illegalFiveLetterWord => illegalFiveLetterWordNotifier.value;

  set _illegalFiveLetterWord(bool tf) =>
      illegalFiveLetterWordNotifier.value = tf;

  final List<ValueNotifier<String>> currentTypingNotifiers =
      List<ValueNotifier<String>>.generate(
        cols,
        (int i) => ValueNotifier<String>(""),
      );
  final ValueNotifier<int> highlightedBoardNotifier = ValueNotifier<int>(0);

  final ValueNotifier<bool> illegalFiveLetterWordNotifier = ValueNotifier<bool>(
    false,
  );

  /// Resets the game state and initiates a new board.
  void initiateBoardEphemeral() {
    setCurrentTyping("");
    _highlightedBoard = -1;
    _illegalFiveLetterWord = false;
  }

  void onBackspaceTapped() {
    final String typingPreTap = currentTypingString;
    //Backspace key
    if (typingPreTap.isNotEmpty) {
      //There is text to delete
      setCurrentTyping(typingPreTap.substring(0, typingPreTap.length - 1));
      if (illegalFiveLetterWord) {
        _illegalFiveLetterWord = false;
      }
    }
  }

  void onLetterTapped(String letter) {
    final String typingPreTap = currentTypingString;
    //pressing regular letter key
    if (typingPreTap.length < cols) {
      //Space to add extra letter
      setCurrentTyping(typingPreTap + letter);
      final String typingPostTap = currentTypingString;
      if (typingPostTap.length == cols && !isLegalWord(typingPostTap)) {
        _illegalFiveLetterWord = true;
      }
    }
  }

  /// Returns currently typed letter at a column.
  String getCurrentTypingAtCol(int col) {
    return currentTypingNotifiers[col].value;
  }

  /// Updates current typing state and notifies relevant watchers.
  void setCurrentTyping(String text) {
    for (int i = 0; i < cols; i++) {
      if (i < text.length) {
        currentTypingNotifiers[i].value = text.substring(i, i + 1);
      } else {
        currentTypingNotifiers[i].value = "";
      }
    }
  }

  /// Highlights a specific board for focus.
  void toggleHighlightedBoard(int boardNumber) {
    if (highlightedBoard == boardNumber) {
      _highlightedBoard = -1; //if already set turn off
    } else {
      _highlightedBoard = boardNumber;
    }
  }

  /// Checks if a board should be highlighted or dimmed.
  bool isBoardNormalHighlighted(int boardNumber) {
    return highlightedBoard == -1 || highlightedBoard == boardNumber;
  }
}

/// Global singleton instance of [GameEphemeral].
final GameEphemeral gameEphemeral = GameEphemeral();
