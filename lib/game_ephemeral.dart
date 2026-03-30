import 'package:flutter/foundation.dart';

import 'constants.dart';

/// Ephemeral game state for Infinitordle.
class GameEphemeral {
  GameEphemeral();

  String get currentTypingString => currentTypingNotifiers
      .map((ValueNotifier<String> element) => element.value)
      .join();

  int get highlightedBoard => highlightedBoardNotifier.value;

  set highlightedBoard(int value) => highlightedBoardNotifier.value = value;

  /// Resets the game state and initiates a new board.
  void initiateBoardEphemeral() {
    setCurrentTyping("");
    highlightedBoard = -1;
  }

  //Other state non-saved
  final List<ValueNotifier<String>> currentTypingNotifiers =
      List<ValueNotifier<String>>.generate(
        cols,
        (int i) => ValueNotifier<String>(""),
      );
  final ValueNotifier<int> highlightedBoardNotifier = ValueNotifier<int>(0);

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
      highlightedBoard = -1; //if already set turn off
    } else {
      highlightedBoard = boardNumber;
    }
    //No need to save as local state
  }

  /// Checks if a board should be highlighted or dimmed.
  bool isBoardNormalHighlighted(int boardNumber) {
    return highlightedBoard == -1 || highlightedBoard == boardNumber;
  }
}

/// Global singleton instance of [GameEphemeral].
final GameEphemeral gameE = GameEphemeral();
