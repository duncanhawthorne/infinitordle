// ignore_for_file: camel_case_types

import 'dart:async';

import 'package:flutter/material.dart';

import 'constants.dart';
import 'google/google.dart';
import 'sequencer.dart';
import 'state.dart';

FocusNode focusNodePopup = FocusNode();

/// Shows the main settings and status popup screen.
Future<void> showMainPopupScreen() async {
  await _showMainPopupScreenReal(navigatorKey.currentContext!);
}

/// Internal helper to build and show the main popup dialog.
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
                children: <Widget?>[
                  signInRow(context),
                  !g.loggingInProcess.value ? null : googleWidgetRow(context),
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

/// Builds the row for signing in/out.
class signInRow extends StatelessWidget {
  const signInRow(this.parentContext, {super.key});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
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
}

/// Builds the Google sign-in widget row.
class googleWidgetRow extends StatelessWidget {
  const googleWidgetRow(this.parentContext, {super.key});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
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
}

/// Builds the row for resetting the game board.
class resetRow extends StatelessWidget {
  const resetRow(this.parentContext, {super.key});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
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
}

/// Builds the row for toggling the scrollable board state.
class scrollableBoardRow extends StatelessWidget {
  const scrollableBoardRow(this.parentContext, {super.key});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Text('Scrollable board?'),
        ValueListenableBuilder<bool>(
          valueListenable: state.expandingBoardNotifier,
          builder: (BuildContext context, bool value, Widget? child) {
            return Tooltip(
              message: state.expandingBoard
                  ? "Turn off scrollable board"
                  : "Turn on scrollable board",
              child: IconButton(
                iconSize: 25,
                icon: state.expandingBoard
                    ? const Icon(Icons.visibility_outlined)
                    : const Icon(Icons.visibility_off_outlined),
                onPressed: () {
                  state.toggleExpandingBoardState();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Builds the row showing which words have been won and missed.
class wordsWonRow extends StatelessWidget {
  const wordsWonRow(this.parentContext, {super.key});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final List<String> winWordsCache = state.getWinWords();
    final int numberWinsCache = winWordsCache.length;
    final bool gameOver = state.gameOver;
    return Text(
      gameOver
          ? "You got $numberWinsCache word${numberWinsCache == 1 ? "" : "s"}: ${winWordsCache.join(", ")}\n\nYou missed: ${state.targetWords.join(", ")}"
          : "You've got $numberWinsCache word${numberWinsCache == 1 ? "" : "s"} so far${numberWinsCache != 0 ? ":" : ""} ${winWordsCache.join(", ")}",
    );
  }
}

/// Shows a confirmation dialog before resetting the board.
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
              sequencer.resetBoard();
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

/// Shows a confirmation dialog before logging out.
void showLogoutConfirmationScreen() {
  _showLogoutConfirmationScreenReal(navigatorKey.currentContext!);
  focusNodePopup.requestFocus();
}

/// Internal helper to build and show the logout confirmation dialog.
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
