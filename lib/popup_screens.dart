// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

FocusNode focusNode = FocusNode();

Future<void> showResetConfirmScreenReal(context) async {
  List winWordsCache = game.getWinWords();
  int numberWinsCache = winWordsCache.length;
  bool end = false;
  if (!game.getAboutToWinCache() &&
      game.getAbCurrentRowInt() >= game.getAbLiveNumRowsPerBoard()) {
    end = true;
  }
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(appTitle),
                SizedBox(
                  width: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                          message: game.getExpandingBoard()
                              ? "Turn off expanding board"
                              : "Turn on expanding board",
                          child: IconButton(
                            iconSize: 25,
                            icon: game.getExpandingBoard()
                                ? const Icon(Icons.visibility, color: bg)
                                : const Icon(Icons.visibility_off, color: bg),
                            onPressed: () {
                              game.flipExpandingBoardState();
                              //focusNode.requestFocus();
                              //Navigator.pop(context, 'Cancel');
                              setState(() {}); //state inside dialog
                            },
                          )),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: !g.signedIn() ? "Sign in" : "Sign out",
                        child: !g.signedIn()
                            ? IconButton(
                                iconSize: 25,
                                icon: const Icon(Icons.lock, color: bg),
                                onPressed: () {
                                  g.signIn();
                                  Navigator.pop(context, 'OK');
                                  focusNode.requestFocus();
                                  //ss();
                                },
                              )
                            : IconButton(
                                iconSize: g.getUserIcon() == gUserIconDefault
                                    ? 25
                                    : 50,
                                icon: g.getUserIcon() == gUserIconDefault
                                    ? const Icon(Icons.face, color: bg)
                                    : CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(g.getUserIcon())),
                                onPressed: () {
                                  showLogoutConfirmationScreen(context);
                                  focusNode.requestFocus();
                                  //ss();
                                },
                              ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            content: Text(end
                ? "You got " +
                    numberWinsCache.toString() +
                    " word" +
                    (numberWinsCache == 1 ? "" : "s") +
                    ": " +
                    winWordsCache.join(", ") +
                    "\n\nYou missed: " +
                    game.targetWords.join(", ") +
                    "\n\nReset the board?"
                : "You've got " +
                    numberWinsCache.toString() +
                    " word" +
                    (numberWinsCache == 1 ? "" : "s") +
                    ' so far' +
                    (numberWinsCache != 0 ? ":" : "") +
                    ' ' +
                    winWordsCache.join(", ") +
                    "\n\n"
                        'Lose your progress and reset the board?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => {
                  focusNode.requestFocus(),
                  Navigator.pop(context, 'Cancel')
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => {
                  game.resetBoard(),
                  focusNode.requestFocus(),
                  Navigator.pop(context, 'OK'),
                  //setState(() {}),
                  //ss()
                },
                child: const Text('Reset', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showLogoutConfirmationScreen(context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Do you want to sign out?"),
        content: Text("Signed in as " + g.getUser()),
        actions: <Widget>[
          TextButton(
            onPressed: () => {Navigator.pop(context, 'Cancel')},
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => {
              g.signOut(),
              Navigator.pop(context, 'OK'),
              Navigator.pop(context, 'OK'),
              //setState(() {}),
              //ss()
            },
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}