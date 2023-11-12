import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/globals.dart';
import 'package:infinitordle/keyboard.dart';
import 'package:infinitordle/gameboard.dart';
import 'package:infinitordle/helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FocusNode focusNode = FocusNode();

Widget infinitordleWidget() {
  return streamBuilderWrapperOnDocument();
}

Widget streamBuilderWrapperOnDocument() {
  if (!g.signedIn()) {
    return _scaffold();
  } else {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('states').doc(g.getUser()).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
        } else if (snapshot.connectionState == ConnectionState.waiting) {
        } else {
          var userDocument = snapshot.data;
          if (userDocument != null && userDocument.exists) {
            String snapshotCurrent = userDocument["data"];
            if (g.signedIn() && !recentSnapshotsCache.contains(snapshotCurrent)) {
              if (snapshotCurrent != game.getEncodeCurrentGameState()) {
                game.loadFromEncodedState(snapshotCurrent, false);
              }
              recentSnapshotsCache.add(snapshotCurrent);
              if (recentSnapshotsCache.length > 5) {
                recentSnapshotsCache.removeAt(0);
              }
            }
          }
        }
        return _scaffold();
      },
    );
  }
}

Widget _scaffold() {
  return Scaffold(
    appBar: AppBar(
      centerTitle: true,
      toolbarHeight: screen.appBarHeight,
      title: titleWidget(),
      backgroundColor: bg,
    ),
    body: bodyWidget(),
  );
}

Widget titleWidget() {
  int numberWinsCache = game.getWinWords().length;
  var infText = numberWinsCache == 0
      ? "o"
      : "∞" * (numberWinsCache ~/ 2) + "o" * (numberWinsCache % 2);
  return InkWell(
      onTap: () {
        showResetConfirmScreen();
      },
      child: SizedBox(
        height: screen
            .appBarHeight, //so whole vertical space of appbar is clickable
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: bg),
          child: FittedBox(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: screen.appBarHeight * 40 / 56,
                ),
                children: <TextSpan>[
                  const TextSpan(text: appTitle1),
                  TextSpan(
                      text: infText,
                      style: TextStyle(
                          color: numberWinsCache == 0 ||
                                  game.getExpandingBoardEver()
                              ? Colors.white
                              : green)),
                  const TextSpan(text: appTitle3),
                ],
              ),
            ),
          ),
        ),
      ));
}

Widget bodyWidget() {
  return keyboardListenerWrapper();
}

Widget keyboardListenerWrapper() {
  return KeyboardListener(
    focusNode: focusNode,
    autofocus: true,
    onKeyEvent: (keyEvent) {
      if (keyEvent is KeyDownEvent) {
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
            backspaceSafeCache = false;
            game.onKeyboardTapped(keyboardList.indexOf("<"));
          }
        }
      } else if (keyEvent is KeyUpEvent) {
        if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
          backspaceSafeCache = true;
        }
      }
    },
    child: gameboardAndKeyboard(),
  );
}

Widget gameboardAndKeyboard() {
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
