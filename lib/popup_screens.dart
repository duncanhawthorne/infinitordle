import 'dart:async';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_logic.dart';
import 'google/google.dart';

FocusNode focusNodePopup = FocusNode();

Future<void> showMainPopupScreen() async {
  await _showMainPopupScreenReal(navigatorKey.currentContext!);
}

Future<void> _showMainPopupScreenReal(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: bg,
        surfaceTintColor: bg,
        content: SingleChildScrollView(
          child: ValueListenableBuilder<bool>(
            valueListenable: g.loggingInProcess,
            builder: (BuildContext context, bool value, Widget? child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children:
                    <Widget?>[
                      signInRow(context),
                      !g.loggingInProcess.value
                          ? null
                          : googleWidgetRow(context),
                      scrollableBoardRow(context),
                      resetRow(context),
                      const Divider(),
                      wordsWonRow(context),
                    ].whereType<Widget>().toList(),
              );
            },
          ),
        ),
      );
    },
  );
}

Widget signInRow(BuildContext context) {
  g.googleLogoutConfirmationFunction = showLogoutConfirmationScreen;
  return ValueListenableBuilder<String>(
    valueListenable: g.gUserNotifier,
    builder: (BuildContext context, String stringText, Widget? child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(!g.signedIn ? "Sign in?" : appTitle),
          Tooltip(
            message: !g.signedIn ? "Sign in" : "Sign out",
            child: g.loginLogoutWidget(context, 25, Colors.white),
          ),
        ],
      );
    },
  );
}

Widget googleWidgetRow(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      ValueListenableBuilder<bool>(
        valueListenable: g.loggingInProcess,
        builder: (BuildContext context, bool value, Widget? child) {
          return Visibility(
            visible: g.loggingInProcess.value,
            maintainState: false,
            child: g.gWidget,
          );
        },
      ),
    ],
  );
}

Widget resetRow(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      const Text('Reset board?'),
      Tooltip(
        message: "Reset board",
        child: IconButton(
          iconSize: 25,
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () {
            _showResetConfirmationScreen(context);
            focusNodePopup.requestFocus(); //state inside dialog
          },
        ),
      ),
    ],
  );
}

Widget scrollableBoardRow(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      const Text('Scrollable board?'),
      ValueListenableBuilder<bool>(
        valueListenable: game.expandingBoardNotifier,
        builder: (BuildContext context, bool value, Widget? child) {
          return Tooltip(
            message:
                game.expandingBoard
                    ? "Turn off scrollable board"
                    : "Turn on scrollable board",
            child: IconButton(
              iconSize: 25,
              icon:
                  game.expandingBoard
                      ? const Icon(Icons.visibility_outlined)
                      : const Icon(Icons.visibility_off_outlined),
              onPressed: () {
                game.toggleExpandingBoardState();
              },
            ),
          );
        },
      ),
    ],
  );
}

Widget wordsWonRow(BuildContext context) {
  final List<String> winWordsCache = game.getWinWords();
  final int numberWinsCache = winWordsCache.length;
  final bool gameOver = game.gameOver;
  return Text(
    gameOver
        ? "You got $numberWinsCache word${numberWinsCache == 1 ? "" : "s"}: ${winWordsCache.join(", ")}\n\nYou missed: ${game.targetWords.join(", ")}"
        : "You've got $numberWinsCache word${numberWinsCache == 1 ? "" : "s"} so far${numberWinsCache != 0 ? ":" : ""} ${winWordsCache.join(", ")}",
  );
}

Future<void> _showResetConfirmationScreen(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: bg,
        surfaceTintColor: bg,
        title: const Text("Lose your progress and reset the board?"),
        //content: Text("This will clear the board"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              game.resetBoard();
              focusNodePopup.requestFocus();
              Navigator.pop(context, 'OK');
              Navigator.pop(context, 'OK');
            },
            child: const Text('Reset board', style: TextStyle(color: red)),
          ),
        ],
      );
    },
  );
}

void showLogoutConfirmationScreen() {
  _showLogoutConfirmationScreenReal(navigatorKey.currentContext!);
  focusNodePopup.requestFocus();
}

Future<void> _showLogoutConfirmationScreenReal(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: bg,
        surfaceTintColor: bg,
        title: const Text("Sign out?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              g.logoutNow();
              Navigator.pop(context, 'OK');
              //Navigator.pop(context, 'OK');
            },
            child: const Text('Sign out', style: TextStyle(color: red)),
          ),
        ],
      );
    },
  );
}
