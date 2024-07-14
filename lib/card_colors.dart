import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'helper.dart';

class CardColors {
  final Map<int, Map<int, Map<String, Color>>> _cardColorsCache = {};
  final Map<int, Map<String, Color>> _keyColorsCache = {};

  final List<int> _firstRowsToShowCache = List.filled(numBoards, 0);
  final List<String> _targetWordsCacheForKey = List.filled(numBoards, "x");
  int _getLastCardToConsiderForKeyColorsCache = 0;

  Color getBestColorForLetter(String queryLetter, int boardNumber) {
    if (game.getLastCardToConsiderForKeyColors() !=
            _getLastCardToConsiderForKeyColorsCache ||
        !listEqual(game.getFirstAbRowToShowOnBoardDueToKnowledgeAll(),
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
    Color? answer;
    //String queryLetter = keyboardList[kbIndex];
    int abStart = cols *
        max(0, game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber));
    int abEnd = game.getLastCardToConsiderForKeyColors();

    if (queryLetter == " ") {
      answer = transp;
    }
    if (answer == null) {
      // get color for the keyboard based on best (green > yellow > grey) color on the grid
      for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
        if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
          if (getAbCardColor(abIndex, boardNumber) == green) {
            answer = green;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
        if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
          if (getAbCardColor(abIndex, boardNumber) == amber) {
            answer = amber;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (int abIndex = abStart; abIndex < abEnd; abIndex++) {
        if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
          answer = transp;
          break;
        }
      }
    }
    // ignore: prefer_conditional_assignment
    if (answer == null) {
      answer = grey; //not used yet by the player
    }
    return answer;
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

  Color _getAbCardColorReal(abIndex, boardNumber) {
    Color? answer;
    if (abIndex >= game.abCurrentRowInt * cols) {
      return transp; //later rows
    } else {
      String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
      String testLetter = game.getCardLetterAtAbIndex(abIndex);
      int testAbRow = abIndex ~/ cols;
      int testColumn = abIndex % cols;
      if (targetWord[testColumn] == testLetter) {
        answer = green;
      } else if (targetWord.contains(testLetter)) {
        int numberOfThisLetterInTargetWord =
            testLetter.allMatches(targetWord).length;
        int numberOfYellowThisLetterToLeftInCardRow = 0;
        for (int i = 0; i < testColumn; i++) {
          if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
              getAbCardColor(testAbRow * cols + i, boardNumber) == amber) {
            numberOfYellowThisLetterToLeftInCardRow++;
          }
        }

        int numberOfGreenThisLetterInCardRow = 0;
        for (int i = 0; i < cols; i++) {
          if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
              targetWord[i] ==
                  game.getCardLetterAtAbIndex(testAbRow * cols + i)) {
            numberOfGreenThisLetterInCardRow++;
          }
        }

        if (numberOfThisLetterInTargetWord >
            numberOfYellowThisLetterToLeftInCardRow +
                numberOfGreenThisLetterInCardRow) {
          // full logic to deal with repeating letters. If only one letter matching targetWord, then always returns Amber
          answer = amber;
        } else {
          answer = transp;
        }
      } else {
        answer = transp;
      }
    }

    return answer;
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
