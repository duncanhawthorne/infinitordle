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
                if (game.getHighlightedBoard() == boardNumber) {
                  game.setHighlightedBoard(-1); //if already set turn off
                } else {
                  game.setHighlightedBoard(boardNumber);
                }
                ss();
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
                    itemBuilder: (BuildContext context, int index) {
                      return _cardFlipper(
                          (game.getAbLiveNumRowsPerBoard() - index ~/ cols - 1) *
                                  cols +
                              index % cols,
                          boardNumber);
                    }),
              ))));
}

Widget _cardFlipper(abIndex, boardNumber) {
  return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: flips.getFlipAngle(abIndex)),
      duration: const Duration(milliseconds: durMult * 500),
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
  int speedOfSlide = game.getTemporaryVisualOffsetForSlide();
  return Stack(
    clipBehavior: Clip.none,
    children: [
      AnimatedPositioned(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: speedOfSlide * durMult * 200),
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
  int rowOfAbIndex = abIndex ~/ cols;
  bool historicalWin = game.getTestHistoricalAbWin(rowOfAbIndex, boardNumber);

  return Container(
    padding: EdgeInsets.all(0.005 * screen.cardLiveMaxPixel),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * screen.cardLiveMaxPixel),
      child: Container(
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
                        game.getDetectBoardSolvedByABRow(
                            boardNumber, rowOfAbIndex)) ||
                    rowOfAbIndex <
                        game.getFirstAbRowToShowOnBoardDueToKnowledge(
                            boardNumber)
                ? Colors.transparent // bg //"hide" after solved board
                : bf == "b"
                    ? rowOfAbIndex == game.getAbCurrentRowInt() &&
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
  int rowOfAbIndex = abIndex ~/ cols;
  return Text(
    game.getCardLetterAtAbIndex(abIndex).toUpperCase(),
    style: TextStyle(
      fontSize: screen.cardLiveMaxPixel,
      color: (!infMode &&
                  game.getDetectBoardSolvedByABRow(
                      boardNumber, rowOfAbIndex)) ||
              rowOfAbIndex <
                  game.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber)
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
