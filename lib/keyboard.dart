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
        itemBuilder: (BuildContext context, int offsetIndex) {
          String kbLetter = keyboardList[keyBoardStartKey + offsetIndex];
          return _kbStackWithMiniGrid(kbLetter, length);
        }),
  );
}

Widget _kbStackWithMiniGrid(kbLetter, length) {
  return Container(
    padding: EdgeInsets.all(0.005 * screen.keyboardSingleKeyLiveMaxPixelHeight),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(
          0.1 * screen.keyboardSingleKeyLiveMaxPixelHeight),
      child: Stack(
        children: [
          Center(
            child: ["<", ">"].contains(kbLetter)
                ? const SizedBox.shrink()
                : _kbMiniGridContainer(kbLetter, length),
          ),
          Center(
              child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                game.onKeyboardTapped(kbLetter);
              },
              child: _kbTextSquare(kbLetter, length),
            ),
          )),
        ],
      ),
    ),
  );
}

Widget _kbTextSquare(kbLetter, length) {
  return SizedBox(
      height: screen.keyboardSingleKeyLiveMaxPixelHeight, //double.infinity,
      width: screen.keyboardSingleKeyLiveMaxPixelWidth *
          10 /
          length, //double.infinity,
      child: FittedBox(
          fit: BoxFit.fitHeight,
          child: kbLetter == "<"
              ? Container(
                  padding: const EdgeInsets.all(7),
                  child: const Icon(Icons.keyboard_backspace, color: white))
              : kbLetter == ">"
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
                  : _kbRegularTextCache[kbLetter]));
}

Widget _kbRegularTextConst(kbLetter) {
  return StrokeText(
    text: kbLetter.toUpperCase(),
    strokeWidth: 0.2,
    strokeColor: bg,
    textStyle: const TextStyle(
      color: white,
      height: 1.15,
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );
}

final Map _kbRegularTextCache = {
  for (var kbLetter in keyboardList) (kbLetter): _kbRegularTextConst(kbLetter)
};

Widget _kbMiniGridContainer(kbLetter, length) {
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
        Color color = cardColors.getBestColorForLetter(kbLetter, subIndex);
        return _kbMiniSquareColorCache[color];
      });
}

Widget _kbMiniSquareColorConst(color) {
  return Container(
    decoration: BoxDecoration(
      color: color,
    ),
  );
}

final Map _kbMiniSquareColorCache = {
  for (var color in kbColorsList) (color): _kbMiniSquareColorConst(color)
};
