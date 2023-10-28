import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

class CardColors {
  var cardColorsCache = [];
  var keyColorsCache = [];
  //int keyAndCardColorsTestedStateCache = 0;

  var getCardLetterAtIndex = game.getCardLetterAtIndex; //for typing ease only
  var getVisualCurrentRowInt =
      game.getVisualCurrentRowInt; //for typing ease only

  Color getBestColorForLetter(index, boardNumber) {
    if (game.getHighlightedBoard() != -1) {
      boardNumber = game.getHighlightedBoard();
    }
    if (boardNumber < keyColorsCache.length &&
        index < keyColorsCache[boardNumber].length
        ) { // && keyAndCardColorsTestedStateCache == saveOrLoadKeysCountCache
      Color? cacheColorAnswer = keyColorsCache[boardNumber][index];
      if (cacheColorAnswer != null) {
        return cacheColorAnswer;
      } else {
        //Haven't cached that get, so do so in the function below
      }
    } else {
      //blank the cache
      //keyAndCardColorsTestedStateCache = saveOrLoadKeysCountCache;
      resetColorsCache();
    }

    Color? answer;
    String queryLetter = keyboardList[index];
    int gbStart = 5 * max(0, game.getFirstVisualRowToShowOnBoard(boardNumber));

    if (queryLetter == " ") {
      answer = Colors.transparent;
    }
    if (answer == null) {
      //get color for the keyboard based on best (green > yellow > grey) color on the grid
      for (var gbPosition = gbStart;
          gbPosition < getVisualCurrentRowInt() * 5;
          gbPosition++) {
        if (getCardLetterAtIndex(gbPosition) == queryLetter) {
          if (getCardColor(gbPosition, boardNumber) == green) {
            answer = green;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (var gbPosition = gbStart;
          gbPosition < getVisualCurrentRowInt() * 5;
          gbPosition++) {
        if (getCardLetterAtIndex(gbPosition) == queryLetter) {
          if (getCardColor(gbPosition, boardNumber) == amber) {
            answer = amber;
            break;
          }
        }
      }
    }
    if (answer == null) {
      for (var gbPosition = gbStart;
          gbPosition < getVisualCurrentRowInt() * 5;
          gbPosition++) {
        if (getCardLetterAtIndex(gbPosition) == queryLetter) {
          answer = Colors.transparent; //bg; //grey //used and no match
          break;
        }
      }
    }
    // ignore: prefer_conditional_assignment
    if (answer == null) {
      answer = grey; //not used yet by the player
    }
    keyColorsCache[boardNumber][index] = answer;
    return answer; // ?? Colors.pink;
  }

  Color getCardColor(index, boardNumber) {
    if (boardNumber < cardColorsCache.length &&
        index < cardColorsCache[boardNumber].length ) { //&& keyAndCardColorsTestedStateCache == saveOrLoadKeysCountCache
      Color? cacheColorAnswer = cardColorsCache[boardNumber][index];
      if (cacheColorAnswer != null) {
        return cacheColorAnswer;
      } else {
        //Haven't cached that get, so do so in the function below
      }
    } else {
      //blank the cache
      //keyAndCardColorsTestedStateCache = saveOrLoadKeysCountCache;
      resetColorsCache();
    }

    Color? answer;
    if (index >= getVisualCurrentRowInt() * 5) {
      answer = Colors.transparent; //grey; //later rows
    } else {
      String targetWord = game.getTargetWordForBoard(boardNumber);
      String testLetter = getCardLetterAtIndex(
          index); //newGameboardEntries[index ~/ 5][index % 5]//gameboardEntries[index];
      int testRow = index ~/ 5;
      int testColumn = index % 5;
      if (targetWord[testColumn] == testLetter) {
        answer = green;
      } else if (targetWord.contains(testLetter)) {
        int numberOfThisLetterInTargetWord =
            testLetter.allMatches(targetWord).length;
        int numberOfYellowThisLetterToLeftInCardRow = 0;
        for (var i = 0; i < testColumn; i++) {
          if (getCardLetterAtIndex(testRow * 5 + i) == testLetter &&
              getCardColor(testRow * 5 + i, boardNumber) == amber) {
            numberOfYellowThisLetterToLeftInCardRow++;
          }
        }

        int numberOfGreenThisLetterInCardRow = 0;
        for (var i = 0; i < 5; i++) {
          if (getCardLetterAtIndex(testRow * 5 + i) == testLetter &&
              targetWord[i] == getCardLetterAtIndex(testRow * 5 + i)) {
            numberOfGreenThisLetterInCardRow++;
          }
        }

        if (numberOfThisLetterInTargetWord >
            numberOfYellowThisLetterToLeftInCardRow +
                numberOfGreenThisLetterInCardRow) {
          //full logic to deal with repeating letters. If only one letter matching targetWord, then always returns Amber
          answer = amber;
        } else {
          answer = Colors.transparent;
        }
      } else {
        answer = Colors.transparent;
      }
    }

    cardColorsCache[boardNumber][index] = answer;
    return answer;
  }

  void resetColorsCache() {
    cardColorsCache = [];
    keyColorsCache = [];
    for (int i = 0; i < numBoards; i++) {
      cardColorsCache.add(List<Color?>.generate(
          (game.getLiveNumRowsPerBoard() * 5), (i) => null));
      keyColorsCache.add(List<Color?>.generate((30), (i) => null));
    }
  }
}
