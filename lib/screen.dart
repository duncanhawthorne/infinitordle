import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';

class Screen {
  //Variables used outside of class
  double appBarHeight = -1;
  double cardLiveMaxPixel = -1;
  double keyAspectRatioLive = -1;
  double keyboardSingleKeyLiveMaxPixelHeight = -1;
  int numPresentationBigRowsOfBoards = -1;

  //Variable used only inside of class
  double vertSpaceForGameboard = -1;
  double vertSpaceForCardWithWrap = -1;
  double horizSpaceForCardNoWrap = -1;
  double scW = -1;
  double scH = -1;
  double vertSpaceAfterTitle = -1;

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

      keyboardSingleKeyLiveMaxPixelHeight = min(
          keyAspectRatioDefault * scW / 10,
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
      int numSpacersAcross = ((numBoards + 1) ~/ numPresentationBigRowsOfBoards) - 1;
      int numSpacersDown = (numPresentationBigRowsOfBoards) - 1;
      cardLiveMaxPixel = min(
          (vertSpaceForGameboard - numSpacersDown * boardSpacer) /
              numPresentationBigRowsOfBoards /
              numRowsPerBoard,
          (scW - numSpacersAcross * boardSpacer) /
              ((numBoards + 1)  ~/ numPresentationBigRowsOfBoards) /
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
}
