// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

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
}

void p(x) {
  //dev.log(x.toString());
  debugPrint("///// A " + x.toString());
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

    keyboardSingleKeyLiveMaxPixelHeight = min(keyAspectRatioDefault * scW / 10,
        keyAspectRatioDefault * vertSpaceAfterTitle * 0.17 / 3); //
    vertSpaceForGameboard =
        vertSpaceAfterTitle - keyboardSingleKeyLiveMaxPixelHeight * 3;
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
    cardLiveMaxPixel = min(
        (vertSpaceForGameboard - numSpacersDown * boardSpacer) /
            numPresentationBigRowsOfBoards /
            numRowsPerBoard,
        (scW - numSpacersAcross * boardSpacer) /
            (numBoards ~/ numPresentationBigRowsOfBoards) /
            5);

    if (vertSpaceForGameboard >
        cardLiveMaxPixel * numRowsPerBoard * numPresentationBigRowsOfBoards +
            numSpacersDown * boardSpacer) {
      //if still space left over, no point squashing keyboard for nothing
      keyboardSingleKeyLiveMaxPixelHeight = min(
          keyAspectRatioDefault * scW / 10,
          (vertSpaceAfterTitle -
                  cardLiveMaxPixel *
                      numRowsPerBoard *
                      numPresentationBigRowsOfBoards +
                  numSpacersDown * boardSpacer) /
              3);
    }
  }

  keyAspectRatioLive =
      max(0.5, keyboardSingleKeyLiveMaxPixelHeight / (scW / 10));
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
