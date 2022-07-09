import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'dart:math';
import 'package:infinitordle/constants.dart';

Widget gameboardWidget(boardNumber) {
  return Container(
    constraints: BoxConstraints(
        maxWidth: 5 * cardEffectiveMaxPixel, //*0.97
        maxHeight: numRowsPerBoard * cardEffectiveMaxPixel), //*0.97
    child: GridView.builder(
        physics:
        const NeverScrollableScrollPhysics(), //turns off ios scrolling
        itemCount: numRowsPerBoard * 5,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemBuilder: (BuildContext context, int index) {
          return _cardFlipper(index, boardNumber);
        }),
  );
}

Widget _cardFlipper(index, boardNumber) {
  return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: angles[index]),
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
  return Stack(
    clipBehavior: Clip.none,
    children: [
      //oneStepState == 0 ?
      //_sizedCard(index, boardNumber, val, bf)
      //:
      AnimatedPositioned(
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: oneStepState * durMult * 200), //when oneStepState = 0 then will instantly transition
        top: -cardEffectiveMaxPixel * oneStepState,
        child: _sizedCard(index, boardNumber, val, bf),
      ),
    ],
  );
}

Widget _sizedCard(index, boardNumber, val, bf) {
  return SizedBox(
    height: cardEffectiveMaxPixel,
    width: cardEffectiveMaxPixel,
    child: _card(index, boardNumber, val, bf),
  );
}

Widget _card(index, boardNumber, val, bf) {
  int rowOfIndex = index ~/ 5;
  var wordForRowOfIndex = gameboardEntries
      .sublist((5 * rowOfIndex).toInt(), (5 * (rowOfIndex + 1)).toInt())
      .join("");
  bool legalOrShort = typeCountInWord != 5 || oneLegalWordForRedCardsCache;

  bool infPreviousWin5 = false;
  if (infSuccessWords.contains(wordForRowOfIndex)) {
    if (infSuccessBoardsMatchingWords[
    infSuccessWords.indexOf(wordForRowOfIndex)] ==
        boardNumber) {
      infPreviousWin5 = true;
    }
  }
  return Container(
    padding: EdgeInsets.all(0.005 * cardEffectiveMaxPixel),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0.2 * cardEffectiveMaxPixel),
      child: Container(
        //padding: const EdgeInsets.all(1),
        //height: 500, //oversize so it renders in full and so doesn't pixelate
        //width: 500, //oversize so it renders in full and so doesn't pixelate
        decoration: BoxDecoration(
            border: Border.all(
                color: bf == "b"
                    ? Colors.transparent //bg
                    : infPreviousWin5
                    ? Colors.green
                    : Colors.transparent, //bg
                width: bf == "b"
                    ? 0
                    : infPreviousWin5
                    ? 0.05 * cardEffectiveMaxPixel //2
                    : 0),
            borderRadius: BorderRadius.circular(
                0.2 * cardEffectiveMaxPixel), //needed for green border
            color: !infMode && detectBoardSolvedByRow(boardNumber, rowOfIndex)
                ? Colors.transparent // bg //"hide" after solved board
                : bf == "b"
                ? rowOfIndex == currentWord && !legalOrShort
                ? Colors.red
                : grey
                : getCardColor(index, boardNumber)),
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
    gameboardEntries[index].toUpperCase(),
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
      fontSize: cardEffectiveMaxPixel,
      color: !infMode && detectBoardSolvedByRow(boardNumber, rowOfIndex)
          ? Colors.transparent // bg //"hide" after being solved
          : Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );
}