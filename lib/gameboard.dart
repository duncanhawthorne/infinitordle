import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:stroke_text/stroke_text.dart';

Widget gameboardWidget(boardNumber) {
  return ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () {
                game.toggleHighlightedBoard(boardNumber);
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: cols * screen.cardLiveMaxPixel,
                    maxHeight: numRowsPerBoard * screen.cardLiveMaxPixel),
                child: GridView.builder(
                    padding: EdgeInsets
                        .zero, //https://github.com/flutter/flutter/issues/20241
                    cacheExtent:
                        10000, //prevents top card reloading (and flipping) on scroll
                    reverse: true, //makes stick to bottom
                    physics: game.getExpandingBoard()
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(), //turns off ios scrolling
                    itemCount: game.getGbLiveNumRowsPerBoard() * cols,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                    ),
                    itemBuilder: (BuildContext context, int rGbIndex) {
                      return _cardFlipper(
                          getABIndexFromRGBIndex(rGbIndex), boardNumber);
                    }),
              ))));
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
                  child: _positionedScaledCard(abIndex, boardNumber, true),
                ),
        ));
      });
}

Widget _positionedScaledCard(abIndex, boardNumber, facingFront) {
  int abRow = abIndex ~/ cols;
  bool shouldSlideCard = abRow < game.getAbCurrentRowInt();
  bool shouldShrinkCard = game.getExpandingBoard() &&
      abRow - (shouldSlideCard ? game.getTemporaryVisualOffsetForSlide() : 0) <
          game.getAbLiveNumRowsPerBoard() - numRowsPerBoard;
  double cardSize = screen.cardLiveMaxPixel;
  double shrinkCardScale = 0.75;
  double shrinkCardOffset = (1 - shrinkCardScale) / 2;
  double cardScale = shouldShrinkCard ? shrinkCardScale : 1.0;
  double cardScaleOffset = cardSize * (shouldShrinkCard ? shrinkCardOffset : 0);
  double cardSlideOffset =
      shouldSlideCard ? -cardSize * game.getTemporaryVisualOffsetForSlide() : 0;
  // if offset 1, do gradually. if offset 0, do instantaneously
  // so slide visual cards into new position slowly
  // then do a real switch to what is in each card to move one place forward
  // and move visual cards back to original position instantly
  int timeFactorOfSlide = game.getTemporaryVisualOffsetForSlide();
  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        //curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: timeFactorOfSlide * slideTime),
        top: cardSlideOffset + cardScaleOffset,
        left: cardScaleOffset,
        height: cardSize * cardScale,
        width: cardSize * cardScale,
        child: _card(abIndex, boardNumber, facingFront),
      ),
    ],
  );
}

Widget _card(abIndex, boardNumber, facingFront) {
  int abRow = abIndex ~/ cols;
  bool historicalWin = game.getTestHistoricalAbWin(abRow, boardNumber) ||
      game.boardFlourishFlipAngles.containsKey(boardNumber) &&
          abRow == game.boardFlourishFlipAngles[boardNumber];
  //int timeFactorOfSlide = game.getTemporaryVisualOffsetForSlide();
  bool justFlippedBackToFront =
      game.boardFlourishFlipAngles.containsKey(boardNumber);
  bool hideCard =
      (!infMode && game.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
          abRow < game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) ||
          (rowOffTopOfMainBoard(abRow) &&
              !facingFront &&
              justFlippedBackToFront); //abRow < game.getAbCurrentRowInt() - 1
  const double cardBorderRadius = 0.2;
  //assert(
  //    slideTime < flipTime / 2); //to ensure we never see color changes via fade

  return Container(
    padding: EdgeInsets.all(0.005 * screen.cardLiveMaxPixel),
    child: ClipRRect(
      borderRadius:
          BorderRadius.circular(cardBorderRadius * screen.cardLiveMaxPixel),
      child: Container(
        //duration: Duration(milliseconds: timeFactorOfSlide * slideTime),
        decoration: BoxDecoration(
            border: Border.all(
                color: hideCard
                    ? transp
                    : historicalWin
                        ? soften(boardNumber, green)
                        : transp,
                width: 0.05 * screen.cardLiveMaxPixel),
            borderRadius: BorderRadius.circular(
                cardBorderRadius * screen.cardLiveMaxPixel),
            color: hideCard
                ? transp
                : !facingFront
                    ? grey
                    : soften(boardNumber,
                        cardColors.getAbCardColor(abIndex, boardNumber))),
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: _cardText(abIndex, boardNumber, hideCard),
        ),
      ),
    ),
  );
}

Widget _cardText(abIndex, boardNumber, hideCard) {
  int abRow = abIndex ~/ cols;
  int col = abIndex % cols;
  return StrokeText(
    text: abRow ==
                game.getAbLiveNumRowsPerBoard() -
                    1 && //code is formatting final row of cards
            game.getGbCurrentRowInt() < 0 &&
            game.getCurrentTyping().length > col
        //If need to type while off top of board (unlikely), show on final row
        ? game.getCurrentTyping()[col].toUpperCase()
        : hideCard
            ? ""
            : game.getCardLetterAtAbIndex(abIndex).toUpperCase(),
    strokeWidth: 0.5,
    strokeColor: hideCard ? transp : soften(boardNumber, bg),
    textStyle: TextStyle(
      height: m3 ? 1.15 : null,
      leadingDistribution: m3 ? TextLeadingDistribution.even : null,
      color: hideCard ? transp : soften(boardNumber, white),
      fontWeight: FontWeight.bold,
    ),
  );
}
