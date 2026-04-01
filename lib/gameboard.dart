import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stroke_text/stroke_text.dart';

import 'card_colors.dart';
import 'constants.dart';
import 'flips.dart';
import 'ephemeral.dart';
import 'state.dart';
import 'sequencer.dart';
import 'screen.dart';

const double _notionalCardSize = 1.0;
const int _renderTwoFramesTime =
    delayMult *
    33; // so that set state and animations don't happen exactly simultaneously
const double tau = 2 * pi;

/// Builds the gameboard widget for a specific [boardNumber].
/// Listens to [expandingBoardNotifier] and [pushUpStepsNotifier] to handle layouts.
Widget gameboardWidget(int boardNumber) {
  return ValueListenableBuilder<bool>(
    valueListenable: state.expandingBoardNotifier,
    builder: (BuildContext context, bool value, Widget? child) {
      return state.expandingBoard
          ? ListenableBuilder(
              listenable: Listenable.merge(<Listenable?>[
                state.pushUpStepsNotifier,
                state,
              ]),
              builder: (BuildContext context, _) {
                return _gameboardWidgetReal(boardNumber);
              },
            )
          : _gameboardWidgetReal(boardNumber);
    },
  );
}

/// Internal helper to build the actual board container and gesture detector.
Widget _gameboardWidgetReal(int boardNumber) {
  final bool expandingBoard = state.expandingBoard;
  final int boardNumberRows = state.gbLiveNumRowsPerBoard;
  // ignore: sized_box_for_whitespace
  return Container(
    height: numRowsPerBoard * screen.cardLiveMaxPixel, //notionalCardSize,
    width: cols * screen.cardLiveMaxPixel, //notionalCardSize,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
        onTap: () {
          ephemeral.toggleHighlightedBoard(boardNumber);
        },
        child: _gameboardWidgetWithNRows(
          boardNumber,
          boardNumberRows,
          expandingBoard,
        ),
      ),
    ),
  );
}

/// Builds the grid of cards for the gameboard.
Widget _gameboardWidgetWithNRows(
  int boardNumber,
  int boardNumberRows,
  bool expandingBoard,
) {
  return GridView.builder(
    padding: EdgeInsets.zero,
    //https://github.com/flutter/flutter/issues/20241
    cacheExtent: 10000,
    //prevents top card reloading (and flipping) on scroll
    reverse: true,
    //makes stick to bottom
    physics: expandingBoard
        ? const AlwaysScrollableScrollPhysics()
        : const NeverScrollableScrollPhysics(),
    //turns off ios scrolling
    itemCount: boardNumberRows * cols,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
    ),
    itemBuilder: (BuildContext context, int rGbIndex) {
      return state.expandingBoard
          ? _cardFlipperAlts(_getABIndexFromRGBIndex(rGbIndex), boardNumber)
          : ValueListenableBuilder<int>(
              valueListenable: state.pushUpStepsNotifier,
              builder: (BuildContext context, int value, Widget? child) {
                return _cardFlipperAlts(
                  _getABIndexFromRGBIndex(rGbIndex),
                  boardNumber,
                );
              },
            );
    },
  );
}

/// Orchestrates listeners for individual cards to trigger animations efficiently.
Widget _cardFlipperAlts(int abIndex, int boardNumber) {
  final int abRow = abIndex ~/ cols;
  return ValueListenableBuilder<int>(
    valueListenable: state.currentRowChangedNotifier,
    builder: (BuildContext context, int value, Widget? child) {
      return abRow > state.abCurrentRowInt
          ? _cardFlipper(abIndex, boardNumber)
          : ListenableBuilder(
              listenable: Listenable.merge(<Listenable?>[
                flips.boardFlourishFlipRowsNotifiers[boardNumber],
                flips.abCardFlourishFlipAnglesNotifier,
              ]),
              builder: (BuildContext context, _) {
                return _cardFlipper(abIndex, boardNumber);
              },
            );
    },
  );
}

/// Builds the visual card widget with a slide animation listener.
Widget _cardBuilder(int abIndex, int boardNumber, bool facingFront) {
  return ValueListenableBuilder<int>(
    valueListenable: sequencer.temporaryVisualOffsetForSlideNotifier,
    builder: (BuildContext context, int value, Widget? child) {
      return _positionedScaledCard(abIndex, boardNumber, facingFront);
    },
  );
}

/// Handles the 3D flip animation of a card.
Widget _cardFlipper(int abIndex, int boardNumber) {
  final Widget childFront = _cardBuilder(abIndex, boardNumber, true);
  final Widget childBack = _cardBuilder(abIndex, boardNumber, false);

  return TweenAnimationBuilder<double>(
    tween: Tween<double>(
      begin: 0,
      end: flips.getFlipAngle(abIndex, boardNumber),
    ),
    duration: const Duration(milliseconds: flipTime),
    builder: (BuildContext context, double angle, _) {
      final bool isFront = angle > 0.25;
      return (Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateX(angle * tau + (isFront ? tau / 2 : 0)),
        child: isFront ? childFront : childBack,
      ));
    },
  );
}

