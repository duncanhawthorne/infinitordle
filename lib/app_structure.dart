import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'firebase.dart';
import 'game_logic.dart';
import 'gameboard.dart';
import 'google_logic.dart';
import 'keyboard.dart';
import 'popup_screens.dart';
import 'saves.dart';
import 'screen.dart';
import 'src/workarounds.dart';

FocusNode focusNode = FocusNode();

Widget infinitordleWidget() {
  return streamBuilderWrapperOnDocument();
}

Widget streamBuilderWrapperOnDocument() {
  return ValueListenableBuilder<String>(
      valueListenable: g.gUserNotifier,
      builder: (BuildContext context, String value, Widget? child) {
        if (!fbOn || !g.signedIn) {
          return _scaffold();
        } else {
          return StreamBuilder<DocumentSnapshot>(
            stream: db!.collection('states').doc(g.gUser).snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              fBase.load(snapshot);
              return _scaffold();
            },
          );
        }
      });
}

Widget _scaffold() {
  return Container(
    decoration: const BoxDecoration(color: bg),
    child: Padding(
      padding: EdgeInsets.only(bottom: gestureInset()),
      child: Scaffold(
        //backgroundColor: bg,
        appBar: AppBar(
          centerTitle: true,
          titleSpacing: 0,
          toolbarHeight: screen.appBarHeight,
          title: titleWidget(),
          backgroundColor: bg,
          scrolledUnderElevation: 0.0,
        ),
        body: bodyWidget(),
      ),
    ),
  );
}

Widget titleWidget() {
  return InkWell(
      onTap: () {
        showResetConfirmScreen();
      },
      child: SizedBox(
        height: screen
            .appBarHeight, //so whole vertical space of appbar is clickable
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: FittedBox(
            child: ListenableBuilder(
                listenable: Listenable.merge([
                  game,
                  game.targetWordsChangedNotifier,
                ]),
                builder: (BuildContext context, _) {
                  return titleWidgetReal();
                }),
          ),
        ),
      ));
}

Widget titleWidgetReal() {
  int numberWinsCache = game.getWinWords().length;
  String infText = numberWinsCache == 0
      ? "o"
      : "∞" * (numberWinsCache ~/ 2) + "o" * (numberWinsCache % 2);
  return RichText(
    text: TextSpan(
      style: TextStyle(
        color: white,
        fontWeight: FontWeight.bold,
        fontSize: screen.appBarHeight * 40 / 56,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),
      children: <TextSpan>[
        const TextSpan(text: appTitle1),
        TextSpan(
            text: infText,
            style: TextStyle(
                color: numberWinsCache == 0 || game.expandingBoardEver
                    ? white
                    : green)),
        const TextSpan(text: appTitle3),
      ],
    ),
  );
}

Widget bodyWidget() {
  return keyboardListenerWrapper();
}

Widget keyboardListenerWrapper() {
  return Focus(
    // https://stackoverflow.com/questions/68333803/flutter-rawkeyboardlistener-triggering-system-sounds-on-macos
    onKeyEvent: (focus, onKey) => KeyEventResult.handled,
    child: KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (keyEvent) {
        if (keyEvent is KeyDownEvent) {
          if (keyboardList.contains(keyEvent.character)) {
            game.onKeyboardTapped(keyEvent.character ?? " ");
          } else if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
            game.onKeyboardTapped(">");
          } else if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
            game.onKeyboardTapped("<");
          }
        }
      },
      child: gameboardAndKeyboard(),
    ),
  );
}

Widget gameboardAndKeyboard() {
  return Container(
    color: bg,
    child: Column(
      children: [
        Stack(alignment: Alignment.center, children: [
          game.highlightedBoard != -1
              ? InkWell(
                  onTap: () => game.toggleHighlightedBoard(-1),
                  child: SizedBox(
                    width: screen.scW,
                    height: screen.fullSizeOfGameboards,
                  ),
                )
              : const SizedBox.shrink(),
          Wrap(
            spacing: boardSpacer,
            runSpacing: boardSpacer,
            children: [
              // Split into 2 halves so that don't get a wrap on 3 + 1 basis
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
          )
        ]),
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
