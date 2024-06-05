import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';
//import 'package:get/get.dart';
import 'package:refreshed/refreshed.dart';
import 'package:stroke_text/stroke_text.dart';

Widget keyboardRowWidget(keyBoardStartKeyIndex, kbRowLength) {
  return Container(
    constraints: BoxConstraints(
        maxWidth: screen.keyboardSingleKeyLiveMaxPixelHeight *
            10 /
            screen.keyAspectRatioLive,
        maxHeight: screen.keyboardSingleKeyLiveMaxPixelHeight),
    child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), //ios fix
        itemCount: kbRowLength,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: kbRowLength,
          childAspectRatio: 1 / screen.keyAspectRatioLive * (10 / kbRowLength),
        ),
        itemBuilder: (BuildContext context, int offsetIndex) {
          String kbLetter = keyboardList[keyBoardStartKeyIndex + offsetIndex];
          return _kbKeyStack(kbLetter, kbRowLength);
        }),
  );
}

Widget _kbKeyStack(kbLetter, kbRowLength) {
  return Container(
    padding: EdgeInsets.all(0.005 * screen.keyboardSingleKeyLiveMaxPixelHeight),
    child: Stack(
      children: [
        Center(
          child: ["<", ">"].contains(kbLetter)
              ? const SizedBox.shrink()
              : _kbMiniGrid(kbLetter, kbRowLength),
        ),
        Center(
            child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
                0.1 * screen.keyboardSingleKeyLiveMaxPixelHeight),
            onTap: () {
              game.onKeyboardTapped(kbLetter);
            },
            child: _kbTextSquare(kbLetter, kbRowLength),
          ),
        )),
      ],
    ),
  );
}

Widget _kbTextSquare(kbLetter, kbRowLength) {
  return SizedBox(
      height: screen.keyboardSingleKeyLiveMaxPixelHeight, //double.infinity,
      width: screen.keyboardSingleKeyLiveMaxPixelWidth *
          10 /
          kbRowLength, //double.infinity,
      child: FittedBox(
          fit: BoxFit.fitHeight,
          child: kbLetter == "<"
              ? Container(
                  padding: const EdgeInsets.all(7),
                  child: const Icon(Icons.keyboard_backspace, color: white))
              : kbLetter == ">"
                  ? Container(
                      padding: const EdgeInsets.all(7),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: game.illegalFiveLetterWord,
                        builder:
                            (BuildContext context, bool value, Widget? child) {
                          return game.isIllegalFiveLetterWord()
                              ? const Icon(Icons.cancel, color: red)
                              : game.getReadyForStreakCurrentRow()
                                  ? const Icon(Icons.fast_forward, color: green)
                                  : const Icon(Icons.keyboard_return_sharp,
                                      color: white);
                        },
                      ))
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

Widget _kbMiniGrid(kbLetter, kbRowLength) {
  return ValueListenableBuilder<int>(
      valueListenable: game.highlightedBoard,
      builder: (BuildContext context, int value, Widget? child) {
        return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: game.getHighlightedBoard() != -1 ? 1 : numBoards,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: game.getHighlightedBoard() != -1
                  ? 1
                  : numBoards ~/ screen.numPresentationBigRowsOfBoards,
              childAspectRatio: (game.getHighlightedBoard() != -1
                      ? 1
                      : 1 /
                          ((numBoards / screen.numPresentationBigRowsOfBoards) /
                              screen.numPresentationBigRowsOfBoards)) /
                  screen.keyAspectRatioLive *
                  (10 / kbRowLength),
            ),
            itemBuilder: (BuildContext context, int subIndex) {
              //Color color = cardColors.getBestColorForLetter(kbLetter, subIndex);
              //return _kbMiniSquareColorCache[color];
              return Obx(() => _kbMiniSquareColorChooser(kbLetter, subIndex));
            });
      });
}

Widget _kbMiniSquareColorChooser(kbLetter, subIndex) {
  Color color = cardColors.getBestColorForLetter(kbLetter, subIndex);
  double radius = 0.1 * screen.keyboardSingleKeyLiveMaxPixelHeight;
  int numRows = screen.numPresentationBigRowsOfBoards;
  bool specialHighlighting = game.getHighlightedBoard() != -1;
  return _kbMiniSquareColorRounded(color, subIndex, numRows, radius,
      specialHighlighting); //_kbMiniSquareColorCache[color][subIndex];
}

Widget _kbMiniSquareColorRounded(
    color, subIndex, numRows, radius, specialHighlighting) {
  return Container(
    decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: specialHighlighting || subIndex == 0
              ? Radius.circular(radius)
              : const Radius.circular(0),
          topRight: specialHighlighting ||
                  subIndex == 1 && numRows == 2 ||
                  subIndex == 3 && numRows == 1
              ? Radius.circular(radius)
              : const Radius.circular(0),
          bottomLeft: specialHighlighting ||
                  subIndex == 2 && numRows == 2 ||
                  subIndex == 0 && numRows == 1
              ? Radius.circular(radius)
              : const Radius.circular(0),
          bottomRight: specialHighlighting || subIndex == 3
              ? Radius.circular(radius)
              : const Radius.circular(0),
        ),
        color: color),
  );
}

/*
final Map _kbMiniSquareColorCache = {
  for (var color in kbColorsList) (color): {
    for (var subIndex in [0,1,2,3]) (subIndex): //FIXME
    _kbMiniSquareColorConst(color, subIndex)}
};
 */
