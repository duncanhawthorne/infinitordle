import 'dart:math';

import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class CardColors {
  Map<int, Map<int, Map<String, Color>>> cardColorsCache = {};
  Map<int, Map<String, Color>> keyColorsCache = {};

  List<dynamic> firstRowsToShowCache = List.filled(numBoards, 0);
  List<dynamic> targetWordsCacheForKey = List.filled(numBoards, "x");
  List<dynamic> targetWordsCacheForCard = List.filled(numBoards, "x");
  int getLastCardToConsiderForKeyColorsCache = 0;

  Color getBestColorForLetter(queryLetter, boardNumber) {
    if (game.getLastCardToConsiderForKeyColors() !=
            getLastCardToConsiderForKeyColorsCache ||
        !listEqual(game.getFirstAbRowToShowOnBoardDueToKnowledgeAll(),
            firstRowsToShowCache)) {
      resetKeyColorsCache();
    }

    if (game.getHighlightedBoard() != -1) {
      boardNumber = game.getHighlightedBoard();
    }

    String targetWord = game.getCurrentTargetWordForBoard(boardNumber);

    if (!keyColorsCache.containsKey(boardNumber) ||
        targetWordsCacheForKey[boardNumber] != targetWord) {
      keyColorsCache[boardNumber] = {};
      targetWordsCacheForKey[boardNumber] = targetWord;
    }

    if (!keyColorsCache[boardNumber]!.containsKey(queryLetter)) {
      keyColorsCache[boardNumber]![queryLetter] =
          getBestColorForLetterReal(queryLetter, boardNumber);
    }

    return keyColorsCache[boardNumber]![queryLetter]!;
  }

  Color getBestColorForLetterReal(queryLetter, boardNumber) {
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
      for (var abIndex = abStart; abIndex < abEnd; abIndex++) {
        if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
          if (getAbCardColor(abIndex, boardNumber) == green) {
            answer = green;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (var abIndex = abStart; abIndex < abEnd; abIndex++) {
        if (game.getCardLetterAtAbIndex(abIndex) == queryLetter) {
          if (getAbCardColor(abIndex, boardNumber) == amber) {
            answer = amber;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (var abIndex = abStart; abIndex < abEnd; abIndex++) {
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

  Color getAbCardColor(abIndex, boardNumber) {
    if (abIndex >= game.getAbCurrentRowInt() * cols) {
      // Later rows
      return transp;
    }
    String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
    String testLetter = game.getCardLetterAtAbIndex(abIndex);
    if (!cardColorsCache.containsKey(boardNumber) ||
        !cardColorsCache[boardNumber]![-1]!.containsKey(targetWord)) {
      cardColorsCache[boardNumber] = {
        -1: {targetWord: transp}
      };
    }
    if (!cardColorsCache[boardNumber]!.containsKey(abIndex) ||
        !cardColorsCache[boardNumber]![abIndex]!.containsKey(testLetter)) {
      cardColorsCache[boardNumber]![abIndex] = {
        testLetter: getAbCardColorReal(abIndex, boardNumber)
      };
    }
    return cardColorsCache[boardNumber]![abIndex]![testLetter]!;
  }

  Color getAbCardColorReal(abIndex, boardNumber) {
    Color? answer;
    if (abIndex >= game.getAbCurrentRowInt() * cols) {
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
        for (var i = 0; i < testColumn; i++) {
          if (game.getCardLetterAtAbIndex(testAbRow * cols + i) == testLetter &&
              getAbCardColor(testAbRow * cols + i, boardNumber) == amber) {
            numberOfYellowThisLetterToLeftInCardRow++;
          }
        }

        int numberOfGreenThisLetterInCardRow = 0;
        for (var i = 0; i < cols; i++) {
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

  void resetKeyColorsCache() {
    for (int i = 0; i < numBoards; i++) {
      targetWordsCacheForKey[i] = game.getCurrentTargetWordForBoard(i);
      firstRowsToShowCache[i] =
          game.getFirstAbRowToShowOnBoardDueToKnowledge(i);
    }
    getLastCardToConsiderForKeyColorsCache =
        game.getLastCardToConsiderForKeyColors();

    keyColorsCache = {};
  }
}