/// Positioned and scales the card, handling the sliding animation for board shifts.
Widget _positionedScaledCard(int abIndex, int boardNumber, bool facingFront) {
  const double shrinkCardScaleDefault = 0.75;
  final double cardSizeDefault = screen.cardLiveMaxPixel; //notionalCardSize;
  final int temporaryVisualOffsetForSlide =
      sequencer.temporaryVisualOffsetForSlide;

  final int abRow = abIndex ~/ cols;
  final int gbRow = _getGBRowFromABRow(abRow);
  final bool shouldSlideCard = abRow < state.abCurrentRowInt;
  final bool shouldShrinkCard =
      state.expandingBoard &&
      abRow - (shouldSlideCard ? temporaryVisualOffsetForSlide : 0) <
          state.abLiveNumRowsPerBoard - numRowsPerBoard;

  final double cardScaleFactor = shouldShrinkCard
      ? shrinkCardScaleDefault
      : 1.0;
  final double cardSize = cardSizeDefault * cardScaleFactor;
  final double cardScaleOffset = cardSizeDefault * (1 - cardScaleFactor) / 2;
  final double cardSlideOffset = shouldSlideCard
      ? -cardSizeDefault * temporaryVisualOffsetForSlide
      : 0;
  // if offset 1, do gradually. if offset 0, do instantaneously
  // so slide visual cards into new position slowly
  // then do a real switch to what is in each card to move one place forward
  // and move visual cards back to original position instantly
  final int timeFactorOfSlide = temporaryVisualOffsetForSlide;
  final Widget chosenCard = SizedBox(
    height: cardSize,
    width: cardSize,
    child: _cardChooser(abIndex, boardNumber, facingFront),
  );
  return Stack(
    clipBehavior: gbRow == 0 && cardSlideOffset != 0
        ? Clip.hardEdge
        : Clip.none, //clipping is slow so clip only when necessary
    children: <Widget>[
      AnimatedPositioned(
        //curve: Curves.fastOutSlowIn,
        duration: Duration(
          milliseconds: timeFactorOfSlide * (slideTime - _renderTwoFramesTime),
        ),
        // move slightly quicker so have two frames to re-render final position
        top: cardSlideOffset + cardScaleOffset,
        left: cardScaleOffset,
        height: cardSize,
        width: cardSize,
        child: chosenCard,
      ),
    ],
  );
}

/// Listens to game state to decide which letter and color to show on a card.
Widget _cardChooser(int abIndex, int boardNumber, bool facingFront) {
  final int abRow = abIndex ~/ cols;

  return ListenableBuilder(
    listenable: Listenable.merge(<Listenable?>[
      state,
      ephemeral.highlightedBoardNotifier,
      state.currentRowChangedNotifier,
    ]),
    builder: (BuildContext context, _) {
      return abRow == state.abCurrentRowInt
          ? ValueListenableBuilder<String>(
              valueListenable: ephemeral.currentTypingNotifiers[abIndex % cols],
              builder: (BuildContext context, String value, Widget? child) {
                return _cardChooserRealReal(abIndex, boardNumber, facingFront);
              },
            )
          : _cardChooserRealReal(abIndex, boardNumber, facingFront);
    },
  );
}

/// Determines visibility, letter, and colors for a card based on logic and historical state.
Widget _cardChooserRealReal(int abIndex, int boardNumber, bool facingFront) {
  final int abRow = abIndex ~/ cols;
  final int col = abIndex % cols;
  final bool historicalWin =
      state.getTestHistoricalAbWin(abRow, boardNumber) ||
      flips.getBoardFlourishFlipRow(boardNumber) != -1 &&
          abRow == flips.getBoardFlourishFlipRow(boardNumber);
  final bool justFlippedBackToFront =
      flips.getBoardFlourishFlipRow(boardNumber) != -1;
  final bool hideCard =
      (!infMode && state.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
      abRow < state.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) ||
      (_rowOffTopOfMainBoard(abRow) &&
          !facingFront &&
          justFlippedBackToFront); //abRow < game.getAbCurrentRowInt() - 1

  final String cardLetter =
      abRow ==
              state.abLiveNumRowsPerBoard -
                  1 && //code is formatting final row of cards
          _getGBRowFromABRow(state.abCurrentRowInt) < 0 &&
          ephemeral.currentTypingString.length > col
      //If need to type while off top of board (unlikely), show on final row
      ? ephemeral.currentTypingString[col]
      : hideCard
      ? ""
      : _getCardLetter(abIndex);
  final bool normalHighlighting = ephemeral.isBoardNormalHighlighted(
    boardNumber,
  );
  final Color cardColor = hideCard
      ? transp
      : !facingFront
      ? grey
      : _soften(boardNumber, cardColors.getAbCardColor(abIndex, boardNumber));
  final Color borderColor = hideCard
      ? transp
      : historicalWin
      ? _soften(boardNumber, green)
      : transp;
  assert(_cardCache.containsKey(normalHighlighting));
  assert(_cardCache[normalHighlighting]!.containsKey(cardLetter));
  assert(_cardCache[normalHighlighting]![cardLetter]!.containsKey(cardColor));
  assert(
    _cardCache[normalHighlighting]![cardLetter]![cardColor]!.containsKey(
      borderColor,
    ),
  );
  return _cardCache[normalHighlighting]![cardLetter]![cardColor]![borderColor]!;
}

