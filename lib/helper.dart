import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinitordle/constants.dart';

String getTargetWord() {
  return finalWords[random.nextInt(finalWords.length)];
}

List getTargetWords(numberOfBoards) {
  var starterList = [];
  for (var i = 0; i < numberOfBoards; i++) {
    starterList.add(getTargetWord());
  }
  return starterList;
}

void cheatPrintTargetWords() {
  if (cheatMode) {
    // ignore: avoid_print
    print(targetWords);
  }
}

void logWinAndGetNewWord(enteredWord, oneMatchingWordBoard) {
  //Log the word just got in success words, which gets green to shown
  infSuccessWords.add(enteredWord);
  infSuccessBoardsMatchingWords.add(oneMatchingWordBoard);
  //Create new target word for the board
  targetWords[oneMatchingWordBoard] = getTargetWord();
  resetColorsCache();
  saveKeys();
}

void oneStepBack(currentWordLocal) {
  //Erase a row and step back
  for (var j = 0; j < infNumBacksteps; j++) {
    for (var i = 0; i < 5; i++) {
      gameboardEntries.removeAt(0);
      gameboardEntries.add("");
    }
    currentWord--;
    //Reverse flip the card on the next row back to backside (after earlier having flipped them the right way)
    for (var j = 0; j < 5; j++) {
      flipReal(currentWord * 5 + j, "b");
    }
  }
  resetColorsCache();
  saveKeys();
}

bool streak() {
  bool isStreak = true;
  if (infSuccessWords.isNotEmpty) {
    isStreak = true;
  }
  else {
    isStreak = false;
  }

  if (infSuccessWords.length >= min(3,currentWord)) {
    for (int q = 0; q < min(3,currentWord); q++) {
      int i = currentWord - 1 - q;
      if (gameboardEntries.sublist(i * 5, i * 5 + 5).join("") !=
          infSuccessWords[infSuccessWords.length - 1 - q]) {
        isStreak = false;
        break;
      }
    }
  }
  else {
    isStreak = false;
  }

  onStreakForKeyboardIndicatorCache = isStreak; //cache the result for visual indicator on return key
  return isStreak;
}


