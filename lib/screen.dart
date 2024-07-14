import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';

class Screen {
  double appBarHeight = -1;
  double cardLiveMaxPixel = -1;
  double keyAspectRatioLive = -1;
  double keyboardSingleKeyLiveMaxPixelHeight = -1;
  double keyboardSingleKeyLiveMaxPixelWidth = -1;
  int numPresentationBigRowsOfBoards = -1;
  double fullSizeOfGameboards = -1;
  double scW = -1;
  double scH = -1;

  double _vertSpaceForGameboard = -1;
  double _vertSpaceForCardWithWrap = -1;
  double _horizSpaceForCardNoWrap = -1;
  double _vertSpaceAfterTitle = -1;

  void detectAndUpdateForScreenSize(BuildContext context) {
    if (scW != MediaQuery.of(context).size.width ||
        scH !=
            MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom) {
      //recalculate these key values for screen size changes
      scW = MediaQuery.of(context).size.width;
      scH = MediaQuery.of(context).size.height -
          MediaQuery.of(context).padding.top -
          MediaQuery.of(context).padding.bottom;
      appBarHeight = scH * 0.055;
      _vertSpaceAfterTitle = scH - appBarHeight - dividerHeight;

      keyboardSingleKeyLiveMaxPixelHeight = min(
          keyAspectRatioDefault * scW / 10,
          keyAspectRatioDefault * _vertSpaceAfterTitle * 0.17 / 3);

      _vertSpaceForGameboard =
          _vertSpaceAfterTitle - keyboardSingleKeyLiveMaxPixelHeight * 3;
      _vertSpaceForCardWithWrap =
          ((_vertSpaceForGameboard - boardSpacer) / numRowsPerBoard) / 2;
      _horizSpaceForCardNoWrap =
          (scW - (numBoards - 1) * boardSpacer) / numBoards / cols;
      if (_vertSpaceForCardWithWrap > _horizSpaceForCardNoWrap) {
        numPresentationBigRowsOfBoards = 2;
      } else {
        numPresentationBigRowsOfBoards = 1;
      }
      int numSpacersAcross =
          ((numBoards / numPresentationBigRowsOfBoards).ceil()) - 1;
      int numSpacersDown = (numPresentationBigRowsOfBoards) - 1;
      cardLiveMaxPixel = min(
          (_vertSpaceForGameboard - numSpacersDown * boardSpacer) /
              numPresentationBigRowsOfBoards /
              numRowsPerBoard,
          (scW - numSpacersAcross * boardSpacer) /
              (numBoards / numPresentationBigRowsOfBoards).ceil() /
              cols);
      fullSizeOfGameboards =
          cardLiveMaxPixel * numRowsPerBoard * numPresentationBigRowsOfBoards +
              numSpacersDown * boardSpacer;
      if (_vertSpaceForGameboard > fullSizeOfGameboards) {
        //if still space left over, no point squashing keyboard for nothing

        keyboardSingleKeyLiveMaxPixelHeight = min(
            keyAspectRatioDefault * scW / 10,
            (_vertSpaceAfterTitle - fullSizeOfGameboards) / 3);
      }

      keyAspectRatioLive =
          max(0.5, keyboardSingleKeyLiveMaxPixelHeight / (scW / 10));
      keyboardSingleKeyLiveMaxPixelWidth =
          keyboardSingleKeyLiveMaxPixelHeight / keyAspectRatioLive;
    }
  }
}
