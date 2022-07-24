// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinitordle/constants.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

bool quickIn(list, bit) {
  //p(["quickIn", "list", bit]);
  return binarySearch(list, bit) !=
      -1; //sorted list so this is faster than doing contains
  //return list.contains(bit);
}

bool legalWord(word) {

  if (word.length != 5) {
    return false;
  }

  if (legalWordTestedWord == word) {
    return oneLegalWordForRedCardsCache;
  }
  else {
    //blank the cache
    legalWordTestedWord = word;
    oneLegalWordForRedCardsCache = false;
  }

  bool answer = quickIn(legalWords, currentTyping);
  oneLegalWordForRedCardsCache = answer;

  return answer;
}

void p(x) {
  //dev.log(x.toString());
  debugPrint("///// A " + x.toString());
}

List winWords() {
  var log = [];
  for (var i = 0; i < winRecordBoards.length; i++) {
    if (winRecordBoards[i] != -1) {
      log.add(enteredWords[i]);
    }
  }
  return log;
}

bool testHistoricalWin(rowOfIndex, boardNumber) {
  if (rowOfIndex + offsetRollback > 0 &&
      winRecordBoards.length > rowOfIndex + offsetRollback &&
      winRecordBoards[rowOfIndex + offsetRollback] == boardNumber) {
    return true;
  }
  return false;
}

int getVisualCurrentRowInt() {
  return enteredWords.length - offsetRollback;
}

String getVisualGBLetterAtIndexEntered(index) {
  int rowOfIndex = index ~/ 5;
  try {
    String letter = "";
    if (rowOfIndex > getVisualCurrentRowInt()) {
      letter = "";
    } else if (rowOfIndex == getVisualCurrentRowInt()) {
      if (currentTyping.length > (index % 5)) {
        letter = currentTyping.substring(index % 5, (index % 5) + 1);
      } else {
        letter = "";
      }
    } else {
      letter = enteredWords[index ~/ 5 + offsetRollback][index % 5];
    }
    return letter;
  } catch (e) {
    p(["getVisualGBLetterAtIndexEntered", index, e]);
    return "";
  }
}

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
    p(targetWords);
  }
}

void logWinAndGetNewWord(
    masterEnteredWordPositionLocal, oneMatchingWordBoardLocal) {
  //Log the word just got in success words, which gets green to shown
  winRecordBoards[masterEnteredWordPositionLocal - 1] =
      oneMatchingWordBoardLocal;
  //Create new target word for the board
  targetWords[oneMatchingWordBoardLocal] = getTargetWord();
  //resetColorsCache();
  saveKeys();
}

void oneStepBack(currentWordLocal) {
  //Erase a row and step back
  for (var j = 0; j < infNumBacksteps; j++) {
    //Reverse flip the card on the next row back to backside (after earlier having flipped them the right way)
    offsetRollback++;
    for (var j = 0; j < 5; j++) {
      flipCardReal(getVisualCurrentRowInt() * 5 + j, "b");
    }
  }
  initiateFlipState(); //in case anything is in the wrong state, fix here
  //resetColorsCache();
  saveKeys();
}

bool isStreak() {

  if (onStreakTestedState == saveKeysCount) {
    return onStreakCache;
  }
  else {
    //blank the cache
    onStreakTestedState = saveKeysCount;
    onStreakCache = false;
  }

  bool isStreak = true;

  if (winRecordBoards.isEmpty) {
    isStreak = false;
  } else {
    for (int q = 0; q < 3; q++) {
      if (winRecordBoards.length - 1 - q < 0 ||
          winRecordBoards[winRecordBoards.length - 1 - q] != -1) {
        isStreak = true;
      } else {
        isStreak = false;
        break;
      }
    }
  }
  onStreakCache = isStreak;

  return isStreak;
}

