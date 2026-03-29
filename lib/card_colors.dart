import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_logic.dart';

/// Manages the colors of cards and keyboard keys based on game state and logic.
class CardColors {
  CardColors({required this.game});

  final Game game;

  final Map<int, Map<int, Map<String, Color>>> _cardColorsCache =
      <int, Map<int, Map<String, Color>>>{};
  final Map<int, Map<String, Color>> _keyColorsCache =
      <int, Map<String, Color>>{};

  final List<int> _firstRowsToShowCache = List<int>.filled(numBoards, 0);
  final List<String> _targetWordsCacheForKey = List<String>.filled(
    numBoards,
    "x",
  );
  int _getLastCardToConsiderForKeyColorsCache = 0;

  /// Returns the best color (Green > Amber > Grey) for a letter on the keyboard for a specific board.
  Color getBestColorForKeyboardLetter(String letter, int boardNumber) {
    final bool isGlobalCacheInvalid =
        game.getLastCardToConsiderForKeyColors() !=
        _getLastCardToConsiderForKeyColorsCache;

    if (isGlobalCacheInvalid) {
      _getLastCardToConsiderForKeyColorsCache =
          game.getLastCardToConsiderForKeyColors();
      _keyColorsCache.clear();
    }

    if (game.highlightedBoard != -1) {
      //only care about color from highlighted board, if highlighted
      boardNumber = game.highlightedBoard;
    }

    final String targetWord = game.getCurrentTargetWordForBoard(boardNumber);

    final bool isBoardCacheInvalid =
        !_keyColorsCache.containsKey(boardNumber) ||
        _targetWordsCacheForKey[boardNumber] != targetWord ||
        game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) !=
            _firstRowsToShowCache[boardNumber];

    if (isBoardCacheInvalid) {
      _keyColorsCache[boardNumber] = <String, Color>{};
      _targetWordsCacheForKey[boardNumber] = targetWord;
      _firstRowsToShowCache[boardNumber] = game
          .getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);
    }

    final Map<String, Color> keyColorsCacheForBoard =
        _keyColorsCache[boardNumber]!;
    if (!keyColorsCacheForBoard.containsKey(letter)) {
      keyColorsCacheForBoard[letter] = _getBestColorForKeyboardLetterReal(
        letter,
        boardNumber,
      );
    }

    return keyColorsCacheForBoard[letter]!;
  }

  /// Checks if a letter of a specific color exists on the board within a range of rows.
  bool _cardOnBoardOfColor(
    Color? color,
    String queryLetter,
    int boardNumber,
    int abStart,
    int abEnd,
  ) {
    //for transp, just check the existence of the letter rather than color
    for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
      if (game.getCardLetterAtAbIndex(abIndex) == queryLetter &&
          (color == transp || getAbCardColor(abIndex, boardNumber) == color)) {
        return true;
      }
    }
    return false;
  }

  static const List<Color> _cardColorsPriority = <Color>[green, amber, transp];

  /// Internal logic to find the best color for a keyboard letter.
  Color _getBestColorForKeyboardLetterReal(
    String queryLetter,
    int boardNumber,
  ) {
    if (queryLetter == " ") {
      assert(false);
      return transp;
    }

    final int abStart =
        cols *
        max(0, game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber));
    final int abEnd = game.getLastCardToConsiderForKeyColors();

    // get color for the keyboard based on best (green > yellow > grey) color on the grid
    for (Color color in _cardColorsPriority) {
      if (_cardOnBoardOfColor(
        color,
        queryLetter,
        boardNumber,
        abStart,
        abEnd,
      )) {
        return color;
      }
    }
    return grey; //not used yet by the player
  }

  /// Returns the color of a card at [abIndex] for a specific [boardNumber].
  Color getAbCardColor(int abIndex, int boardNumber) {
    if (abIndex >= game.abCurrentRowInt * cols) {
      // Later rows
      return transp;
    }
    final String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
    final String testLetter = game.getCardLetterAtAbIndex(abIndex);
    if (!_cardColorsCache.containsKey(boardNumber) ||
        !_cardColorsCache[boardNumber]![-1]!.containsKey(targetWord)) {
      _cardColorsCache[boardNumber] = <int, Map<String, Color>>{
        -1: <String, Color>{targetWord: transp},
      };
    }
    if (!_cardColorsCache[boardNumber]!.containsKey(abIndex) ||
        !_cardColorsCache[boardNumber]![abIndex]!.containsKey(testLetter)) {
      _cardColorsCache[boardNumber]![abIndex] = <String, Color>{
        testLetter: _getAbCardColorReal(abIndex, boardNumber),
      };
    }
    return _cardColorsCache[boardNumber]![abIndex]![testLetter]!;
  }

  /// Counts how many times [testLetter] appears as a 'Green' (correct spot) match in a row.
  int _countGreenThisLetterThisRow(
    int testAbRow,
    String testLetter,
    String targetWord,
  ) {
    int numberOfGreenThisLetterInCardRow = 0;
    for (int i = 0; i < cols; i++) {
      if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
          targetWord[i] == testLetter) {
        numberOfGreenThisLetterInCardRow++;
      }
    }
    return numberOfGreenThisLetterInCardRow;
  }

  /// Counts 'Yellow' matches for [testLetter] to the left of [testColumn] in a row.
  int _countYellowToLeftThisLetterThisRow(
    int testAbRow,
    String testLetter,
    String targetWord,
    int testColumn,
    int boardNumber,
  ) {
    int numberOfYellowThisLetterToLeftInCardRow = 0;
    for (int i = 0; i < testColumn; i++) {
      if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
          getAbCardColor(testAbRow * cols + i, boardNumber) == amber) {
        numberOfYellowThisLetterToLeftInCardRow++;
      }
    }
    return numberOfYellowThisLetterToLeftInCardRow;
  }

  /// Determines if a letter that is in the word but wrong column should be colored Amber or Transparent.
  Color _colorForRightLetterWrongColumn(
    int testAbRow,
    String testLetter,
    String targetWord,
    int testColumn,
    int boardNumber,
  ) {
    final int numberThisLetterInTargetWord =
        testLetter.allMatches(targetWord).length;

    final int numberYellowToLeftThisLetterThisRow =
        _countYellowToLeftThisLetterThisRow(
          testAbRow,
          testLetter,
          targetWord,
          testColumn,
          boardNumber,
        );

    final int numberGreenThisLetterThisRow = _countGreenThisLetterThisRow(
      testAbRow,
      testLetter,
      targetWord,
    );

    //note if only one letter matching targetWord, then always returns Amber
    return numberThisLetterInTargetWord >
            numberYellowToLeftThisLetterThisRow + numberGreenThisLetterThisRow
        ? amber
        : transp;
  }

  /// Internal logic to calculate the color of a card.
  Color _getAbCardColorReal(int abIndex, int boardNumber) {
    if (abIndex >= game.abCurrentRowInt * cols) {
      return transp; //later rows
    }
    final String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
    final String testLetter = game.getCardLetterAtAbIndex(abIndex);
    final int testAbRow = abIndex ~/ cols;
    final int testColumn = abIndex % cols;
    if (targetWord[testColumn] == testLetter) {
      return green;
    } else if (!targetWord.contains(testLetter)) {
      return transp;
    } else {
      return _colorForRightLetterWrongColumn(
        testAbRow,
        testLetter,
        targetWord,
        testColumn,
        boardNumber,
      );
    }
  }
}

/// Global instance of [CardColors] to be used across the app.
final CardColors cardColors = CardColors(game: game);
