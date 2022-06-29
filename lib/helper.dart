import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinitordle/constants.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

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
      flipCardReal(currentWord * 5 + j, "b");
    }
  }
  resetColorsCache();
  saveKeys();
}

bool streak() {
  bool isStreak = true;
  if (infSuccessWords.isNotEmpty) {
    isStreak = true;
  } else {
    isStreak = false;
  }

  if (infSuccessWords.length >= min(3, currentWord)) {
    for (int q = 0; q < min(3, currentWord); q++) {
      int i = currentWord - 1 - q;
      if (gameboardEntries.sublist(i * 5, i * 5 + 5).join("") !=
          infSuccessWords[infSuccessWords.length - 1 - q]) {
        isStreak = false;
        break;
      }
    }
  } else {
    isStreak = false;
  }

  onStreakForKeyboardIndicatorCache =
      isStreak; //cache the result for visual indicator on return key
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
    cardColorsCache
        .add(List<Color?>.generate((numRowsPerBoard * 5), (i) => null));
    keyColorsCache.add(List<Color?>.generate((30), (i) => null));
  }
}

Future<void> saveKeys() async {
  //print("called saveKeys");
  //print(gUser);
  //print(targetWords);
  game = {};
  game["targetWords"] = targetWords;
  game["gUser"] = gUser;
  game["gameboardEntries"] = gameboardEntries;
  game["currentWord"] = currentWord;
  game["typeCountInWord"] = typeCountInWord;
  game["infSuccessWords"] = infSuccessWords;
  game["infSuccessBoardsMatchingWords"] = infSuccessBoardsMatchingWords;

  String gameEncoded = json.encode(game);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('game', gameEncoded);

  fbSave(gameEncoded);
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

Future<void> loadKeys() async {
  //print("load keys called");
  final prefs = await SharedPreferences.getInstance();
  String gameEncoded = "";

  //await Firebase.initializeApp(
  //  options: DefaultFirebaseOptions.currentPlatform,
  //);
  //db = FirebaseFirestore.instance;

  if (gUser == gUserDefault) {
    gameEncoded = prefs.getString('game') ?? "";
    //print("gUser = Joe Bloggs - 1gameencoded" + gameEncoded);
  } else {
    //await fbInit();

    gameEncoded = "";
    final docRef = db.collection("states").doc(gUser);
    await docRef.get().then(
      (DocumentSnapshot doc) {
        final gameEncodedTmp = doc.data() as Map<String, dynamic>;
        gameEncoded = gameEncodedTmp["data"];
        //print(gameEncodedTmp);
        //if (gameEncodedTmp != null) {
        //  gameEncoded = gameEncodedTmp["data"];
        //  //print(gameEncoded);
        //}

        // ...
      },
      // ignore: avoid_print
      onError: (e) => print("Error getting document: $e"),
    );
    /*
    await db.collection("states").get().then((event) {
      for (var doc in event.docs) {
        if (doc.id == gUser) {
          //print(doc.data()["data"]);
          gameEncoded = doc.data()["data"];
        }
      }
    });
    */
    //print("gUser NOT Joe Bloggs - 1gameencoded" + gameEncoded);
  }

  loadKeysReal(gameEncoded);

  //saveKeys();
}

void loadKeysReal(gameEncoded) {
  //print("loadKeysReal"+gameEncoded);
  if (gameEncoded == "") {
    //print("ge empty");
    resetBoardReal(true);
  } else if (gameEncoded != gameEncodedLast) {
    try {
      game = json.decode(gameEncoded);

      String tmpgUser = game["gUser"] ?? "Default";
      if (tmpgUser != gUser && tmpgUser != "Default") {
        //print("redoing load keys");
        gUser = tmpgUser;
        loadKeys(); //redo it using the new gUser (i.e. from the cloud)
        return;
      }

      targetWords = game["targetWords"] ?? getTargetWords(numBoards);

      var fallbackGameboardEntries = [];
      fallbackGameboardEntries
          .addAll(List<String>.generate((numRowsPerBoard * 5), (i) => ""));

      gameboardEntries = game["gameboardEntries"] ?? fallbackGameboardEntries;
      currentWord = game["currentWord"] ?? 0;
      typeCountInWord = game["typeCountInWord"] ?? 0;
      infSuccessWords = game["infSuccessWords"] ?? [];
      infSuccessBoardsMatchingWords =
          game["infSuccessBoardsMatchingWords"] ?? [];
    } catch (error) {
      //print("ERROR");
      resetBoardReal(true);
    }
    initiateFlipState();
    resetColorsCache();
    //print(targetWords);
    gameEncodedLast = gameEncoded;
  }
}

Future<void> fbSave(state) async {
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

String getDataFromSnapshot(snapshot) {
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
  //   setState(() {
  //initialise on reset
  typeCountInWord = 0;
  currentWord = 0;
  gameboardEntries.clear();
  gameboardEntries
      .addAll(List<String>.generate((numRowsPerBoard * 5), (i) => ""));
  //print(gameboardEntries);
  //gameboardEntries = ;
  targetWords = getTargetWords(numBoards);
  infSuccessWords.clear();
  infSuccessBoardsMatchingWords.clear();

  for (var j = 0; j < numRowsPerBoard * 5; j++) {
    flipCardReal(j, "b");
  }

  //speed initialise entries using cheat mode for debugging
  if (cheatMode) {
    for (var j = 0; j < numBoards; j++) {
      if (cheatWords.length > j) {
        targetWords[j] = cheatWords[j];
      } else {
        targetWords[j] = getTargetWord();
      }
    }

    for (var j = 0; j < cheatString.length; j++) {
      gameboardEntries[j] = cheatString[j];
    }

    currentWord = cheatString.length ~/ 5;
  }
  initiateFlipState();
  onStreakForKeyboardIndicatorCache = false;
  resetColorsCache();
  if (save) {
    //print("reset called with instruction to save keys, and now saving keys");
    saveKeys();
  }
}

void initiateFlipState() {
  for (var j = 0; j < gameboardEntries.length; j++) {
    //if (gameboardEntries[(j ~/ 5) * 5] != "") {
    if (currentWord > (j ~/ 5)) {
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
        keyAspectRatio * scW / 10,
        min(
            double.infinity, //keyboardSingleKeyUnconstrainedMaxPixelHeight,
            keyAspectRatio * vertSpaceAfterTitle * 0.17 / 3));
    vertSpaceForGameboard =
        vertSpaceAfterTitle - keyboardSingleKeyEffectiveMaxPixelHeight * 3;
    vertSpaceForCardNoWrap = vertSpaceForGameboard / numRowsPerBoard;
    horizSpaceForCardNoWrap =
        (scW - (numBoards - 1) * boardSpacer) / numBoards / 5;
    if (vertSpaceForCardNoWrap > 2 * horizSpaceForCardNoWrap) {
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
          keyAspectRatio * scW / 10,
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
}

/*
Future<void> fbInit() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  db = FirebaseFirestore.instance;
}
*/
