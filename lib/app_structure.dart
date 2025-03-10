import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'game_logic.dart';
import 'gameboard.dart';
import 'keyboard.dart';
import 'popup_screens.dart';
import 'screen.dart';
import 'src/workarounds.dart';

FocusNode focusNode = FocusNode();

Widget infinitordleWidget() {
  return _scaffold();
}

Widget _scaffold() {
  return Container(
    decoration: const BoxDecoration(color: bg),
    child: Padding(
      padding: EdgeInsets.only(bottom: gestureInset()),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          screen.detectAndUpdateForScreenSize(context);
          return Scaffold(
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
          );
        },
      ),
    ),
  );
}

Widget titleWidget() {
  return InkWell(
    onTap: () {
      showMainPopupScreen();
    },
    child: SizedBox(
      height:
          screen.appBarHeight, //so whole vertical space of appbar is clickable
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: FittedBox(
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable?>[
              game,
              game.targetWordsChangedNotifier,
            ]),
            builder: (BuildContext context, _) {
              return titleWidgetReal();
            },
          ),
        ),
      ),
    ),
  );
}

Widget titleWidgetReal() {
  final int numberWinsCache = game.getWinWords().length;
  final String infText =
      numberWinsCache == 0
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
            color:
                numberWinsCache == 0 || game.expandingBoardEver ? white : green,
          ),
        ),
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
    onKeyEvent: (FocusNode focus, KeyEvent onKey) => KeyEventResult.handled,
    child: KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent keyEvent) {
        if (keyEvent is KeyDownEvent) {
          if (keyboardList.contains(keyEvent.character)) {
            game.onKeyboardTapped(keyEvent.character ?? kNonKey);
          } else if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
            game.onKeyboardTapped(kEnter);
          } else if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
            game.onKeyboardTapped(kBackspace);
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
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ValueListenableBuilder<int>(
              valueListenable: game.highlightedBoardNotifier,
              builder: (BuildContext context, int value, Widget? child) {
                return game.highlightedBoard != -1
                    //click away to de-highlight all boards
                    ? InkWell(
                      onTap: () => game.toggleHighlightedBoard(-1),
                      child: SizedBox(
                        width: screen.scW,
                        height: screen.fullSizeOfGameboards,
                      ),
                    )
                    : const SizedBox.shrink();
              },
            ),
            Wrap(
              spacing: boardSpacer,
              runSpacing: boardSpacer,
              children: <Widget>[
                // Split into 2 halves so that don't get a wrap on 3 + 1 basis
                Wrap(
                  spacing: boardSpacer,
                  runSpacing: boardSpacer,
                  children: List<Widget>.generate(
                    numBoards ~/ 2,
                    (int index) => gameboardWidget(index),
                  ),
                ),
                Wrap(
                  spacing: boardSpacer,
                  runSpacing: boardSpacer,
                  children: List<Widget>.generate(
                    numBoards - (numBoards ~/ 2),
                    (int index) => gameboardWidget(numBoards ~/ 2 + index),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Divider(color: Colors.transparent, height: dividerHeight),
        keyboardRowWidget(0, 10),
        keyboardRowWidget(10, 9),
        keyboardRowWidget(20, 9),
      ],
    ),
  );
}
