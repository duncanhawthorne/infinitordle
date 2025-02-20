import 'dart:math';

import 'constants.dart';
import 'game_logic.dart';

class Flips {
  Flips({required this.game});

  final Game game;

  double getFlipAngle(int abIndex, int boardNumber) {
    final int abRow = abIndex ~/ cols;
    final double cardFlipAngle =
        _getPermFlipAngle(abIndex) - _getFlourishFlipAngle(abIndex);
    final double boardFlipAngle =
        abRow <= game.abCurrentRowInt
            ? _getFlourishBoardFlipAngle(boardNumber)
            : 0;
    return max(0, cardFlipAngle - boardFlipAngle);
  }

  double _getPermFlipAngle(int abIndex) {
    final int abRow = abIndex ~/ cols;
    return abRow >= game.abCurrentRowInt ? 0 : 0.5;
  }

  double _getFlourishFlipAngle(int abIndex) {
    final int abRow = abIndex ~/ cols;
    final int col = abIndex % cols;
    if (!game.abCardFlourishFlipAnglesNotifier.value.containsKey(abRow)) {
      return 0;
    } else {
      return game.abCardFlourishFlipAnglesNotifier.value[abRow]![col];
    }
  }

  double _getFlourishBoardFlipAngle(int boardNumber) {
    return game.getBoardFlourishFlipRow(boardNumber) == -1 ? 0 : 0.5;
  }
}

final Flips flips = Flips(game: game);
