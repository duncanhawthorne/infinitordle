// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/card_flips.dart';
import 'package:infinitordle/card_colors.dart';
import 'package:infinitordle/saves.dart';
import 'package:infinitordle/game_logic.dart';
import 'package:infinitordle/screen.dart';

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

bool isLegalWord(word) {
  if (word.length != 5) {
    return false;
  }
  return isListContains(legalWords, word);
  /*
  if (legalWordTestedWordCache == word) {
    return oneLegalWordForRedCardsCache;
  } else {
    //blank the cache
    legalWordTestedWordCache = word;
    oneLegalWordForRedCardsCache = false;
  }

  bool answer = isListContains(legalWords, word);
  oneLegalWordForRedCardsCache = answer;

  return answer;
   */
}

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
