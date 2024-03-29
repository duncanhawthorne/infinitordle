import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';
import 'package:stroke_text/stroke_text.dart';

Widget keyboardRowWidget(keyBoardStartKey, length) {
  return Container(
    constraints: BoxConstraints(
        maxWidth: screen.keyboardSingleKeyLiveMaxPixelHeight *
            10 /
            screen.keyAspectRatioLive,
        maxHeight: screen.keyboardSingleKeyLiveMaxPixelHeight),
    child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), //ios fix
        itemCount: length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: length,
          childAspectRatio: 1 / screen.keyAspectRatioLive * (10 / length),
        ),
        itemBuilder: (BuildContext context, int index) {
          return _kbStackWithMiniGrid(keyBoardStartKey + index, length);
        }),
  );
}

Widget _kbStackWithMiniGrid(index, length) {
  return Container(
    padding: EdgeInsets.all(0.005 * screen.keyboardSingleKeyLiveMaxPixelHeight),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(
          0.1 * screen.keyboardSingleKeyLiveMaxPixelHeight),
      child: Stack(
        children: [
          Center(
            child: ["<", ">"].contains(keyboardList[index])
                ? const SizedBox.shrink()
                : _kbMiniGridContainer(index, length),
          ),
          Center(
              child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                game.onKeyboardTapped(index);
              },
              child: _kbTextSquare(index, length),
            ),
          )),
        ],
      ),
    ),
  );
}

Widget _kbTextSquare(index, length) {
  return SizedBox(
      height: screen.keyboardSingleKeyLiveMaxPixelHeight, //double.infinity,
      width: screen.keyboardSingleKeyLiveMaxPixelWidth *
          10 /
          length, //double.infinity,
      child: FittedBox(
          fit: BoxFit.fitHeight,
          child: keyboardList[index] == "<"
              ? Container(
                  padding: const EdgeInsets.all(7),
                  child: const Icon(Icons.keyboard_backspace, color: white))
              : keyboardList[index] == ">"
                  ? Container(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                          game.isIllegalWordEntered()
                              ? Icons.cancel
                              : game.getReadyForStreakCurrentRow()
                                  ? Icons.fast_forward
                                  : Icons.keyboard_return_sharp,
                          color: game.isIllegalWordEntered()
                              ? red
                              : game.getReadyForStreakCurrentRow()
                                  ? green
                                  : white))
                  : StrokeText(
                      text: keyboardList[index].toUpperCase(),
                      strokeWidth: 0.2,
                      strokeColor: bg,
                      //textAlign: TextAlign.center,
                      textStyle: const TextStyle(
                        color: white,
                        height: m3 ? 1.15 : null,
                        leadingDistribution:
                            m3 ? TextLeadingDistribution.even : null,
                        /*
                          shadows: <Shadow>[
                            //impact font shadows
                            Shadow(
                              offset: Offset(0, 0),
                              blurRadius: 1.0,
                              color: bg,
                            ),
                          ]
                          */
                      ),
                    )));
}

Widget _kbMiniGridContainer(index, length) {
  return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: game.highlightedBoard != -1 ? 1 : numBoards,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: game.highlightedBoard != -1
            ? 1
            : numBoards ~/ screen.numPresentationBigRowsOfBoards,
        childAspectRatio: (game.highlightedBoard != -1
                ? 1
                : 1 /
                    ((numBoards / screen.numPresentationBigRowsOfBoards) /
                        screen.numPresentationBigRowsOfBoards)) /
            screen.keyAspectRatioLive *
            (10 / length),
      ),
      itemBuilder: (BuildContext context, int subIndex) {
        return _kbMiniSquareColor(index, subIndex);
      });
}

Widget _kbMiniSquareColor(kbIndex, subIndex) {
  return Container(
    //height: 1000,
    decoration: BoxDecoration(
      color: cardColors.getBestColorForLetter(kbIndex, subIndex),
    ),
  );
}
