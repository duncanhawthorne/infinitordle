import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/game_logic.dart';

Widget keyboardRowWidget(keyBoardStartKey, length) {
  return Container(
    constraints: BoxConstraints(
        maxWidth:
            keyboardSingleKeyEffectiveMaxPixelHeight * 10 / keyAspectRatioLive,
        maxHeight: keyboardSingleKeyEffectiveMaxPixelHeight),
    child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), //ios fix
        itemCount: length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: length,
          childAspectRatio: 1 / keyAspectRatioLive * (10 / length),
        ),
        itemBuilder: (BuildContext context, int index) {
          return _kbStackWithMiniGrid(keyBoardStartKey + index, length);
        }),
  );
}

Widget _kbStackWithMiniGrid(index, length) {
  return Container(
    padding: EdgeInsets.all(0.005 * keyboardSingleKeyEffectiveMaxPixelHeight),
    child: ClipRRect(
      borderRadius:
          BorderRadius.circular(0.1 * keyboardSingleKeyEffectiveMaxPixelHeight),
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
                            onKeyboardTapped(index);
                          },
                          child: _kbTextSquare(index),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onKeyboardTapped(index);
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
                      child: Icon(Icons.keyboard_return_sharp,
                          color: onStreakForKeyboardIndicatorCache
                              ? Colors.green
                              : Colors.white))
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
        crossAxisCount: numBoards ~/ numPresentationBigRowsOfBoards,
        childAspectRatio: 1 /
            ((numBoards / numPresentationBigRowsOfBoards) /
                numPresentationBigRowsOfBoards) /
            keyAspectRatioLive *
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
      color: getBestColorForLetter(index, subIndex),
    ),
  );
}
