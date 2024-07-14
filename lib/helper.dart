// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'card_colors.dart';
import 'card_flips.dart';
import 'constants.dart';
import 'firebase.dart';
import 'game_logic.dart';
import 'google_logic.dart';
import 'saves.dart';
import 'screen.dart';
import 'title_fix_stub.dart' if (dart.library.js_interop) 'title_fix_web.dart';

Game game = Game();
Save save = Save();
Flips flips = Flips();
CardColors cardColors = CardColors();
Screen screen = Screen();
Google g = Google();
FireBase fBase = FireBase();

bool isListContains(List<String> list, String bit) {
  //sorted list so this is faster than doing contains
  return binarySearch(list, bit) != -1;
}

// Memoisation
class LegalWord {
  Map<String, bool> legalWordCache = {};
  bool call(String word) {
    if (word.length != cols) {
      return false;
    }
    if (!legalWordCache.containsKey(word)) {
      if (legalWordCache.length > 3) {
        //reset cache to keep it short
        legalWordCache = {};
      }
      legalWordCache[word] = isListContains(legalWords, word);
    }
    return legalWordCache[word]!; //null
  }
}

LegalWord isLegalWord = LegalWord();

bool listEqual(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void p(var x) {
  debugPrint("///// A ${DateTime.now()} ${x ?? "null"}");
}

Color soften(int boardNumber, Color color) {
  if (game.isBoardNormalHighlighted(boardNumber) ||
      !colorMap.containsKey(color)) {
    return color;
  } else {
    return colorMap[color];
  }
}

List<int> getBlankFirstKnowledge(int numberOfBoards) {
  return List.filled(numberOfBoards, 0);
}

void fixTitle() {
  fixTitleReal(); //either from web or stub
}

Future<void> sleep(int delayAfterMult) async {
  await Future.delayed(Duration(milliseconds: delayAfterMult), () {});
}

int getABRowFromGBRow(int gbRow) {
  return gbRow + game.pushOffBoardRows;
}

int getGBRowFromABRow(int abRow) {
  return abRow - game.pushOffBoardRows;
}

int getABIndexFromGBIndex(int gbIndex) {
  return gbIndex + cols * game.pushOffBoardRows;
}

int getGBIndexFromABIndex(int abIndex) {
  return abIndex - cols * game.pushOffBoardRows;
}

int getABIndexFromRGBIndex(int rGbIndex) {
  return (game.abLiveNumRowsPerBoard - rGbIndex ~/ cols - 1) * cols +
      rGbIndex % cols;
}

bool rowOffTopOfMainBoard(int abRow) {
  return abRow < game.abLiveNumRowsPerBoard - numRowsPerBoard;
}
