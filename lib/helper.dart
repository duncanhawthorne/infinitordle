// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:infinitordle/card_flips.dart';
import 'package:infinitordle/card_colors.dart';
import 'package:infinitordle/saves.dart';
import 'package:infinitordle/game_logic.dart';
import 'package:infinitordle/screen.dart';
import 'package:infinitordle/constants.dart';

Game game = Game();
Save save = Save();
Flips flips = Flips();
CardColors cardColors = CardColors();
Screen screen = Screen();

bool isListContains(list, bit) {
  return binarySearch(list, bit) !=
      -1; //sorted list so this is faster than doing contains
}

// Memoisation
class LegalWord {
  var legalWordCache = {};
  bool call(String word) {
    if (word.length != 5) {
      return false;
    }
    if (!legalWordCache.containsKey(word)) {
      if (legalWordCache.length > 5) {
        //reset cache
        legalWordCache = {};
      }
      legalWordCache[word] = isListContains(legalWords, word);
    }
    return legalWordCache[word]!;
  }
}

LegalWord isLegalWord = LegalWord();

bool listEqual(a, b) {
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

int getABRowFromGBRow(gbRow) {
  return gbRow + game.getPushOffBoardRows();
}

int getGBRowFromABRow(abRow) {
  return abRow - game.getPushOffBoardRows();
}

int getABIndexFromGBIndex(gbIndex) {
  return gbIndex + 5 * game.getPushOffBoardRows();
}

int getGBIndexFromABIndex(abIndex) {
  return abIndex - 5 * game.getPushOffBoardRows();
}
