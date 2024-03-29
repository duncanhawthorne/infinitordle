import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class CardColors {
  var cardColorsCache = [];
  var keyColorsCache = [];

  List<dynamic> firstRowsToShowCache = List.filled(numBoards, 0);
  List<dynamic> targetWordsCacheForKey = List.filled(numBoards, "x");
  List<dynamic> targetWordsCacheForCard = List.filled(numBoards, "x");
  int abCurrentRowIntCache = 0;

  Color getBestColorForLetter(kbIndex, boardNumber) {
    if (game.getLastCardToConsiderForKeyColors() != abCurrentRowIntCache ||
        !listEqual(game.getFirstAbRowToShowOnBoardDueToKnowledgeAll(),
            firstRowsToShowCache) ||
        !listEqual(game.getCurrentTargetWords(), targetWordsCacheForKey)) {
      resetKeyColorsCache();
    }

    if (game.getHighlightedBoard() != -1) {
      boardNumber = game.getHighlightedBoard();
    }
    if (boardNumber < keyColorsCache.length &&
        kbIndex < keyColorsCache[boardNumber].length) {
      Color? cacheColorAnswer = keyColorsCache[boardNumber][kbIndex];
      if (cacheColorAnswer != null) {
        return cacheColorAnswer;
      } else {
        // Haven't cached that get, so do so in the function below
      }
    } else {
      // blank the cache
      resetKeyColorsCache();
    }

    Color? answer;
    String queryLetter = keyboardList[kbIndex];
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
    keyColorsCache[boardNumber][kbIndex] = answer;
    return answer;
  }

  Color getAbCardColor(abIndex, boardNumber) {
    if (abIndex >= game.getAbCurrentRowInt() * cols) {
      // Later rows
      return transp;
    }

    if (cardColorsCache.isEmpty ||
        cardColorsCache[0].length != (game.getAbCurrentRowInt() * cols) ||
        !listEqual(game.getCurrentTargetWords(), targetWordsCacheForCard)) {
      resetCardColorsCache();
    }
    if (boardNumber < cardColorsCache.length &&
        abIndex < cardColorsCache[boardNumber].length) {
      Color? cacheColorAnswer = cardColorsCache[boardNumber][abIndex];
      if (cacheColorAnswer != null) {
        return cacheColorAnswer;
      } else {
        //Haven't cached that get, so do so in the function below
      }
    } else {
      //blank the cache
      resetCardColorsCache();
    }

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

    cardColorsCache[boardNumber][abIndex] = answer;
    return answer;
  }

  void resetKeyColorsCache() {
    for (int i = 0; i < numBoards; i++) {
      targetWordsCacheForKey[i] = game.getCurrentTargetWords()[i];
      firstRowsToShowCache[i] =
          game.getFirstAbRowToShowOnBoardDueToKnowledge(i);
    }
    abCurrentRowIntCache = game.getLastCardToConsiderForKeyColors();

    keyColorsCache = [];
    for (int i = 0; i < numBoards; i++) {
      keyColorsCache.add(List<Color?>.generate((30), (i) => null));
    }
  }

  void resetCardColorsCache() {
    for (int i = 0; i < numBoards; i++) {
      targetWordsCacheForCard[i] = game.getCurrentTargetWords()[i];
    }
    cardColorsCache = [];
    for (int i = 0; i < numBoards; i++) {
      cardColorsCache.add(List<Color?>.generate(
          (game.getAbCurrentRowInt() * cols), (i) => null));
    }
  }
}
