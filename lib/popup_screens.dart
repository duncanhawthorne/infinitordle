// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/helper.dart';

import 'google_logic.dart';

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
            title: gOn && g.signedIn() ? signInRow(context) : null,
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  gOn && !g.signedIn()
                      ? signInRow(context)
                      : const SizedBox.shrink(),
                  gOn && !g.signedIn()
                      ? const SizedBox(height: 10)
                      : const SizedBox.shrink(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scrollable board?'),
                      Tooltip(
                          message: game.getExpandingBoard()
                              ? "Turn off scrollable board"
                              : "Turn on scrollable board",
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
                      const Text('Reset board?'),
                      Tooltip(
                          message: "Reset board",
                          child: IconButton(
                            iconSize: 25,
                            icon: const Icon(Icons.refresh_outlined),
                            onPressed: () {
                              showResetConfirmationScreen(context);
                              focusNode.requestFocus(); //state inside dialog
                            },
                          )),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
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
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget signInRow(context) {
  if (gOn) {
    StreamSubscription? subscription;
    subscription = g.googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      subscription!.cancel(); //FIXME doesn't work
      p("subscription fire");
      if (account != null) {
        //login
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, 'OK');
            focusNode.requestFocus();
          }
        } catch (e) {
          p("No pop");
        }
      }
    });
  }
  gOn && !g.signedIn()
      ? g.signInSilently()
      : null; //FIXME not suitable for mobile
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(!g.signedIn()
          ? (newLoginButtons && kIsWeb ? "" : "Sign in?")
          : appTitle),
      Tooltip(
        message: !g.signedIn() ? "Sign in" : "Sign out",
        child: !g.signedIn()
            ? newLoginButtons
                ? g.platformAdaptiveSignInButton(context)
                : lockStyleSignInButton(context)
            : IconButton(
                iconSize: g.getUserIcon() == gUserIconDefault ? 25 : 50,
                icon: g.getUserIcon() == gUserIconDefault
                    ? const Icon(Icons.face_outlined)
                    : CircleAvatar(
                        backgroundImage: NetworkImage(g.getUserIcon())),
                onPressed: () {
                  showLogoutConfirmationScreen(context);
                  focusNode.requestFocus();
                },
              ),
      ),
    ],
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
              g.signOutAndExtractDetails();
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
            child: const Text('Reset board', style: TextStyle(color: red)),
          ),
        ],
      );
    },
  );
}
