import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'dart:math';
import 'package:infinitordle/constants.dart';

Widget gameboardWidget(boardNumber) {
  return ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () {
                //var ss = globalFunctions[0];
                if (game.getHighlightedBoard() == boardNumber) {
                  game.setHighlightedBoard(-1); //if already set turn off
                } else {
                  game.setHighlightedBoard(boardNumber);
                }
                ss();
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: 5 * screen.cardLiveMaxPixel, //*0.97
                    maxHeight: numRowsPerBoard * screen.cardLiveMaxPixel), //*0.97
                child: GridView.builder(
                    cacheExtent: 10000, //prevents top card reloading (and flipping) on scroll
                    reverse: game.getExpandingBoard() ? true : false,
                    physics: game.getExpandingBoard()
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(), //turns off ios scrolling
                    itemCount: game.getLiveNumRowsPerBoard() * 5,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return game.getExpandingBoard()
                          ? _cardFlipper(
                              (game.getLiveNumRowsPerBoard() - index ~/ 5 - 1) *
                                      5 +
                                  index % 5,
                              boardNumber)
                          : _cardFlipper(index, boardNumber);
                    }),
              ))));
}

Widget _cardFlipper(index, boardNumber) {
  return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: flips.getFlipAngle(index)),
      duration: const Duration(milliseconds: durMult * 500),
      builder: (BuildContext context, double val, __) {
        return (Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateX(val * (2 * pi)),
          child: val <= 0.25
              ? _card(index, boardNumber, val, "b")
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateX(pi),
                  child: _positionedCard(index, boardNumber, val, "f"),
                ),
        ));
      });
}

Widget _positionedCard(index, boardNumber, val, bf) {
  // if offset 1, do gradually. if offset 0, do instantaneously
  // so slide visual cards into new position slowly
  // then do a real switch to what is in each card to move one place forward
  // and move visual cards back to original position instantly
  int speedOfSlide = game.getTemporaryVisualOffsetForSlide();
  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: speedOfSlide * durMult * 200),
        top: -screen.cardLiveMaxPixel * game.getTemporaryVisualOffsetForSlide(),
        child: _sizedCard(index, boardNumber, val, bf),
      ),
    ],
  );
}

Widget _sizedCard(index, boardNumber, val, bf) {
  return SizedBox(
    height: screen.cardLiveMaxPixel,
    width: screen.cardLiveMaxPixel,
    child: _card(index, boardNumber, val, bf),
  );
}

Widget _card(index, boardNumber, val, bf) {
  int rowOfIndex = index ~/ 5;
  bool historicalWin = game.getTestHistoricalWin(rowOfIndex, boardNumber);

  return Container(
    padding: EdgeInsets.all(0.005 * screen.cardLiveMaxPixel),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
      child: Container(
        //padding: const EdgeInsets.all(1),
        //height: 500, //oversize so it renders in full and so doesn't pixelate
        //width: 500, //oversize so it renders in full and so doesn't pixelate
        decoration: BoxDecoration(
            border: Border.all(
                color: bf == "b"
                    ? Colors.transparent //bg
                    : historicalWin
                        ? green
                        : Colors.transparent, //bg
                width: bf == "b"
                    ? 0
                    : historicalWin
                        ? 0.05 * screen.cardLiveMaxPixel
                        : 0.05 * screen.cardLiveMaxPixel),
            borderRadius: BorderRadius.circular(
                0.2 * screen.cardLiveMaxPixel), //needed for green border
            color: (!infMode &&
                        game.getDetectBoardSolvedByRow(
                            boardNumber, rowOfIndex)) ||
                    rowOfIndex <
                        game.getFirstVisualRowToShowOnBoard(boardNumber)
                ? Colors.transparent // bg //"hide" after solved board
                : bf == "b"
                    ? rowOfIndex == game.getVisualCurrentRowInt() &&
                            game.getCurrentTyping().length == 5 &&
                            !isLegalWord(game.getCurrentTyping())
                        ? Colors.red
                        : grey
                    : cardColors.getCardColor(index, boardNumber)),
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: _cardText(index, boardNumber),
        ),
      ),
    ),
  );
}

Widget _cardText(index, boardNumber) {
  int rowOfIndex = index ~/ 5;
  return Text(
    game.getCardLetterAtIndex(index).toUpperCase(),
    style: TextStyle(
      /*
        shadows: const <Shadow>[
          Shadow(
            offset: Offset(0, 0),
            blurRadius: 1.0,
            color: bg,
          ),
        ],
         */
      fontSize: screen.cardLiveMaxPixel,
      color: (!infMode &&
                  game.getDetectBoardSolvedByRow(boardNumber, rowOfIndex)) ||
              rowOfIndex < game.getFirstVisualRowToShowOnBoard(boardNumber)
          ? Colors.transparent // bg //"hide" after being solved
          : game.getHighlightedBoard() == -1
              ? Colors.white
              : game.getHighlightedBoard() == boardNumber
                  ? Colors.white
                  : offWhite,
      fontWeight: FontWeight.bold,
    ),
  );
}
