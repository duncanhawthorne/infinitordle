import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stroke_text/stroke_text.dart';

import 'card_colors.dart';
import 'card_flips.dart';
import 'constants.dart';
import 'game_logic.dart';
import 'screen.dart';

const double _notionalCardSize = 1.0;
const _renderTwoFramesTime = delayMult *
    33; // so that set state and animations don't happen exactly simultaneously
const tau = 2 * pi;

Widget gameboardWidget(int boardNumber) {
  return ValueListenableBuilder<bool>(
      valueListenable: game.expandingBoardNotifier,
      builder: (BuildContext context, bool value, Widget? child) {
        return game.expandingBoard
            ? ValueListenableBuilder<int>(
                valueListenable: game.pushUpStepsNotifier,
                builder: (BuildContext context, int value, Widget? child) {
                  return _gameboardWidgetReal(boardNumber);
                },
              )
            : _gameboardWidgetReal(boardNumber);
      });
}

Widget _gameboardWidgetReal(int boardNumber) {
  final bool expandingBoard = game.expandingBoard;
  final int boardNumberRows = game.gbLiveNumRowsPerBoard;
  // ignore: sized_box_for_whitespace
  return Container(
    height: numRowsPerBoard * screen.cardLiveMaxPixel, //notionalCardSize,
    width: cols * screen.cardLiveMaxPixel, //notionalCardSize,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
        onTap: () {
          game.toggleHighlightedBoard(boardNumber);
        },
        child: _gameboardWidgetWithNRows(
            boardNumber, boardNumberRows, expandingBoard),
      ),
    ),
  );
}

Widget _gameboardWidgetWithNRows(
    int boardNumber, int boardNumberRows, bool expandingBoard) {
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
        return game.expandingBoard
            ? _cardFlipperAlts(_getABIndexFromRGBIndex(rGbIndex), boardNumber)
            : ValueListenableBuilder<int>(
                valueListenable: game.pushUpStepsNotifier,
                builder: (BuildContext context, int value, Widget? child) {
                  return _cardFlipperAlts(
                      _getABIndexFromRGBIndex(rGbIndex), boardNumber);
                },
              );
      });
}

Widget _cardFlipperAlts(int abIndex, int boardNumber) {
  final int abRow = abIndex ~/ cols;
  return ValueListenableBuilder<int>(
      valueListenable: game.currentRowChangedNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return abRow > game.abCurrentRowInt
            ? _cardFlipper(abIndex, boardNumber)
            : ListenableBuilder(
                listenable: Listenable.merge([
                  game.boardFlourishFlipRowsNotifiers[boardNumber],
                  game.abCardFlourishFlipAnglesNotifier,
                ]),
                builder: (BuildContext context, _) {
                  return _cardFlipper(abIndex, boardNumber);
                });
      });
}

Widget _cardFlipper(int abIndex, int boardNumber) {
  return TweenAnimationBuilder(
      tween: Tween<double>(
          begin: 0, end: flips.getFlipAngle(abIndex, boardNumber)),
      duration: const Duration(milliseconds: flipTime),
      builder: (BuildContext context, double angle, __) {
        return (Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateX(angle * tau + (angle <= 0.25 ? 0 : tau / 2)),
          child: ValueListenableBuilder<int>(
            valueListenable: game.temporaryVisualOffsetForSlideNotifier,
            builder: (BuildContext context, int value, Widget? child) {
              return _positionedScaledCard(abIndex, boardNumber, angle > 0.25);
            },
          ),
        ));
      });
}

Widget _positionedScaledCard(int abIndex, int boardNumber, bool facingFront) {
  const double shrinkCardScaleDefault = 0.75;
  final double cardSizeDefault = screen.cardLiveMaxPixel; //notionalCardSize;
  final int temporaryVisualOffsetForSlide = game.temporaryVisualOffsetForSlide;

  final int abRow = abIndex ~/ cols;
  final int gbRow = _getGBRowFromABRow(abRow);
  final bool shouldSlideCard = abRow < game.abCurrentRowInt;
  final bool shouldShrinkCard = game.expandingBoard &&
      abRow - (shouldSlideCard ? temporaryVisualOffsetForSlide : 0) <
          game.abLiveNumRowsPerBoard - numRowsPerBoard;

  final double cardScaleFactor =
      shouldShrinkCard ? shrinkCardScaleDefault : 1.0;
  final double cardSize = cardSizeDefault * cardScaleFactor;
  final double cardScaleOffset = cardSizeDefault * (1 - cardScaleFactor) / 2;
  final double cardSlideOffset =
      shouldSlideCard ? -cardSizeDefault * temporaryVisualOffsetForSlide : 0;
  // if offset 1, do gradually. if offset 0, do instantaneously
  // so slide visual cards into new position slowly
  // then do a real switch to what is in each card to move one place forward
  // and move visual cards back to original position instantly
  final int timeFactorOfSlide = temporaryVisualOffsetForSlide;
  return Stack(
    clipBehavior: gbRow == 0 && cardSlideOffset != 0
        ? Clip.hardEdge
        : Clip.none, //clipping is slow so clip only when necessary
    children: [
      AnimatedPositioned(
          //curve: Curves.fastOutSlowIn,
          duration: Duration(
              milliseconds:
                  timeFactorOfSlide * (slideTime - _renderTwoFramesTime)),
          // move slightly quicker so have two frames to re-render final position
          top: cardSlideOffset + cardScaleOffset,
          left: cardScaleOffset,
          height: cardSize,
          width: cardSize,
          child: SizedBox(
              height: cardSize,
              width: cardSize,
              child: _cardChooser(abIndex, boardNumber, facingFront))),
    ],
  );
}

