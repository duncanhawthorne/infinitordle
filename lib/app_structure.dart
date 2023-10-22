import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/keyboard.dart';
import 'package:infinitordle/gameboard.dart';
import 'package:infinitordle/game_logic.dart';

FocusNode focusNode = FocusNode();

Widget bodyWidget() {
  return keyboardListenerWrapper();
}

Widget keyboardListenerWrapper() {
  return KeyboardListener(
    focusNode: focusNode,
    autofocus: true,
    onKeyEvent: (keyEvent) {
      if (keyEvent is KeyDownEvent) {
        //if (keyEvent.runtimeType.toString() == 'KeyDownEvent') {
        if (keyboardList.contains(keyEvent.character)) {
          game.onKeyboardTapped(
              keyboardList.indexOf(keyEvent.character ?? " "));
        }
        if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
          game.onKeyboardTapped(keyboardList.indexOf(">"));
        }
        if (keyEvent.logicalKey == LogicalKeyboardKey.backspace &&
            backspaceSafeCache) {
          if (backspaceSafeCache) {
            // (DateTime.now().millisecondsSinceEpoch > lastTimePressedDelete + 200) {
            //workaround to bug which was firing delete key twice
            backspaceSafeCache = false;
            game.onKeyboardTapped(keyboardList.indexOf("<"));
            //lastTimePressedDelete = DateTime.now().millisecondsSinceEpoch;
          }
        }
      } else if (keyEvent is KeyUpEvent) {
        if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
          backspaceSafeCache = true;
        }
      }
    },
    child: _wrapStructure(),
  );
}

Widget _wrapStructure() {
  return Container(
    color: bg,
    child: Column(
      children: [
        Wrap(
          spacing: boardSpacer,
          runSpacing: boardSpacer,
          children: [
            //split into 2 so that don't get a wrap on 3 + 1 basis. Note that this is why 2 is hardcoded below
            Wrap(
              spacing: boardSpacer,
              runSpacing: boardSpacer,
              children: List.generate(
                  numBoards ~/ 2, (index) => gameboardWidget(index)),
            ),
            Wrap(
              spacing: boardSpacer,
              runSpacing: boardSpacer,
              children: List.generate(numBoards - (numBoards ~/ 2),
                  (index) => gameboardWidget(numBoards ~/ 2 + index)),
            ),
          ],
        ),
        const Divider(
          color: Colors.transparent,
          height: dividerHeight,
        ),
        keyboardRowWidget(0, 10),
        keyboardRowWidget(10, 9),
        keyboardRowWidget(20, 9)
      ],
    ),
  );
}
