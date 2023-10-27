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
  //p(["quickIn", "list", bit]);
  return binarySearch(list, bit) !=
      -1; //sorted list so this is faster than doing contains
  //return list.contains(bit);
}

// Memoisation
class LegalWord {
  var cache = {};
  bool call(String word) {
    if (word.length != 5) {
      return false;
    }
    if (!cache.containsKey(word)) {
      if (cache.length > 5) {
        //reset cache
        cache = {};
      }
      cache[word] = isListContains(legalWords, word);
    }
    return cache[word]!;
  }
}

LegalWord isLegalWord = LegalWord();

void p(x) {
  //dev.log(x.toString());
  debugPrint("///// A " + x.toString());
}

List getBlankFirstKnowledge(numberOfBoards) {
  return List.filled(numberOfBoards, 0);
}

void fixTitle() {
  //https://github.com/flutter/flutter/issues/98248
  if (true) {
    //scW == -1) { //one-off
    SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: appTitle,
        primaryColor: bg
            .value //Theme.of(context).primaryColor.value, // This line is required
        ));
  }
}
