import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_logic.dart';

class CardColors {
  CardColors({required this.game});

  final Game game;

  final Map<int, Map<int, Map<String, Color>>> _cardColorsCache = {};
  final Map<int, Map<String, Color>> _keyColorsCache = {};

  final List<int> _firstRowsToShowCache = List.filled(numBoards, 0);
  final List<String> _targetWordsCacheForKey = List.filled(numBoards, "x");
  int _getLastCardToConsiderForKeyColorsCache = 0;

  Color getBestColorForLetter(String queryLetter, int boardNumber) {
    if (game.getLastCardToConsiderForKeyColors() !=
            _getLastCardToConsiderForKeyColorsCache ||
        !listEquals(game.getFirstAbRowToShowOnBoardDueToKnowledgeAll(),
            _firstRowsToShowCache)) {
      _resetKeyColorsCache();
    }

    if (game.highlightedBoard != -1) {
      boardNumber = game.highlightedBoard;
    }

    String targetWord = game.getCurrentTargetWordForBoard(boardNumber);

    if (!_keyColorsCache.containsKey(boardNumber) ||
        _targetWordsCacheForKey[boardNumber] != targetWord) {
      _keyColorsCache[boardNumber] = {};
      _targetWordsCacheForKey[boardNumber] = targetWord;
    }

    if (!_keyColorsCache[boardNumber]!.containsKey(queryLetter)) {
      _keyColorsCache[boardNumber]![queryLetter] =
          _getBestColorForLetterReal(queryLetter, boardNumber);
    }

    return _keyColorsCache[boardNumber]![queryLetter]!;
  }

  Color _getBestColorForLetterReal(queryLetter, boardNumber) {
    int abStart = cols *
        max(0, game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber));
    int abEnd = game.getLastCardToConsiderForKeyColors();

    if (queryLetter == " ") {
      return transp;
    }
    // get color for the keyboard based on best (green > yellow > grey) color on the grid
    for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
      if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
        if (getAbCardColor(abIndex, boardNumber) == green) {
          return green;
        }
      }
    }
    for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
      if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
        if (getAbCardColor(abIndex, boardNumber) == amber) {
          return amber;
        }
      }
    }
    for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
      if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
        return transp;
      }
    }
    return grey; //not used yet by the player
  }

  Color getAbCardColor(int abIndex, int boardNumber) {
    if (abIndex >= game.abCurrentRowInt * cols) {
      // Later rows
      return transp;
    }
    String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
    String testLetter = game.getCardLetterAtAbIndex(abIndex);
    if (!_cardColorsCache.containsKey(boardNumber) ||
        !_cardColorsCache[boardNumber]![-1]!.containsKey(targetWord)) {
      _cardColorsCache[boardNumber] = {
        -1: {targetWord: transp}
      };
    }
    if (!_cardColorsCache[boardNumber]!.containsKey(abIndex) ||
        !_cardColorsCache[boardNumber]![abIndex]!.containsKey(testLetter)) {
      _cardColorsCache[boardNumber]![abIndex] = {
        testLetter: _getAbCardColorReal(abIndex, boardNumber)
      };
    }
    return _cardColorsCache[boardNumber]![abIndex]![testLetter]!;
  }

  int _countGreenThisLetterThisRow(
      int testAbRow, String testLetter, String targetWord) {
    int numberOfGreenThisLetterInCardRow = 0;
    for (int i = 0; i < cols; i++) {
      if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
          targetWord[i] == game.getCardLetterAtAbIndex(testAbRow * cols + i)) {
        numberOfGreenThisLetterInCardRow++;
      }
    }
    return numberOfGreenThisLetterInCardRow;
  }

  int _countYellowToLeftThisLetterThisRow(int testAbRow, String testLetter,
      String targetWord, int testColumn, int boardNumber) {
    int numberOfYellowThisLetterToLeftInCardRow = 0;
    for (int i = 0; i < testColumn; i++) {
      if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
          getAbCardColor(testAbRow * cols + i, boardNumber) == amber) {
        numberOfYellowThisLetterToLeftInCardRow++;
      }
    }
    return numberOfYellowThisLetterToLeftInCardRow;
  }

  Color colorForRightLetterWrongColumn(int testAbRow, String testLetter,
      String targetWord, int testColumn, int boardNumber) {
    int numberThisLetterInTargetWord = testLetter.allMatches(targetWord).length;

    int numberYellowToLeftThisLetterThisRow =
        _countYellowToLeftThisLetterThisRow(
            testAbRow, testLetter, targetWord, testColumn, boardNumber);

    int numberGreenThisLetterThisRow =
        _countGreenThisLetterThisRow(testAbRow, testLetter, targetWord);

    //note if only one letter matching targetWord, then always returns Amber
    return numberThisLetterInTargetWord >
            numberYellowToLeftThisLetterThisRow + numberGreenThisLetterThisRow
        ? amber
        : transp;
  }

  Color _getAbCardColorReal(abIndex, boardNumber) {
    if (abIndex >= game.abCurrentRowInt * cols) {
      return transp; //later rows
    } else {
      String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
      String testLetter = game.getCardLetterAtAbIndex(abIndex);
      int testAbRow = abIndex ~/ cols;
      int testColumn = abIndex % cols;
      if (targetWord[testColumn] == testLetter) {
        return green;
      } else if (!targetWord.contains(testLetter)) {
        return transp;
      } else {
        return colorForRightLetterWrongColumn(
            testAbRow, testLetter, targetWord, testColumn, boardNumber);
      }
    }
  }

  void _resetKeyColorsCache() {
    for (int i = 0; i < numBoards; i++) {
      _targetWordsCacheForKey[i] = game.getCurrentTargetWordForBoard(i);
      _firstRowsToShowCache[i] =
          game.getFirstAbRowToShowOnBoardDueToKnowledge(i);
    }
    _getLastCardToConsiderForKeyColorsCache =
        game.getLastCardToConsiderForKeyColors();

    _keyColorsCache.clear();
  }
}

final CardColors cardColors = CardColors(game: game);
