import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

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
      //borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Center(
            child: ["<", ">", " "].contains(keyboardList[index])
                ? const SizedBox.shrink()
                : _kbMiniGridContainer(index, length),
          ),
          Center(
              child: keyboardList[index] == " "
                  ? const SizedBox.shrink()
                  // ignore: dead_code
                  : false && noAnimations
                      // ignore: dead_code
                      ? GestureDetector(
                          onTap: () {
                            game.onKeyboardTapped(index);
                          },
                          child: _kbTextSquare(index),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              game.onKeyboardTapped(index);
                            },
                            child: Container(child: _kbTextSquare(index)),
                          ),
                        )),
        ],
      ),
    ),
  );
}

Widget _kbTextSquare(index) {
  return SizedBox(
      height:
          double.infinity, //keyboardSingleKeyEffectiveMaxPixelHeight, //500,
      width: double
          .infinity, // keyboardSingleKeyEffectiveMaxPixelHeight / keyAspectRatio, //500,
      child: FittedBox(
          fit: BoxFit.fitHeight,
          child: keyboardList[index] == "<"
              ? Container(
                  padding: const EdgeInsets.all(7),
                  child:
                      const Icon(Icons.keyboard_backspace, color: Colors.white))
              : keyboardList[index] == ">"
                  ? Container(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                          game.getIsStreak()
                              ? Icons.fast_forward
                              : Icons.keyboard_return_sharp,
                          color: game.getIsStreak() ? green : Colors.white))
                  : Text(
                      keyboardList[index].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(0, 0),
                              blurRadius: 1.0,
                              color: bg,
                            ),
                          ]),
                    )));
}

Widget _kbMiniGridContainer(index, length) {
  return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: numBoards,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: numBoards ~/ screen.numPresentationBigRowsOfBoards,
        childAspectRatio: 1 /
            ((numBoards / screen.numPresentationBigRowsOfBoards) /
                screen.numPresentationBigRowsOfBoards) /
            screen.keyAspectRatioLive *
            (10 / length),
      ),
      itemBuilder: (BuildContext context, int subIndex) {
        return _kbMiniSquareColor(index, subIndex);
      });
}

Widget _kbMiniSquareColor(index, subIndex) {
  //return AnimatedContainer(
  //  duration: const Duration(milliseconds: 500),
  //  curve: Curves.fastOutSlowIn,
  return Container(
    height: 1000,
    decoration: BoxDecoration(
      color: cardColors.getBestColorForLetter(index, subIndex),
    ),
  );
}
