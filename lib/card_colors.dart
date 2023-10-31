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
    if (!listEqual(game.getFirstAbRowToShowOnBoardDueToKnowledgeAll(),
            firstRowsToShowCache) ||
        !listEqual(game.getCurrentTargetWords(), targetWordsCacheForKey) ||
        game.getAbCurrentRowInt() != abCurrentRowIntCache) {
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
    int abStart =
        5 * max(0, game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber));

    if (queryLetter == " ") {
      answer = Colors.transparent;
    }
    if (answer == null) {
      // get color for the keyboard based on best (green > yellow > grey) color on the grid
      for (var abPosition = abStart;
          abPosition < game.getAbCurrentRowInt() * 5;
          abPosition++) {
        if (game.getCardLetterAtAbIndex(abPosition) == queryLetter) {
          if (getAbCardColor(abPosition, boardNumber) == green) {
            answer = green;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (var abPosition = abStart;
          abPosition < game.getAbCurrentRowInt() * 5;
          abPosition++) {
        if (game.getCardLetterAtAbIndex(abPosition) == queryLetter) {
          if (getAbCardColor(abPosition, boardNumber) == amber) {
            answer = amber;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (var abPosition = abStart;
          abPosition < game.getAbCurrentRowInt() * 5;
          abPosition++) {
        if (game.getCardLetterAtAbIndex(abPosition) == queryLetter) {
          answer = Colors.transparent;
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
    if (abIndex >= game.getAbCurrentRowInt() * 5) {
      return Colors.transparent; // later rows
    }

    if (cardColorsCache.isEmpty ||
        cardColorsCache[0].length != (game.getAbCurrentRowInt() * 5) ||
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
    if (abIndex >= game.getAbCurrentRowInt() * 5) {
      return Colors.transparent; //later rows
    } else {
      String targetWord = game.getCurrentTargetWordForBoard(boardNumber);
      String testLetter = game.getCardLetterAtAbIndex(abIndex);
      int testAbRow = abIndex ~/ 5;
      int testColumn = abIndex % 5;
      if (targetWord[testColumn] == testLetter) {
        answer = green;
      } else if (targetWord.contains(testLetter)) {
        int numberOfThisLetterInTargetWord =
            testLetter.allMatches(targetWord).length;
        int numberOfYellowThisLetterToLeftInCardRow = 0;
        for (var i = 0; i < testColumn; i++) {
          if (game.getCardLetterAtAbIndex(testAbRow * 5 + i) == testLetter &&
              getAbCardColor(testAbRow * 5 + i, boardNumber) == amber) {
            numberOfYellowThisLetterToLeftInCardRow++;
          }
        }

        int numberOfGreenThisLetterInCardRow = 0;
        for (var i = 0; i < 5; i++) {
          if (game.getCardLetterAtAbIndex(testAbRow * 5 + i) == testLetter &&
              targetWord[i] == game.getCardLetterAtAbIndex(testAbRow * 5 + i)) {
            numberOfGreenThisLetterInCardRow++;
          }
        }

        if (numberOfThisLetterInTargetWord >
            numberOfYellowThisLetterToLeftInCardRow +
                numberOfGreenThisLetterInCardRow) {
          // full logic to deal with repeating letters. If only one letter matching targetWord, then always returns Amber
          answer = amber;
        } else {
          answer = Colors.transparent;
        }
      } else {
        answer = Colors.transparent;
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
    abCurrentRowIntCache = game.getAbCurrentRowInt();

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
      cardColorsCache.add(
          List<Color?>.generate((game.getAbCurrentRowInt() * 5), (i) => null));
    }
  }
}
