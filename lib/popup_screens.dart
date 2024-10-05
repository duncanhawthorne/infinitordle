import 'dart:async';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_logic.dart';
import 'google/google.dart';

FocusNode focusNode = FocusNode();

Future<void> showMainPopupScreen() async {
  _showMainPopupScreenReal(navigatorKey.currentContext!);
}

Future<void> _showMainPopupScreenReal(BuildContext context) async {
  List winWordsCache = game.getWinWords();
  int numberWinsCache = winWordsCache.length;
  bool gameOver = game.gameOver;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: bg,
        surfaceTintColor: bg,
        title: gOn && g.signedIn ? g.signInRow(context) : null,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gOn && !g.signedIn
                  ? g.signInRow(context)
                  : const SizedBox.shrink(),
              gOn && !g.signedIn
                  ? const SizedBox(height: 10)
                  : const SizedBox.shrink(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scrollable board?'),
                  ValueListenableBuilder<bool>(
                    valueListenable: game.expandingBoardNotifier,
                    builder: (BuildContext context, bool value, Widget? child) {
                      return Tooltip(
                          message: game.expandingBoard
                              ? "Turn off scrollable board"
                              : "Turn on scrollable board",
                          child: IconButton(
                            iconSize: 25,
                            icon: game.expandingBoard
                                ? const Icon(Icons.visibility_outlined)
                                : const Icon(Icons.visibility_off_outlined),
                            onPressed: () {
                              game.toggleExpandingBoardState();
                            },
                          ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reset board?'),
                  Tooltip(
                      message: "Reset board",
                      child: IconButton(
                        iconSize: 25,
                        icon: const Icon(Icons.refresh_outlined),
                        onPressed: () {
                          _showResetConfirmationScreen(context);
                          focusNode.requestFocus(); //state inside dialog
                        },
                      )),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(gameOver
                  ? "You got $numberWinsCache word${numberWinsCache == 1 ? "" : "s"}: ${winWordsCache.join(", ")}\n\nYou missed: ${game.targetWords.join(", ")}"
                  : "You've got $numberWinsCache word${numberWinsCache == 1 ? "" : "s"} so far${numberWinsCache != 0 ? ":" : ""} ${winWordsCache.join(", ")}"),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
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
              focusNode.requestFocus();
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
