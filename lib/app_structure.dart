// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'ephemeral.dart';
import 'gameboard.dart';
import 'keyboard.dart';
import 'popup_screens.dart';
import 'screen.dart';
import 'sequencer.dart';
import 'src/workarounds.dart';
import 'state.dart';

FocusNode focusNode = FocusNode();

/// Returns the main widget for the Infinitordle game.
class infinitordleWidget extends StatelessWidget {
  const infinitordleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: gestureInset()),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            screen.calculateLayoutDimensions(constraints);
            return Scaffold(
              //backgroundColor: bg,
              appBar: AppBar(
                centerTitle: true,
                titleSpacing: 0,
                toolbarHeight: screen.appBarHeight,
                backgroundColor: bg,
                scrolledUnderElevation: 0.0,
                flexibleSpace: const InkWell(
                  onTap: showMainPopupScreen,
                  child: SizedBox.expand(),
                ),
                title: titleWidget(screen.appBarHeight),
              ),
              body: keyboardListenerWrapper(
                constraints.maxHeight,
                constraints.maxWidth,
              ),
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
    return IgnorePointer(
      child: FittedBox(
        fit: BoxFit.scaleDown,
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

/// Wraps the game content to handle physical keyboard events.
class keyboardListenerWrapper extends StatelessWidget {
  const keyboardListenerWrapper(
    this.constraintHeight,
    this.constraintWidth, {
    super.key,
  });

  final double constraintHeight;
  final double constraintWidth;

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
            if (keyboardList.contains(keyEvent.character?.toLowerCase())) {
              sequencer.onKeyboardTapped(
                keyEvent.character?.toLowerCase() ?? kNonKey,
              );
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
              sequencer.onKeyboardTapped(kEnter);
            } else if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
              sequencer.onKeyboardTapped(kBackspace);
            }
          }
        },
        child: gameboardAndKeyboard(constraintHeight, constraintWidth),
      ),
    );
  }
}

/// Lays out the game boards and the on-screen keyboard.
class gameboardAndKeyboard extends StatelessWidget {
  const gameboardAndKeyboard(
    this.constraintHeight,
    this.constraintWidth, {
    super.key,
  });

  //constraint variables not used directly, but if they change then screen has changed, so need to rebuild
  final double constraintHeight;
  final double constraintWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (ephemeral.highlightedBoard != -1) {
          ephemeral.toggleHighlightedBoard(-1);
        }
      },
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: boardSpacer,
            runSpacing: boardSpacer,
            alignment: WrapAlignment.center,
            children: <Widget>[
              Wrap(
                spacing: boardSpacer,
                runSpacing: boardSpacer,
                children: List<Widget>.generate(
                  numBoards ~/ 2,
                  (int index) =>
                      gameboardWidget(index, screen.cardLiveMaxPixel),
                ),
              ),
              Wrap(
                spacing: boardSpacer,
                runSpacing: boardSpacer,
                children: List<Widget>.generate(
                  numBoards - (numBoards ~/ 2),
                  (int index) => gameboardWidget(
                    numBoards ~/ 2 + index,
                    screen.cardLiveMaxPixel,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.transparent, height: dividerHeight),
          ...<(int, int)>[(0, 10), (10, 9), (20, 9)].map(
            ((int, int) row) => SizedBox(
              width:
                  screen.keyboardSingleKeyLiveMaxPixelHeight *
                  kMaxKbRowLength /
                  screen.keyAspectRatioLive,
              height: screen.keyboardSingleKeyLiveMaxPixelHeight,
              child: keyboardRowWidget(
                row.$1, // starting index
                row.$2, // row length
                screen.keyboardSingleKeyLiveMaxPixelHeight,
                screen.numPresentationBigRowsOfBoards,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