/// Basic card building block with border and background color.
Widget _card(
  bool normalHighlighting,
  String cardLetter,
  Color cardColor,
  Color borderColor,
) {
  const double cardBorderRadiusFactor = 0.2;
  const double cardSizeFixed = _notionalCardSize;
  return FittedBox(
    fit: BoxFit.contain,
    child: Padding(
      padding: const EdgeInsets.all(0.005 * cardSizeFixed),
      child: Container(
        height: cardSizeFixed,
        width: cardSizeFixed,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 0.05 * cardSizeFixed),
          borderRadius: BorderRadius.circular(
            cardBorderRadiusFactor * cardSizeFixed,
          ),
          color: cardColor,
        ),
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: _cardTextCache[normalHighlighting]![cardLetter],
        ),
      ),
    ),
  );
}

const Color _softGreen = Color(0xff61B063);
const Color _softAmber = Color(0xffFFCF40);
const Color _softRed = Color(0xffF55549);
const Color _offWhite = Color(0xff939393);

/// List of available card colors.
final List<Color> cardColorsList = <Color>[
  red,
  amber,
  green,
  grey,
  transp,
  _softGreen,
  _softAmber,
  _softRed,
];

/// List of available border colors.
final List<Color> borderColorsList = <Color>[green, _softGreen, transp];

/// Cache for built card widgets.
final Map<bool, Map<String, Map<Color, Map<Color, Widget>>>> _cardCache =
    <bool, Map<String, Map<Color, Map<Color, Widget>>>>{
      for (bool normalHighlighting in <bool>[true, false])
        (normalHighlighting): <String, Map<Color, Map<Color, Widget>>>{
          for (String cardLetter in keyboardList)
            (cardLetter): <Color, Map<Color, Widget>>{
              for (Color cardColor in cardColorsList)
                (cardColor): <Color, Widget>{
                  for (Color borderColor in borderColorsList)
                    (borderColor): _card(
                      normalHighlighting,
                      cardLetter,
                      cardColor,
                      borderColor,
                    ),
                },
            },
        },
    };

/// Creates the text widget for a card's letter.
Widget _cardTextConst(bool normalHighlighting, String cardLetter) {
  return StrokeText(
    text: cardLetter.toUpperCase(),
    strokeWidth: 0.5, //previously 0.5 * cardSize / screen.cardLiveMaxPixel,
    strokeColor: normalHighlighting ? bg : transp,
    textStyle: TextStyle(
      height: 1.15,
      leadingDistribution: TextLeadingDistribution.even,
      color: normalHighlighting ? white : _offWhite,
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Cache for card text widgets.
final Map<bool, Map<String, Widget>> _cardTextCache =
    <bool, Map<String, Widget>>{
      for (bool normalHighlighting in <bool>[true, false])
        (normalHighlighting): <String, Widget>{
          for (String cardLetter in keyboardList)
            (cardLetter): _cardTextConst(normalHighlighting, cardLetter),
        },
    };

final Map<Color, Color> _softColorMap = <Color, Color>{
  green: _softGreen,
  amber: _softAmber,
  red: _softRed,
  white: _offWhite,
  //grey: grey
  bg: transp,
};

/// Softens colors for non-highlighted boards.
Color _soften(int boardNumber, Color color) {
  if (ephemeral.isBoardNormalHighlighted(boardNumber) ||
      !_softColorMap.containsKey(color)) {
    return color;
  } else {
    return _softColorMap[color]!;
  }
}

String _getCardLetter(int abIndex) {
  final int abRow = abIndex ~/ cols;
  final int col = abIndex % cols;
  if (abRow > state.abCurrentRowInt) {
    return "";
  } else if (abRow == state.abCurrentRowInt) {
    return ephemeral.getCurrentTypingAtCol(col);
  } else {
    return state.getCardLetterAtAbIndex(abIndex);
  }
}

// ignore: unused_element
int _getABRowFromGBRow(int gbRow) {
  return gbRow + state.pushOffBoardRows;
}

/// Converts a board-relative row index to an absolute row index.
int _getGBRowFromABRow(int abRow) {
  return abRow - state.pushOffBoardRows;
}

// ignore: unused_element
int _getABIndexFromGBIndex(int gbIndex) {
  return gbIndex + cols * state.pushOffBoardRows;
}

// ignore: unused_element
int _getGBIndexFromABIndex(int abIndex) {
  return abIndex - cols * state.pushOffBoardRows;
}

/// Converts a grid index to an absolute board index.
int _getABIndexFromRGBIndex(int rGbIndex) {
  return (state.abLiveNumRowsPerBoard - rGbIndex ~/ cols - 1) * cols +
      rGbIndex % cols;
}

/// Checks if a row is scrolled off the top of the main visible board.
bool _rowOffTopOfMainBoard(int abRow) {
  return abRow < state.abLiveNumRowsPerBoard - numRowsPerBoard;
}
