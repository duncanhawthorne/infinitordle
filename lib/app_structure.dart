// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'ephemeral.dart';
import 'state.dart';
import 'sequencer.dart';
import 'gameboard.dart';
import 'keyboard.dart';
import 'popup_screens.dart';
import 'screen.dart';
import 'src/workarounds.dart';

FocusNode focusNode = FocusNode();

/// Returns the main widget for the Infinitordle game.
class infinitordleWidget extends StatelessWidget {
  const infinitordleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _scaffold();
  }
}

/// Builds the main scaffold of the application, including the AppBar and body.
class _scaffold extends StatelessWidget {
  const _scaffold();

  @override
  Widget build(BuildContext context) {
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
                title: titleWidget(screen.appBarHeight),
                backgroundColor: bg,
                scrolledUnderElevation: 0.0,
              ),
              body: const bodyWidget(),
            );
          },
        ),
      ),
    );
  }
}

/// Builds the interactive title widget in the AppBar.
class titleWidget extends StatelessWidget {
  const titleWidget(this.appBarHeight, {super.key});

  final double appBarHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showMainPopupScreen();
      },
      child: SizedBox(
        height:
        appBarHeight, //so whole vertical space of appbar is clickable
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: FittedBox(
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable?>[
                state.expandingBoardNotifier,
                state.targetWordsChangedNotifier,
              ]),
              builder: (BuildContext context, _) {
                return titleWidgetReal(appBarHeight);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Generates the stylized "infinitordle" title text, showing win count via symbols.
class titleWidgetReal extends StatelessWidget {
  const titleWidgetReal(this.appBarHeight, {super.key});

  final double appBarHeight;

  @override
  Widget build(BuildContext context) {
    final int numberWinsCache = state.getWinWords().length;
    final String infText = numberWinsCache == 0
        ? "o"
        : "∞" * (numberWinsCache ~/ 2) + "o" * (numberWinsCache % 2);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: white,
          fontWeight: FontWeight.bold,
          fontSize: appBarHeight * 40 / 56,
          fontFamily: GoogleFonts.roboto().fontFamily,
        ),
        children: <TextSpan>[
          const TextSpan(text: appTitle1),
          TextSpan(
            text: infText,
            style: TextStyle(
              color: numberWinsCache == 0 || state.expandingBoardEver
                  ? white
                  : green,
            ),
          ),
          const TextSpan(text: appTitle3),
        ],
      ),
    );
  }
}

/// Returns the body widget of the app, wrapped in a keyboard listener.
class bodyWidget extends StatelessWidget {
  const bodyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const keyboardListenerWrapper();
  }
}

/// Wraps the game content to handle physical keyboard events.
class keyboardListenerWrapper extends StatelessWidget {
  const keyboardListenerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      // https://stackoverflow.com/questions/68333803/flutter-rawkeyboardlistener-triggering-system-sounds-on-macos
      onKeyEvent: (FocusNode focus, KeyEvent onKey) => KeyEventResult.handled,
      child: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent keyEvent) {
          if (keyEvent is KeyDownEvent) {
            if (keyboardList.contains(keyEvent.character)) {
              sequencer.onKeyboardTapped(keyEvent.character ?? kNonKey);
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
              sequencer.onKeyboardTapped(kEnter);
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
              sequencer.onKeyboardTapped(kBackspace);
            }
          }
        },
        child: const gameboardAndKeyboard(),
      ),
    );
  }
}

/// Lays out the game boards and the on-screen keyboard.
class gameboardAndKeyboard extends StatelessWidget {
  const gameboardAndKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ValueListenableBuilder<int>(
                    valueListenable: ephemeral.highlightedBoardNotifier,
                    builder: (BuildContext context, int value, Widget? child) {
                      return ephemeral.highlightedBoard != -1
                      //click away to de-highlight all boards
                          ? InkWell(
                        onTap: () => ephemeral.toggleHighlightedBoard(-1),
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
              // ignore: prefer_const_constructors
              keyboardRowWidget(0, 10),
              // ignore: prefer_const_constructors
              keyboardRowWidget(10, 9),
              // ignore: prefer_const_constructors
              keyboardRowWidget(20, 9),
            ],
          );
        }
      ),
    );
  }
}