Color getBestColorForLetter(index, boardNumber) {

  if (keyAndCardColorsTestedState == saveKeysCount) {
    Color? cacheAnswer = keyColorsCache[boardNumber][index];
    if (cacheAnswer != null) {
      return cacheAnswer;
    }
    else {
      //Haven't cached that get, so do so in the function below
    }
  }
  else {
    //blank the cache
    keyAndCardColorsTestedState = saveKeysCount;
    resetColorsCache();
  }

  Color? answer;
  String queryLetter = keyboardList[index];

  if (queryLetter == " ") {
    answer = Colors.transparent;
  }
  if (answer == null) {
    //get color for the keyboard based on best (green > yellow > grey) color on the grid
    for (var gbPosition = 0;
        gbPosition < getVisualCurrentRowInt() * 5;
        gbPosition++) {
      if (getVisualGBLetterAtIndexEntered(gbPosition) == queryLetter) {
        if (getCardColor(gbPosition, boardNumber) == Colors.green) {
          answer = Colors.green;
          break;
        }
      }
    }
  }
  if (answer == null) {
    for (var gbPosition = 0;
        gbPosition < getVisualCurrentRowInt() * 5;
        gbPosition++) {
      if (getVisualGBLetterAtIndexEntered(gbPosition) == queryLetter) {
        if (getCardColor(gbPosition, boardNumber) == Colors.amber) {
          answer = Colors.amber;
          break;
        }
      }
    }
  }
  if (answer == null) {
    for (var gbPosition = 0;
        gbPosition < getVisualCurrentRowInt() * 5;
        gbPosition++) {
      if (getVisualGBLetterAtIndexEntered(gbPosition) == queryLetter) {
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

  if (keyAndCardColorsTestedState == saveKeysCount) {
    Color? cacheAnswer = cardColorsCache[boardNumber][index];
    if (cacheAnswer != null) {
      return cacheAnswer;
    }
    else {
      //Haven't cached that get, so do so in the function below
    }
  }
  else {
    //blank the cache
    keyAndCardColorsTestedState = saveKeysCount;
    resetColorsCache();
  }

  Color? answer;
  if (index >= getVisualCurrentRowInt() * 5) {
    answer = Colors.transparent; //grey; //later rows
  } else {
    String targetWord = targetWords[boardNumber];
    String testLetter = getVisualGBLetterAtIndexEntered(
        index); //newGameboardEntries[index ~/ 5][index % 5]//gameboardEntries[index];
    int testRow = index ~/ 5;
    int testColumn = index % 5;
    if (targetWord[testColumn] == testLetter) {
      answer = Colors.green;
    } else if (targetWord.contains(testLetter)) {
      int numberOfThisLetterInTargetWord =
          testLetter.allMatches(targetWord).length;
      int numberOfYellowThisLetterToLeftInCardRow = 0;
      for (var i = 0; i < testColumn; i++) {
        if (getVisualGBLetterAtIndexEntered(testRow * 5 + i) == testLetter &&
            getCardColor(testRow * 5 + i, boardNumber) == Colors.amber) {
          numberOfYellowThisLetterToLeftInCardRow++;
        }
      }

      int numberOfGreenThisLetterInCardRow = 0;
      for (var i = 0; i < 5; i++) {
        if (getVisualGBLetterAtIndexEntered(testRow * 5 + i) == testLetter &&
            targetWord[i] == getVisualGBLetterAtIndexEntered(testRow * 5 + i)) {
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
  for (var q = 0; q < min(getVisualCurrentRowInt(), maxRowToCheck); q++) {
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
    cardColorsCache
        .add(List<Color?>.generate((numRowsPerBoard * 5), (i) => null));
    keyColorsCache.add(List<Color?>.generate((30), (i) => null));
  }
}

Future<void> loadUser() async {
  //print("load user");
  final prefs = await SharedPreferences.getInstance();
  gUser = prefs.getString('gUser') ?? gUserDefault;
  //print(gUser);
}

Future<void> saveUser() async {
  //print("save user");
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('gUser', gUser);
  //print(gUser);
}

void loadFromEncodedState(gameEncoded) {
  //print("loadKeysReal"+gameEncoded);
  if (gameEncoded == "") {
    //first time through or error state
    //print("ge empty");
    resetBoardReal(true);
  } else if (gameEncoded != gameEncodedLast) {
    try {
      Map<String, dynamic> game = {};
      game = json.decode(gameEncoded);

      String tmpgUser = game["gUser"] ?? "Default";
      if (tmpgUser != gUser && tmpgUser != "Default") {
        //print("redoing load keys");
        //Error state, so set gUser properly and redo loadKeys from firebase
        gUser = tmpgUser;
        loadKeys();
        return;
      }

      targetWords = game["targetWords"] ?? getTargetWords(numBoards);

      enteredWords = game["enteredWords"] ?? [];
      offsetRollback = game["offsetRollback"] ?? 0;
      winRecordBoards = game["winRecordBoards"] ?? [];
    } catch (error) {
      p(["ERROR", error]);
      resetBoardReal(true);
    }
    initiateFlipState();
    //resetColorsCache();
    gameEncodedLast = gameEncoded;
    saveKeysCount++;
  }
}

String encodeCurrentGameState() {
  Map<String, dynamic> game = {};
  game = {};
  game["targetWords"] = targetWords;
  game["gUser"] = gUser;

  game["enteredWords"] = enteredWords;
  game["offsetRollback"] = offsetRollback;
  game["winRecordBoards"] = winRecordBoards;

  return json.encode(game);
}

Future<void> loadKeys() async {
  final prefs = await SharedPreferences.getInstance();
  String gameEncoded = "";

  if (gUser == gUserDefault) {
    //load from local save
    gameEncoded = prefs.getString('game') ?? "";
  } else {
    //load from firebase
    gameEncoded = "";
    final docRef = db.collection("states").doc(gUser);
    await docRef.get().then(
      (DocumentSnapshot doc) {
        final gameEncodedTmp = doc.data() as Map<String, dynamic>;
        gameEncoded = gameEncodedTmp["data"];
      },
      // ignore: avoid_print
      onError: (e) => print("Error getting document: $e"),
    );
  }
  loadFromEncodedState(gameEncoded);
}

Future<void> saveKeys() async {
  saveKeysCount++;
  String gameEncoded = encodeCurrentGameState();
  //p(["SAVE keys",gameEncoded]);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('game', gameEncoded);

  firebasePush(gameEncoded);
}

Future<void> firebasePush(state) async {
  if (gUser != gUserDefault) {
    // Create a new user with a first and last name
    final dhState = <String, dynamic>{"data": state};
    db
        .collection("states")
        .doc(gUser)
        .set(dhState)
        // ignore: avoid_print
        .onError((e, _) => print("Error writing document: $e"));
  }
}

String firebasePull(snapshot) {
  String snapshotCurrent = "";
  snapshot.data!.docs
      .map((DocumentSnapshot document) {
        if (document.id == gUser) {
          Map<String, dynamic> dataTmpQ =
              document.data() as Map<String, dynamic>;
          snapshotCurrent = dataTmpQ["data"].toString();
          return null;
        }
      })
      .toList()
      .cast();
  return snapshotCurrent;
}

void resetBoardReal(save) {
  p("Reset board");
  //initialise on reset
  enteredWords = [];
  currentTyping = "";
  offsetRollback = 0;
  winRecordBoards = [];

  targetWords = getTargetWords(numBoards);

  //speed initialise entries using cheat mode for debugging
  if (cheatMode) {
    for (var j = 0; j < numBoards; j++) {
      if (cheatTargetWordsInitial.length > j) {
        targetWords[j] = cheatTargetWordsInitial[j];
      } else {
        targetWords[j] = getTargetWord();
      }
    }
    for (var j = 0; j < cheatEnteredWordsInitial.length; j++) {
      enteredWords.add(cheatEnteredWordsInitial[j]);
      winRecordBoards.add(-1);
    }
  }

  initiateFlipState();
  //isStreak(); //reset streakCache
  //resetColorsCache();

  if (save) {
    p("Reset board called with instruction to save keys, and now saving keys");
    saveKeys();
  }
  else {
    //only runs at startup
    saveKeysCount++;
  }
}

void initiateFlipState() {
  for (var j = 0; j < numRowsPerBoard * 5; j++) {
    if (getVisualCurrentRowInt() > (j ~/ 5)) {
      flipCardReal(j, "f");
    } else {
      flipCardReal(j, "b");
    }
  }
}

void flipCardReal(index, toFOrB) {
  if (toFOrB == "b") {
    angles[index] = 0;
  } else {
    angles[index] = 0.5;
  }
}

void detectAndUpdateForScreenSize(context) {
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
    appBarHeight = scH * 0.055; //min(56, max(40, scH * 0.05));
    vertSpaceAfterTitle =
        scH - appBarHeight - dividerHeight; //app bar and divider
    keyboardSingleKeyEffectiveMaxPixelHeight = min(
        keyAspectRatioDefault * scW / 10,
        min(
            double.infinity, //keyboardSingleKeyUnconstrainedMaxPixelHeight,
            keyAspectRatioDefault * vertSpaceAfterTitle * 0.17 / 3));
    vertSpaceForGameboard =
        vertSpaceAfterTitle - keyboardSingleKeyEffectiveMaxPixelHeight * 3;
    vertSpaceForCardWithWrap =
        ((vertSpaceForGameboard - boardSpacer) / numRowsPerBoard) / 2;
    horizSpaceForCardNoWrap =
        (scW - (numBoards - 1) * boardSpacer) / numBoards / 5;
    if (vertSpaceForCardWithWrap > horizSpaceForCardNoWrap) {
      numPresentationBigRowsOfBoards = 2;
    } else {
      numPresentationBigRowsOfBoards = 1;
    }
    int numSpacersAcross = (numBoards ~/ numPresentationBigRowsOfBoards) - 1;
    int numSpacersDown = (numPresentationBigRowsOfBoards) - 1;
    cardEffectiveMaxPixel = min(
        double.infinity, // keyboardSingleKeyUnconstrainedMaxPixelHeight,
        min(
            (vertSpaceForGameboard - numSpacersDown * boardSpacer) /
                numPresentationBigRowsOfBoards /
                numRowsPerBoard,
            (scW - numSpacersAcross * boardSpacer) /
                (numBoards ~/ numPresentationBigRowsOfBoards) /
                5));

    if (vertSpaceForGameboard >
        cardEffectiveMaxPixel *
                numRowsPerBoard *
                numPresentationBigRowsOfBoards +
            numSpacersDown * boardSpacer) {
      //if still space left over, no point squashing keyboard for nothing
      keyboardSingleKeyEffectiveMaxPixelHeight = min(
          keyAspectRatioDefault * scW / 10,
          min(
              double.infinity, //keyboardSingleKeyUnconstrainedMaxPixelHeight,
              (vertSpaceAfterTitle -
                      cardEffectiveMaxPixel *
                          numRowsPerBoard *
                          numPresentationBigRowsOfBoards +
                      numSpacersDown * boardSpacer) /
                  3));
    }
  }

  keyAspectRatioLive =
      max(0.5, keyboardSingleKeyEffectiveMaxPixelHeight / (scW / 10));
}
