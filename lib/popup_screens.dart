// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

FocusNode focusNode = FocusNode();

Future<void> showResetConfirmScreenReal(context) async {
  List winWordsCache = game.getWinWords();
  int numberWinsCache = winWordsCache.length;
  bool gameOver =
      game.getAbCurrentRowInt() >= game.getAbLiveNumRowsPerBoard() &&
          game.winRecordBoards.isNotEmpty &&
          game.winRecordBoards[game.winRecordBoards.length - 1] == -1;
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: bg,
            surfaceTintColor: bg,
            //scrollable: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(appTitle),
                //Spacer(flex: 10),
                SizedBox(
                  //width: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      /*
                      Tooltip(
                          message: game.getExpandingBoard()
                              ? "Turn off expanding board"
                              : "Turn on expanding board",
                          child: IconButton(
                            iconSize: 25,
                            icon: game.getExpandingBoard()
                                ? const Icon(Icons.visibility_outlined)
                                : const Icon(Icons.visibility_off_outlined),
                            onPressed: () {
                              game.toggleExpandingBoardState();
                              setState(() {}); //state inside dialog
                            },
                          )),
                      const SizedBox(width: 8),
                      //Spacer(flex: 1),
                       */
                      Tooltip(
                        message: !g.signedIn() ? "Sign in" : "Sign out",
                        child: !g.signedIn()
                            ? IconButton(
                                iconSize: 25,
                                icon: const Icon(Icons.lock_outlined),
                                onPressed: () {
                                  g.signIn();
                                  Navigator.pop(context, 'OK');
                                  focusNode.requestFocus();
                                },
                              )
                            : IconButton(
                                iconSize: g.getUserIcon() == gUserIconDefault
                                    ? 25
                                    : 50,
                                icon: g.getUserIcon() == gUserIconDefault
                                    ? const Icon(Icons.face_outlined)
                                    : CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(g.getUserIcon())),
                                onPressed: () {
                                  showLogoutConfirmationScreen(context);
                                  focusNode.requestFocus();
                                },
                              ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gameOver
                      ? "You got " +
                          numberWinsCache.toString() +
                          " word" +
                          (numberWinsCache == 1 ? "" : "s") +
                          ": " +
                          winWordsCache.join(", ") +
                          "\n\nYou missed: " +
                          game.targetWords.join(", ")
                      : "You've got " +
                          numberWinsCache.toString() +
                          " word" +
                          (numberWinsCache == 1 ? "" : "s") +
                          ' so far' +
                          (numberWinsCache != 0 ? ":" : "") +
                          ' ' +
                          winWordsCache.join(", ")),
                  const SizedBox(height: 10),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expanding board?'),
                      Tooltip(
                          message: game.getExpandingBoard()
                              ? "Turn off expanding board"
                              : "Turn on expanding board",
                          child: IconButton(
                            iconSize: 25,
                            icon: game.getExpandingBoard()
                                ? const Icon(Icons.visibility_outlined)
                                : const Icon(Icons.visibility_off_outlined),
                            onPressed: () {
                              game.toggleExpandingBoardState();
                              setState(() {}); //state inside dialog
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reset the board?'),
                      Tooltip(
                          message: "Reset the board",
                          child: IconButton(
                            iconSize: 25,
                            icon: const Icon(Icons.refresh_outlined),
                            onPressed: () {
                              showResetConfirmationScreen(context);
                              focusNode.requestFocus();//state inside dialog
                            },
                          )),
                    ],
                  ),
                ],
              ),
            ),
            /*
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
                  //game.resetBoard(),
                  showResetConfirmationScreen(context),
                  focusNode.requestFocus(),
                },
                child: const Text('Reset', style: TextStyle(color: red)),
              ),
            ],
            */
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
        backgroundColor: bg,
        surfaceTintColor: bg,
        title: const Text("Sign out?"),
        //content: Text("Signed in as " + g.getUser()),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              g.signOut();
              Navigator.pop(context, 'OK');
              Navigator.pop(context, 'OK');
            },
            child: const Text('Sign out', style: TextStyle(color: red)),
          ),
        ],
      );
    },
  );
}

Future<void> showResetConfirmationScreen(context) async {
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
            child: const Text('Reset the board', style: TextStyle(color: red)),
          ),
        ],
      );
    },
  );
}
