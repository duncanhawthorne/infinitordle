import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';

Widget gameboardWidget(boardNumber) {
  return ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () {
                game.flipHighlightedBoard(boardNumber);
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: cols * screen.cardLiveMaxPixel,
                    maxHeight: numRowsPerBoard * screen.cardLiveMaxPixel),
                child: GridView.builder(
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
              ? _card(abIndex, boardNumber, val, "b")
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateX(pi),
                  child: _positionedCard(abIndex, boardNumber, val, "f"),
                ),
        ));
      });
}

Widget _positionedCard(abIndex, boardNumber, val, bf) {
  // if offset 1, do gradually. if offset 0, do instantaneously
  // so slide visual cards into new position slowly
  // then do a real switch to what is in each card to move one place forward
  // and move visual cards back to original position instantly
  int timeFactorOfSlide = game.getTemporaryVisualOffsetForSlide();
  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: timeFactorOfSlide * slideTime),
        top: -screen.cardLiveMaxPixel * game.getTemporaryVisualOffsetForSlide(),
        child: _sizedCard(abIndex, boardNumber, val, bf),
      ),
    ],
  );
}

Widget _sizedCard(abIndex, boardNumber, val, bf) {
  return SizedBox(
    height: screen.cardLiveMaxPixel,
    width: screen.cardLiveMaxPixel,
    child: _card(abIndex, boardNumber, val, bf),
  );
}

Widget _card(abIndex, boardNumber, val, bf) {
  int abRow = abIndex ~/ cols;
  bool historicalWin = game.getTestHistoricalAbWin(abRow, boardNumber) ||
      game.boardFlourishFlipAngles.containsKey(boardNumber) &&
          abRow == game.boardFlourishFlipAngles[boardNumber];
  bool hideCard =
      (!infMode && game.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
          abRow < game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber);

  return Container(
    padding: EdgeInsets.all(0.005 * screen.cardLiveMaxPixel),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: historicalWin ? green : Colors.transparent,
                width: 0.05 * screen.cardLiveMaxPixel),
            borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
            color: hideCard
                ? Colors.transparent
                : bf == "b"
                    ? abRow == game.getAbCurrentRowInt() &&
                            game.getCurrentTyping().length == cols &&
                            !isLegalWord(game.getCurrentTyping())
                        ? Colors.red
                        : grey
                    : cardColors.getAbCardColor(abIndex, boardNumber)),
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: _cardText(abIndex, boardNumber),
        ),
      ),
    ),
  );
}

Widget _cardText(abIndex, boardNumber) {
  int abRow = abIndex ~/ cols;
  int col = abIndex % cols;
  return Text(
    abRow == game.getAbLiveNumRowsPerBoard() - 1 &&
            game.getGbCurrentRowInt() < 0 &&
            game.getCurrentTyping().length > col
        //In unlikely case need to type while off top of board, show at bottom
        ? game.getCurrentTyping()[col].toUpperCase()
        : game.getCardLetterAtAbIndex(abIndex).toUpperCase(),
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: screen.cardLiveMaxPixel,
      height: m3 ? 1.15 : null,
      leadingDistribution: m3 ? TextLeadingDistribution.even : null,
      color: (!infMode &&
                  game.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
              abRow < game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber)
          ? Colors.transparent
          : game.getHighlightedBoard() == -1 ||
                  game.getHighlightedBoard() == boardNumber
              ? Colors.white
              : offWhite,
      fontWeight: FontWeight.bold,
    ),
  );
}
