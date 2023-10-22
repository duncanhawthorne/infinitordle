import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'dart:math';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/game_logic.dart';
import 'package:infinitordle/card_colors.dart';
import 'package:infinitordle/card_flips.dart';

Widget gameboardWidget(boardNumber) {
  return ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * cardLiveMaxPixel),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () {
                //var ss = globalFunctions[0];
                if (highlightedBoard == boardNumber) {
                  highlightedBoard = -1; //if already set turn off
                } else {
                  highlightedBoard = boardNumber;
                }
                ss();
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: 5 * cardLiveMaxPixel, //*0.97
                    maxHeight: numRowsPerBoard * cardLiveMaxPixel), //*0.97
                child: GridView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), //turns off ios scrolling
                    itemCount: numRowsPerBoard * 5,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return _cardFlipper(index, boardNumber);
                    }),
              ))));
}

Widget _cardFlipper(index, boardNumber) {
  return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: flips.getFlipAngle(index)),
      duration: Duration(milliseconds: durMult * 500),
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
  int speedOfSlide = temporaryVisualOffsetForSlide;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: speedOfSlide * durMult * 200),
        top: -cardLiveMaxPixel * temporaryVisualOffsetForSlide,
        child: _sizedCard(index, boardNumber, val, bf),
      ),
    ],
  );
}

Widget _sizedCard(index, boardNumber, val, bf) {
  return SizedBox(
    height: cardLiveMaxPixel,
    width: cardLiveMaxPixel,
    child: _card(index, boardNumber, val, bf),
  );
}

Widget _card(index, boardNumber, val, bf) {
  int rowOfIndex = index ~/ 5;
  bool historicalWin = game.getTestHistoricalWin(rowOfIndex, boardNumber);

  return Container(
    padding: EdgeInsets.all(0.005 * cardLiveMaxPixel),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * cardLiveMaxPixel),
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
                        ? 0.05 * cardLiveMaxPixel
                        : 0.05 * cardLiveMaxPixel),
            borderRadius: BorderRadius.circular(
                0.2 * cardLiveMaxPixel), //needed for green border
            color: !infMode &&
                    game.getDetectBoardSolvedByRow(boardNumber, rowOfIndex)
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
      fontSize: cardLiveMaxPixel,
      color: !infMode && game.getDetectBoardSolvedByRow(boardNumber, rowOfIndex)
          ? Colors.transparent // bg //"hide" after being solved
          : highlightedBoard == -1
              ? Colors.white
              : highlightedBoard == boardNumber
                  ? Colors.white
                  : offWhite,
      fontWeight: FontWeight.bold,
    ),
  );
}
