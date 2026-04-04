import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'flips_state_notifier.dart';
import 'state.dart';

class Flips {
  final FlipsStateNotifier abCardFlourishFlipAnglesNotifier =
      FlipsStateNotifier(); //{}.obs;
  final List<ValueNotifier<int>> boardFlourishFlipRowsNotifiers =
      List<ValueNotifier<int>>.generate(
        cols,
        (int i) => ValueNotifier<int>(100),
      );

  /// Resets the game state and initiates a new board.
  void initiateBoardFlips() {
    abCardFlourishFlipAnglesNotifier.clear();
    _clearBoardFlourishFlipRows();
  }

  /// Animates the reveal of a row's colors letter by letter.
  void gradualRevealAbRow(int abRow) {
    // flip to reveal the colors with pleasing animation
    for (int i = 0; i < cols; i++) {
      _setAbCardFlourishFlipAngle(abRow, i, 0.5);
    }
    for (int i = 0; i < cols; i++) {
      Future<void>.delayed(
        Duration(milliseconds: gradualRevealDelayTime * i),
        () {
          _setAbCardFlourishFlipAngle(abRow, i, 0.0);
          if (i == cols - 1) {
            if (abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
              // Due to delays check still exists before remove
              abCardFlourishFlipAnglesNotifier.remove(abRow);
            }
          }
        },
      );
    }
  }

  /// Returns the index of the last card relevant for coloring keys.
  int getLastCardToConsiderForKeyColors() {
    return state.abCurrentRowInt * cols -
        abCardFlourishFlipAnglesNotifier.numberNotYetFlourishFlipped;
  }

  /// Helper to set card flip angles for flourishing animations.
  void _setAbCardFlourishFlipAngle(int abRow, int column, double value) {
    abCardFlourishFlipAnglesNotifier.set(abRow, column, value);
  }

  /// Resets flourish animation state for all boards.
  void _clearBoardFlourishFlipRows() {
    for (int i = 0; i < boardFlourishFlipRowsNotifiers.length; i++) {
      setBoardFlourishFlipRow(i, -1);
    }
  }

  //setters

  /// Sets flourish flip animation row for a board.
  void setBoardFlourishFlipRow(int i, int val) {
    boardFlourishFlipRowsNotifiers[i].value = val;
  }

  /// Returns flourish flip row for a board.
  int getBoardFlourishFlipRow(int i) {
    return boardFlourishFlipRowsNotifiers[i].value;
  }

  /// Calculates the current flip angle (in 0.0-1.0 range) for a specific card.
  /// [abIndex] is the absolute card index, [boardNumber] identifies the board.
  double getFlipAngle(int abIndex, int boardNumber) {
    final int abRow = abIndex ~/ cols;
    final double cardFlipAngle =
        _getPermFlipAngle(abIndex) - _getFlourishFlipAngle(abIndex);
    final double boardFlipAngle = abRow <= state.abCurrentRowInt
        ? _getFlourishBoardFlipAngle(boardNumber)
        : 0;
    return max(0, cardFlipAngle - boardFlipAngle);
  }

  /// Returns 0.5 (flipped) if the row has been entered, otherwise 0.
  double _getPermFlipAngle(int abIndex) {
    final int abRow = abIndex ~/ cols;
    return abRow >= state.abCurrentRowInt ? 0 : 0.5;
  }

  /// Retrieves the temporary flourish flip angle from the game logic notifier.
  double _getFlourishFlipAngle(int abIndex) {
    final int abRow = abIndex ~/ cols;
    final int col = abIndex % cols;
    if (!abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
      return 0;
    } else {
      return abCardFlourishFlipAnglesNotifier.value[abRow]![col];
    }
  }

  /// Returns 0.5 if the entire board is undergoing a flourish flip, otherwise 0.
  double _getFlourishBoardFlipAngle(int boardNumber) {
    return getBoardFlourishFlipRow(boardNumber) == -1 ? 0 : 0.5;
  }
}

final Flips flips = Flips();
