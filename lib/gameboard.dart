import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:get/get.dart';

Widget gameboardWidget(boardNumber) {
  bool expandingBoard = game.getExpandingBoard();
  int boardNumberRows = game.getGbLiveNumRowsPerBoard();
  return Container(
      height: numRowsPerBoard * screen.cardLiveMaxPixel, //notionalCardSize,
      width: cols * screen.cardLiveMaxPixel, //notionalCardSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel), //notionalCardSize),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              game.toggleHighlightedBoard(boardNumber);
            },
            child: gameboardWidgetWithNRows(
                boardNumber, boardNumberRows, expandingBoard),
          ),
        ),
      ));
}

Widget gameboardWidgetWithNRows(boardNumber, boardNumberRows, expandingBoard) {
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
        return _cardFlipper(getABIndexFromRGBIndex(rGbIndex), boardNumber);
      });
}

Widget _cardFlipper(abIndex, boardNumber) {
  return TweenAnimationBuilder(
      tween: Tween<double>(
          begin: 0, end: flips.getFlipAngle(abIndex, boardNumber)),
      duration: const Duration(milliseconds: flipTime),
      builder: (BuildContext context, double val, __) {
        return (Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateX(val * (2 * pi)),
          child: val <= 0.25
              ? _positionedScaledCard(abIndex, boardNumber, false)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateX(pi),
                  child: Obx(
                      () => _positionedScaledCard(abIndex, boardNumber, true)),
                ),
        ));
      });
}

Widget _positionedScaledCard(abIndex, boardNumber, facingFront) {
  const double shrinkCardScaleDefault = 0.75;
  double cardSizeDefault = screen.cardLiveMaxPixel; //notionalCardSize;
  int temporaryVisualOffsetForSlide = game.getTemporaryVisualOffsetForSlide();

  int abRow = abIndex ~/ cols;
  bool shouldSlideCard = abRow < game.getAbCurrentRowInt();
  bool shouldShrinkCard = game.getExpandingBoard() &&
      abRow - (shouldSlideCard ? temporaryVisualOffsetForSlide : 0) <
          game.getAbLiveNumRowsPerBoard() - numRowsPerBoard;

  double cardScaleFactor = shouldShrinkCard ? shrinkCardScaleDefault : 1.0;
  double cardSize = cardSizeDefault * cardScaleFactor;
  double cardScaleOffset = cardSizeDefault * (1 - cardScaleFactor) / 2;
  double cardSlideOffset =
      shouldSlideCard ? -cardSizeDefault * temporaryVisualOffsetForSlide : 0;
  // if offset 1, do gradually. if offset 0, do instantaneously
  // so slide visual cards into new position slowly
  // then do a real switch to what is in each card to move one place forward
  // and move visual cards back to original position instantly
  int timeFactorOfSlide = temporaryVisualOffsetForSlide;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        //curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: timeFactorOfSlide * slideTime),
        top: cardSlideOffset + cardScaleOffset,
        left: cardScaleOffset,
        height: cardSize,
        width: cardSize,
        child: SizedBox(
            height: cardSize,
            width: cardSize,
            child: Obx(() => _cardChooser(abIndex, boardNumber, facingFront))),
      ),
    ],
  );
}

Widget _cardChooser(abIndex, boardNumber, facingFront) {
  int abRow = abIndex ~/ cols;
  int col = abIndex % cols;
  bool historicalWin = game.getTestHistoricalAbWin(abRow, boardNumber) ||
      game.boardFlourishFlipAngles.containsKey(boardNumber) &&
          abRow == game.boardFlourishFlipAngles[boardNumber];
  bool justFlippedBackToFront =
      game.boardFlourishFlipAngles.containsKey(boardNumber);
  bool hideCard =
      (!infMode && game.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
          abRow < game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) ||
          (rowOffTopOfMainBoard(abRow) &&
              !facingFront &&
              justFlippedBackToFront); //abRow < game.getAbCurrentRowInt() - 1

  String cardLetter = abRow ==
              game.getAbLiveNumRowsPerBoard() -
                  1 && //code is formatting final row of cards
          game.getGbCurrentRowInt() < 0 &&
          game.getCurrentTyping().length > col
      //If need to type while off top of board (unlikely), show on final row
      ? game.getCurrentTyping()[col]
      : hideCard
          ? ""
          : game.getCardLetterAtAbIndex(abIndex);
  bool normalHighlighting = game.isBoardNormalHighlighted(boardNumber);
  Color cardColor = hideCard
      ? transp
      : !facingFront
          ? grey
          : soften(
              boardNumber, cardColors.getAbCardColor(abIndex, boardNumber));
  Color borderColor = hideCard
      ? transp
      : historicalWin
          ? soften(boardNumber, green)
          : transp;
  assert(_cardCache.containsKey(normalHighlighting));
  assert(_cardCache[normalHighlighting].containsKey(cardLetter));
  assert(_cardCache[normalHighlighting][cardLetter].containsKey(cardColor));
  assert(_cardCache[normalHighlighting][cardLetter][cardColor]
      .containsKey(borderColor));
  return _cardCache[normalHighlighting][cardLetter][cardColor][borderColor];
}

Widget _card(normalHighlighting, cardLetter, cardColor, borderColor) {
  const double cardBorderRadiusFactor = 0.2;
  const cardSizeFixed = notionalCardSize;
  return FittedBox(
    fit: BoxFit.contain,
    child: Container(
      height: cardSizeFixed,
      width: cardSizeFixed,
      padding: const EdgeInsets.all(0.005 * cardSizeFixed),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(cardBorderRadiusFactor * cardSizeFixed),
        child: Container(
          //duration: Duration(milliseconds: timeFactorOfSlide * slideTime),
          decoration: BoxDecoration(
              border:
                  Border.all(color: borderColor, width: 0.05 * cardSizeFixed),
              borderRadius:
                  BorderRadius.circular(cardBorderRadiusFactor * cardSizeFixed),
              color: cardColor),
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: _cardTextCache[normalHighlighting][cardLetter],
          ),
        ),
      ),
    ),
  );
}

final Map _cardCache = {
  for (var normalHighlighting in [true, false])
    (normalHighlighting): {
      for (var cardLetter in keyboardList)
        (cardLetter): {
          for (var cardColor in cardColorsList)
            (cardColor): {
              for (var borderColor in borderColorsList)
                (borderColor): _card(
                    normalHighlighting, cardLetter, cardColor, borderColor)
            }
        }
    }
};

Widget _cardTextConst(normalHighlighting, cardLetter) {
  return StrokeText(
    text: cardLetter.toUpperCase(),
    strokeWidth: 0.5, //previously 0.5 * cardSize / screen.cardLiveMaxPixel,
    strokeColor: normalHighlighting ? bg : transp,
    textStyle: TextStyle(
      height: 1.15,
      leadingDistribution: TextLeadingDistribution.even,
      color: normalHighlighting ? white : offWhite,
      fontWeight: FontWeight.bold,
    ),
  );
}

final Map _cardTextCache = {
  for (var normalHighlighting in [true, false])
    (normalHighlighting): {
      for (var cardLetter in keyboardList)
        (cardLetter): _cardTextConst(normalHighlighting, cardLetter)
    }
};