Color getBestColorForLetter(index, boardNumber) {
  Color? cacheAnswer = keyColorsCache[boardNumber][index];
  if (cacheAnswer != null) {
    return cacheAnswer;
  }

  Color? answer;

  String queryLetter = keyboardList[index];
  if (queryLetter == " ") {
    answer = Colors.transparent;
  }
  if (answer == null) {
    //get color for the keyboard based on best (green > yellow > grey) color on the grid
    for (var gbPosition = 0; gbPosition < currentWord * 5; gbPosition++) {
      if (gameboardEntries[gbPosition] == queryLetter) {
        if (getCardColor(gbPosition, boardNumber) == Colors.green) {
          answer = Colors.green;
          break;
        }
      }
    }
  }
  if (answer == null) {
    for (var gbPosition = 0; gbPosition < currentWord * 5; gbPosition++) {
      if (gameboardEntries[gbPosition] == queryLetter) {
        if (getCardColor(gbPosition, boardNumber) == Colors.amber) {
          answer = Colors.amber;
          break;
        }
      }
    }
  }
  if (answer == null) {
    for (var gbPosition = 0; gbPosition < currentWord * 5; gbPosition++) {
      if (gameboardEntries[gbPosition] == queryLetter) {
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
  Color? cacheAnswer = cardColorsCache[boardNumber][index];
  if (cacheAnswer != null) {
    return cacheAnswer;
  }

  Color? answer;
  if (index >= (currentWord) * 5) {
    answer = Colors.transparent; //grey; //later rows
  } else {
    String targetWord = targetWords[boardNumber];
    String testLetter = gameboardEntries[index];
    int testRow = index ~/ 5;
    int testColumn = index % 5;
    if (targetWord[testColumn] == testLetter) {
      answer = Colors.green;
    } else if (targetWord.contains(testLetter)) {
      int numberOfThisLetterInTargetWord =
          testLetter.allMatches(targetWord).length;
      int numberOfYellowThisLetterToLeftInCardRow = 0;
      for (var i = 0; i < testColumn; i++) {
        if (gameboardEntries[testRow * 5 + i] == testLetter &&
            getCardColor(testRow * 5 + i, boardNumber) == Colors.amber) {
          numberOfYellowThisLetterToLeftInCardRow++;
        }
      }

      int numberOfGreenThisLetterInCardRow = 0;
      for (var i = 0; i < 5; i++) {
        if (gameboardEntries[testRow * 5 + i] == testLetter &&
            targetWord[i] == gameboardEntries[testRow * 5 + i]) {
          numberOfGreenThisLetterInCardRow++;
        }
      }

      if (numberOfThisLetterInTargetWord >
          numberOfYellowThisLetterToLeftInCardRow +
              numberOfGreenThisLetterInCardRow) {
        //full logic to deal with repeating letters. If only one letter matching targetWord, then always returns Amber
        answer = Colors.amber;
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

bool detectBoardSolvedByRow(boardNumber, maxRowToCheck) {
  for (var q = 0; q < min(currentWord, maxRowToCheck); q++) {
    bool result = true;
    for (var j = 0; j < 5; j++) {
      if (getCardColor(q * 5 + j, boardNumber) != Colors.green) {
        result = false;
      }
    }
    if (result) {
      return true;
    }
  }
  return false;
}

void resetColorsCache() {
  cardColorsCache = [];
  keyColorsCache = [];
  for (int i = 0; i < numBoards; i++) {
    cardColorsCache.add(List<Color?>.generate((numRowsPerBoard * 5), (i) => null));
    keyColorsCache.add(List<Color?>.generate((30), (i) => null));
  }
}

Future<void> loadKeys() async {
  final prefs = await SharedPreferences.getInstance();
  targetWords = [];

  //targetWords.add(prefs.getString('word0') ?? getTargetWord());
  //targetWords.add(prefs.getString('word1') ?? getTargetWord());
  //targetWords.add(prefs.getString('word2') ?? getTargetWord());
  //targetWords.add(prefs.getString('word3') ?? getTargetWord());

  String tmpWords = prefs.getString('word') ?? "";
  List tmpWordsList = tmpWords.split(";");
  for (var i = 0; i < numBoards; i++) {
    if (tmpWordsList.length > i) {
      targetWords.add(tmpWordsList[i]);
    }
    else {
      targetWords.add(getTargetWord());
    }
  }

  currentWord = prefs.getInt('currentWord') ?? 0;

  var tmpinfSuccessWords = prefs.getString('infSuccessWords') ?? "";
  for (var i = 0; i < tmpinfSuccessWords.length ~/ 5; i++) {
    var j = i * 5;
    infSuccessWords.add(tmpinfSuccessWords.substring(j, j + 5));
    infSuccessBoardsMatchingWords.add(-1);
  }

  var tmpinfSuccessBoardsMatchingWords =
      prefs.getString('infSuccessBoardsMatchingWords') ?? "";
  for (var i = 0; i < tmpinfSuccessBoardsMatchingWords.length; i++) {
    infSuccessBoardsMatchingWords[i] =
        int.parse(tmpinfSuccessBoardsMatchingWords[i]);
  }

  var tmpGB1 = prefs.getString('gameboardEntries') ?? "";
  for (var i = 0; i < tmpGB1.length; i++) {
    gameboardEntries[i] = tmpGB1.substring(i, i + 1);
  }
  for (var j = 0; j < (tmpGB1.length ~/ 5) * 5; j++) {
    if (gameboardEntries[j] != "") {
      flipReal(j, "f");
    }
  }
  typeCountInWord = tmpGB1.length % 5;
  saveKeys();
}

Future<void> saveKeys() async {
  final prefs = await SharedPreferences.getInstance();
  //await prefs.setString('word0', targetWords[0]);
  //await prefs.setString('word1', targetWords[1]);
  //await prefs.setString('word2', targetWords[2]);
  //await prefs.setString('word3', targetWords[3]);

  await prefs.setString('word', targetWords.join(";"));

  await prefs.setInt('currentWord', currentWord);
  await prefs.setString('infSuccessWords', infSuccessWords.join(""));

  var tmpGB1 = "";
  for (var i = 0; i < currentWord * 5; i++) {
    tmpGB1 = tmpGB1 + gameboardEntries[i];
  }
  await prefs.setString('gameboardEntries', tmpGB1);

  var tmpinfSuccessBoardsMatchingWords = "";
  for (var i = 0; i < infSuccessBoardsMatchingWords.length; i++) {
    tmpinfSuccessBoardsMatchingWords = tmpinfSuccessBoardsMatchingWords +
        infSuccessBoardsMatchingWords[i].toString();
  }

  await prefs.setString(
      'infSuccessBoardsMatchingWords', tmpinfSuccessBoardsMatchingWords);

}

void flipReal(index, toFOrB) {
  if (toFOrB == "b") {
    angles[index] = 0;
  } else {
    angles[index] = 0.5;
  }
}

void detetctAndUpdateForScreenSize(context) {
  if (scW != MediaQuery.of(context).size.width ||
      scH !=
          MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top) {
    //recalculate these key values for screen size changes
    scW = MediaQuery.of(context).size.width;
    scH = MediaQuery.of(context).size.height -
        MediaQuery.of(context)
            .padding
            .top; // - (kIsWeb ? 0 : kBottomNavigationBarHeight);
    vertSpaceAfterTitle = scH - 56 - 2; //app bar and divider
    keyboardSingleKeyEffectiveMaxPixel = min(
        scW / 10,
        min(keyboardSingleKeyUnconstrainedMaxPixel,
            vertSpaceAfterTitle * 0.25 / 3));
    vertSpaceForGameboard =
        vertSpaceAfterTitle - keyboardSingleKeyEffectiveMaxPixel * 3;
    vertSpaceForCardNoWrap = vertSpaceForGameboard / numRowsPerBoard;
    horizSpaceForCardNoWrap =
        (scW - (numBoards - 1) * boardSpacer) / numBoards / 5;
    if (vertSpaceForCardNoWrap > 2 * horizSpaceForCardNoWrap) {
      numPresentationBigRowsOfBoards = 2;
    } else {
      numPresentationBigRowsOfBoards = 1;
    }
    cardEffectiveMaxPixel = min(
        keyboardSingleKeyUnconstrainedMaxPixel,
        min(
            (vertSpaceForGameboard) /
                numPresentationBigRowsOfBoards /
                numRowsPerBoard,
            (scW - (numBoards - 1) * boardSpacer) /
                (numBoards ~/ numPresentationBigRowsOfBoards) /
                5));
  }
}
