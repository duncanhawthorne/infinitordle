import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'constants.dart';
import 'game_logic.dart';
import 'google_logic.dart';
import 'helper.dart';

const bool _newLoginButtons = false;
FocusNode focusNode = FocusNode();

Future<void> showResetConfirmScreen() async {
  showResetConfirmScreenReal(navigatorKey.currentContext!);
}

Future<void> showResetConfirmScreenReal(BuildContext context) async {
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
        title: gOn && g.signedIn ? _signInRow(context) : null,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gOn && !g.signedIn
                  ? _signInRow(context)
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

Widget _signInRow(BuildContext context) {
  if (gOn) {
    StreamSubscription? subscription;
    subscription = g.googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      subscription!.cancel(); //FIXME doesn't work
      debug("subscription fire");
      if (account != null) {
        //login
        try {
          // ignore: use_build_context_synchronously
          if (Navigator.canPop(context)) {
            // ignore: use_build_context_synchronously
            Navigator.pop(context, 'OK');
            focusNode.requestFocus();
          }
        } catch (e) {
          debug("No pop");
        }
      }
    });
  }
  gOn && !g.signedIn
      ? g.signInSilently()
      : null; //FIXME not suitable for mobile
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(!g.signedIn
          ? (_newLoginButtons && kIsWeb ? "" : "Sign in?")
          : appTitle),
      Tooltip(
        message: !g.signedIn ? "Sign in" : "Sign out",
        child: !g.signedIn
            ? _newLoginButtons
                ? g.platformAdaptiveSignInButton(context)
                : lockStyleSignInButton(context)
            : IconButton(
                iconSize: g.gUserIcon == G.gUserIconDefault ? 25 : 50,
                icon: g.gUserIcon == G.gUserIconDefault
                    ? const Icon(Icons.face_outlined)
                    : CircleAvatar(backgroundImage: NetworkImage(g.gUserIcon)),
                onPressed: () {
                  _showLogoutConfirmationScreen(context);
                  focusNode.requestFocus();
                },
              ),
      ),
    ],
  );
}

Future<void> _showLogoutConfirmationScreen(BuildContext context) async {
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
