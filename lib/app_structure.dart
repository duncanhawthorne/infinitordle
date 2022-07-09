import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          onKeyboardTapped(
              keyboardList.indexOf(keyEvent.character ?? " "));
        }
        if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
          onKeyboardTapped(keyboardList.indexOf(">"));
        }
        if (keyEvent.logicalKey == LogicalKeyboardKey.backspace &&
            backspaceSafe) {
          if (backspaceSafe) {
            // (DateTime.now().millisecondsSinceEpoch > lastTimePressedDelete + 200) {
            //workaround to bug which was firing delete key twice
            backspaceSafe = false;
            onKeyboardTapped(keyboardList.indexOf("<"));
            //lastTimePressedDelete = DateTime.now().millisecondsSinceEpoch;
          }
        }
      } else if (keyEvent is KeyUpEvent) {
        if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
          backspaceSafe = true;
        }
      }
    },
    child: streamBuilderWrapperOnDocument(),
  );
}

Widget streamBuilderWrapperOnDocument() {
  if (gUser == gUserDefault) {
    return _wrapStructure();
  } else {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('states').doc(gUser).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
        } else if (snapshot.connectionState == ConnectionState.waiting) {
        } else {
          //print(snapshot);
          var userDocument = snapshot.data;
          //print(userDocument);
          if (userDocument != null && userDocument.exists) {
            String snapshotCurrent = userDocument["data"];
            //print(snapshotCurrent);
            if (gUser != gUserDefault && snapshotCurrent != snapshotLast) {
              if (snapshotCurrent != encodeCurrentGameState()) {
                /*
                p([
                  "load",
                  snapshotCurrent,
                  snapshotLast,
                  encodeCurrentGameState()
                ]);
                 */
                loadFromEncodedState(snapshotCurrent);
              }
              snapshotLast = snapshotCurrent;
            }
          }
        }

        return _wrapStructure();
      },
    );
  }
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
              children: List.generate(numBoards ~/ 2,
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