Widget _cardChooser(int abIndex, int boardNumber, bool facingFront) {
  final int abRow = abIndex ~/ cols;

  return ListenableBuilder(
      listenable: Listenable.merge([
        game,
        game.highlightedBoardNotifier,
        game.currentRowChangedNotifier,
      ]),
      builder: (BuildContext context, _) {
        return abRow == game.abCurrentRowInt
            ? ValueListenableBuilder<String>(
                valueListenable: game.currentTypingNotifiers[abIndex % cols],
                builder: (BuildContext context, String value, Widget? child) {
                  return _cardChooserRealReal(
                      abIndex, boardNumber, facingFront);
                },
              )
            : _cardChooserRealReal(abIndex, boardNumber, facingFront);
      });
}

Widget _cardChooserRealReal(int abIndex, int boardNumber, bool facingFront) {
  final int abRow = abIndex ~/ cols;
  final int col = abIndex % cols;
  final bool historicalWin = game.getTestHistoricalAbWin(abRow, boardNumber) ||
      game.getBoardFlourishFlipRow(boardNumber) != -1 &&
          abRow == game.getBoardFlourishFlipRow(boardNumber);
  final bool justFlippedBackToFront =
      game.getBoardFlourishFlipRow(boardNumber) != -1;
  final bool hideCard =
      (!infMode && game.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
          abRow < game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) ||
          (_rowOffTopOfMainBoard(abRow) &&
              !facingFront &&
              justFlippedBackToFront); //abRow < game.getAbCurrentRowInt() - 1

  final String cardLetter = abRow ==
              game.abLiveNumRowsPerBoard -
                  1 && //code is formatting final row of cards
          _getGBRowFromABRow(game.abCurrentRowInt) < 0 &&
          game.currentTypingString.length > col
      //If need to type while off top of board (unlikely), show on final row
      ? game.currentTypingString[col]
      : hideCard
          ? ""
          : game.getCardLetterAtAbIndex(abIndex);
  final bool normalHighlighting = game.isBoardNormalHighlighted(boardNumber);
  final Color cardColor = hideCard
      ? transp
      : !facingFront
          ? grey
          : _soften(
              boardNumber, cardColors.getAbCardColor(abIndex, boardNumber));
  final Color borderColor = hideCard
      ? transp
      : historicalWin
          ? _soften(boardNumber, green)
          : transp;
  assert(_cardCache.containsKey(normalHighlighting));
  assert(_cardCache[normalHighlighting].containsKey(cardLetter));
  assert(_cardCache[normalHighlighting][cardLetter].containsKey(cardColor));
  assert(_cardCache[normalHighlighting][cardLetter][cardColor]
      .containsKey(borderColor));
  return _cardCache[normalHighlighting][cardLetter][cardColor][borderColor];
}

Widget _card(bool normalHighlighting, String cardLetter, Color cardColor,
    Color borderColor) {
  const double cardBorderRadiusFactor = 0.2;
  const cardSizeFixed = _notionalCardSize;
  return FittedBox(
    fit: BoxFit.contain,
    child: Padding(
      padding: const EdgeInsets.all(0.005 * cardSizeFixed),
      child: Container(
        height: cardSizeFixed,
        width: cardSizeFixed,
        decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.05 * cardSizeFixed),
            borderRadius:
                BorderRadius.circular(cardBorderRadiusFactor * cardSizeFixed),
            color: cardColor),
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: _cardTextCache[normalHighlighting][cardLetter],
        ),
      ),
    ),
  );
}

const _softGreen = Color(0xff61B063);
const _softAmber = Color(0xffFFCF40);
const _softRed = Color(0xffF55549);
const _offWhite = Color(0xff939393);

final List cardColorsList = [
  red,
  amber,
  green,
  grey,
  transp,
  _softGreen,
  _softAmber,
  _softRed
];
final List borderColorsList = [green, _softGreen, transp];

final Map _cardCache = {
  for (bool normalHighlighting in [true, false])
    (normalHighlighting): {
      for (String cardLetter in keyboardList)
        (cardLetter): {
          for (Color cardColor in cardColorsList)
            (cardColor): {
              for (Color borderColor in borderColorsList)
                (borderColor): _card(
                    normalHighlighting, cardLetter, cardColor, borderColor)
            }
        }
    }
};

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

final Map _cardTextCache = {
  for (bool normalHighlighting in [true, false])
    (normalHighlighting): {
      for (String cardLetter in keyboardList)
        (cardLetter): _cardTextConst(normalHighlighting, cardLetter)
    }
};

final Map _softColorMap = {
  green: _softGreen,
  amber: _softAmber,
  red: _softRed,
  white: _offWhite,
  //grey: grey
  bg: transp,
};

Color _soften(int boardNumber, Color color) {
  if (game.isBoardNormalHighlighted(boardNumber) ||
      !_softColorMap.containsKey(color)) {
    return color;
  } else {
    return _softColorMap[color];
  }
}

// ignore: unused_element
int _getABRowFromGBRow(int gbRow) {
  return gbRow + game.pushOffBoardRows;
}

int _getGBRowFromABRow(int abRow) {
  return abRow - game.pushOffBoardRows;
}

// ignore: unused_element
int _getABIndexFromGBIndex(int gbIndex) {
  return gbIndex + cols * game.pushOffBoardRows;
}

// ignore: unused_element
int _getGBIndexFromABIndex(int abIndex) {
  return abIndex - cols * game.pushOffBoardRows;
}

int _getABIndexFromRGBIndex(int rGbIndex) {
  return (game.abLiveNumRowsPerBoard - rGbIndex ~/ cols - 1) * cols +
      rGbIndex % cols;
}

bool _rowOffTopOfMainBoard(int abRow) {
  return abRow < game.abLiveNumRowsPerBoard - numRowsPerBoard;
}
