// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:infinitordle/card_flips.dart';
import 'package:infinitordle/card_colors.dart';
import 'package:infinitordle/saves.dart';
import 'package:infinitordle/game_logic.dart';
import 'package:infinitordle/screen.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/google_logic.dart';
import 'package:infinitordle/firebase.dart';

Game game = Game();
Save save = Save();
Flips flips = Flips();
CardColors cardColors = CardColors();
Screen screen = Screen();
Google g = Google();
FireBase fBase = FireBase();

bool isListContains(list, bit) {
  //sorted list so this is faster than doing contains
  return binarySearch(list, bit) != -1;
}

// Memoisation
class LegalWord {
  var legalWordCache = {};
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
    return legalWordCache[word]!;
  }
}

LegalWord isLegalWord = LegalWord();

bool listEqual(a, b) {
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

void p(x) {
  debugPrint("///// A " + x.toString());
}

Color soften(boardNumber, color) {
  if (game.isBoardNormalHighlighted(boardNumber) ||
      !colorMap.containsKey(color)) {
    return color;
  } else {
    return colorMap[color];
  }
}

List getBlankFirstKnowledge(numberOfBoards) {
  return List.filled(numberOfBoards, 0);
}

void fixTitle() {
  //https://github.com/flutter/flutter/issues/98248
  if (true) {
    SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: appTitle,
        primaryColor: bg
            .value //Theme.of(context).primaryColor.value, // This line is required
        ));
  }
}

Future<void> sleep(delayAfterMult) async {
  await Future.delayed(Duration(milliseconds: delayAfterMult), () {});
}

int getABRowFromGBRow(gbRow) {
  return gbRow + game.getPushOffBoardRows();
}

int getGBRowFromABRow(abRow) {
  return abRow - game.getPushOffBoardRows();
}

int getABIndexFromGBIndex(gbIndex) {
  return gbIndex + cols * game.getPushOffBoardRows();
}

int getGBIndexFromABIndex(abIndex) {
  return abIndex - cols * game.getPushOffBoardRows();
}

num getABIndexFromRGBIndex(rGbIndex) {
  return (game.getAbLiveNumRowsPerBoard() - rGbIndex ~/ cols - 1) * cols +
      rGbIndex % cols;
}

bool rowOffTopOfMainBoard(abRow) {
  return abRow < game.getAbLiveNumRowsPerBoard() - numRowsPerBoard;
}
