import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';
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
          return _kbStackWithMiniGrid(kbLetter, kbRowLength);
        }),
  );
}

Widget _kbStackWithMiniGrid(kbLetter, kbRowLength) {
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
                : _kbMiniGridChooser(
                    kbLetter: kbLetter,
                    kbRowLength:
                        kbRowLength),
          ),
          Center(
              child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                game.onKeyboardTapped(kbLetter);
              },
              child: _kbTextSquare(kbLetter, kbRowLength),
            ),
          )),
        ],
      ),
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

// ignore: camel_case_types
class _kbMiniGridChooser extends StatefulWidget {
  final String kbLetter;
  final int kbRowLength;
  const _kbMiniGridChooser(
      {this.kbLetter = "",
      this.kbRowLength = 0});

  @override
  State<_kbMiniGridChooser> createState() => _kbMiniGridChooserState();
}

// ignore: camel_case_types
class _kbMiniGridChooserState extends State<_kbMiniGridChooser> {
  @override
  initState() {
    super.initState();
    //Hack to make these functions available globally
    ssKeyboardChangeFunctionMap[[widget.kbLetter, widget.kbRowLength]] =
        ssKeyboardChange;
  }

  @override
  dispose() {
    if (ssKeyboardChangeFunctionMap[[widget.kbLetter, widget.kbRowLength]] ==
        ssKeyboardChange) {
      ssKeyboardChangeFunctionMap[[widget.kbLetter, widget.kbRowLength]] = null;
    }
    super.dispose();
  }

  void ssKeyboardChange() {
    try {
      setState(() {});
    } catch (e) {
      p(["ssKeyboardChange error ", e.toString()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _kbMiniGrid(widget.kbLetter, widget.kbRowLength);
  }
}

Widget _kbMiniGrid(kbLetter, kbRowLength) {
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
            (10 / kbRowLength),
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
