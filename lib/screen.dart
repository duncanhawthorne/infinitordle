import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';

const double _keyAspectRatioDefault = 1.5;
const double dividerHeight = 2;

/// A utility class to manage and calculate screen-related dimensions and layout constraints.
class Screen {
  double appBarHeight = -1;
  double cardLiveMaxPixel = -1;
  double _keyAspectRatioLive = -1;
  double keyboardSingleKeyLiveMaxPixelHeight = -1;
  double keyboardSingleKeyLiveMaxPixelWidth = -1;
  int numPresentationBigRowsOfBoards = -1;
  double _fullSizeOfGameboards = -1;
  double _scW = -1;
  double _scH = -1;

  double _vertSpaceForGameboard = -1;
  double _vertSpaceForCardWithWrap = -1;
  double _horizSpaceForCardNoWrap = -1;
  double _vertSpaceAfterTitle = -1;

  /// Detects screen size changes and updates internal layout variables.
  void calculateLayoutDimensions(BoxConstraints constraints) {
    if (_scW != constraints.maxWidth || _scH != constraints.maxHeight) {
      //recalculate these key values for screen size changes
      _scW = constraints.maxWidth;
      _scH = constraints.maxHeight;
      appBarHeight = _scH * 0.055;
      _vertSpaceAfterTitle = _scH - appBarHeight - dividerHeight;

      keyboardSingleKeyLiveMaxPixelHeight = min(
        _keyAspectRatioDefault * _scW / kMaxKbRowLength,
        _keyAspectRatioDefault * _vertSpaceAfterTitle * 0.17 / 3,
      );

      _vertSpaceForGameboard =
          _vertSpaceAfterTitle - keyboardSingleKeyLiveMaxPixelHeight * 3;
      _vertSpaceForCardWithWrap =
          ((_vertSpaceForGameboard - boardSpacer) / numRowsPerBoard) / 2;
      _horizSpaceForCardNoWrap =
          (_scW - (numBoards - 1) * boardSpacer) / numBoards / cols;
      if (_vertSpaceForCardWithWrap > _horizSpaceForCardNoWrap) {
        numPresentationBigRowsOfBoards = 2;
      } else {
        numPresentationBigRowsOfBoards = 1;
      }
      final int numSpacersAcross =
          ((numBoards / numPresentationBigRowsOfBoards).ceil()) - 1;
      final int numSpacersDown = (numPresentationBigRowsOfBoards) - 1;
      cardLiveMaxPixel = min(
        (_vertSpaceForGameboard - numSpacersDown * boardSpacer) /
            numPresentationBigRowsOfBoards /
            numRowsPerBoard,
        (_scW - numSpacersAcross * boardSpacer) /
            (numBoards / numPresentationBigRowsOfBoards).ceil() /
            cols,
      );
      _fullSizeOfGameboards =
          cardLiveMaxPixel * numRowsPerBoard * numPresentationBigRowsOfBoards +
          numSpacersDown * boardSpacer;
      if (_vertSpaceForGameboard > _fullSizeOfGameboards) {
        //if still space left over, no point squashing keyboard for nothing

        keyboardSingleKeyLiveMaxPixelHeight = min(
          _keyAspectRatioDefault * _scW / kMaxKbRowLength,
          (_vertSpaceAfterTitle - _fullSizeOfGameboards) / 3,
        );
      }

      _keyAspectRatioLive = max(
        0.5,
        keyboardSingleKeyLiveMaxPixelHeight / (_scW / kMaxKbRowLength),
      );
      keyboardSingleKeyLiveMaxPixelWidth =
          keyboardSingleKeyLiveMaxPixelHeight / _keyAspectRatioLive;
    }
  }
}

/// Global instance of [Screen] to be used across the app.
final Screen screen = Screen();
