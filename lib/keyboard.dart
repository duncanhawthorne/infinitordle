import 'package:flutter/material.dart';
import 'package:stroke_text/stroke_text.dart';

import 'card_colors.dart';
import 'constants.dart';
import 'game_flips.dart';
import 'game_ephemeral.dart';
import 'game_state.dart';
import 'game_sequencer.dart';
import 'screen.dart';

/// Builds a row of the on-screen keyboard.
/// [keyBoardStartKeyIndex] is the starting index in the [keyboardList].
/// [kbRowLength] is the number of keys in this row.
Widget keyboardRowWidget(int keyBoardStartKeyIndex, int kbRowLength) {
  return Container(
    constraints: BoxConstraints(
      maxWidth:
          screen.keyboardSingleKeyLiveMaxPixelHeight *
          10 /
          screen.keyAspectRatioLive,
      maxHeight: screen.keyboardSingleKeyLiveMaxPixelHeight,
    ),
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(), //ios fix
      itemCount: kbRowLength,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kbRowLength,
        childAspectRatio: 1 / screen.keyAspectRatioLive * (10 / kbRowLength),
      ),
      itemBuilder: (BuildContext context, int offsetIndex) {
        final String kbLetter =
            keyboardList[keyBoardStartKeyIndex + offsetIndex];
        return _kbKeyStack(kbLetter, kbRowLength);
      },
    ),
  );
}

/// Builds an individual key on the keyboard, including its background colors and text/icon.
Widget _kbKeyStack(String kbLetter, int kbRowLength) {
  return Container(
    padding: EdgeInsets.all(0.005 * screen.keyboardSingleKeyLiveMaxPixelHeight),
    child: Stack(
      children: <Widget>[
        Center(
          child: <String>[kBackspace, kEnter].contains(kbLetter)
              ? const SizedBox.shrink()
              : _kbMiniGrid(kbLetter, kbRowLength),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                0.1 * screen.keyboardSingleKeyLiveMaxPixelHeight,
              ),
              onTap: () {
                gameSequencer.onKeyboardTapped(kbLetter);
              },
              child: _kbTextSquare(kbLetter, kbRowLength),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Returns the icon widget for the backspace key.
Widget _backspaceKey() {
  return Container(
    padding: const EdgeInsets.all(7),
    child: const Icon(Icons.keyboard_backspace, color: white),
  );
}

/// Returns the icon widget for the enter key, dynamically changing based on game state.
Widget _enterKey() {
  return Container(
    padding: const EdgeInsets.all(7),
    child: ValueListenableBuilder<bool>(
      valueListenable: gameEphemeral.illegalFiveLetterWordNotifier,
      builder: (BuildContext context, bool value, Widget? child) {
        return gameEphemeral.illegalFiveLetterWord
            ? const Icon(Icons.cancel, color: red)
            : ValueListenableBuilder<int>(
                valueListenable: gameState.currentRowChangedNotifier,
                builder: (BuildContext context, int value, Widget? child) {
                  return gameState.readyForStreakCurrentRow
                      ? const Icon(Icons.fast_forward, color: green)
                      : const Icon(Icons.keyboard_return_sharp, color: white);
                },
              );
      },
    ),
  );
}

/// Builds the visual representation of the key's label or icon.
Widget _kbTextSquare(String kbLetter, int kbRowLength) {
  return SizedBox(
    height: screen.keyboardSingleKeyLiveMaxPixelHeight, //double.infinity,
    width:
        screen.keyboardSingleKeyLiveMaxPixelWidth *
        10 /
        kbRowLength, //double.infinity,
    child: FittedBox(
      fit: BoxFit.fitHeight,
      child: kbLetter == kBackspace
          ? _backspaceKey()
          : kbLetter == kEnter
          ? _enterKey()
          : _kbRegularTextCache[kbLetter],
    ),
  );
}

/// Creates a stroked text widget for a regular letter key.
Widget _kbRegularTextConst(String kbLetter) {
  return StrokeText(
    text: kbLetter.toUpperCase(),
    strokeWidth: 0.2,
    strokeColor: bg,
    textStyle: const TextStyle(
      color: white,
      height: 1.15,
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );
}

/// Cache for the regular letter key widgets.
final Map<String, Widget> _kbRegularTextCache = <String, Widget>{
  for (String kbLetter in keyboardList)
    (kbLetter): _kbRegularTextConst(kbLetter),
};

/// Builds a mini-grid inside a key to show statuses for multiple boards simultaneously.
Widget _kbMiniGrid(String kbLetter, int kbRowLength) {
  return ValueListenableBuilder<int>(
    valueListenable: gameEphemeral.highlightedBoardNotifier,
    builder: (BuildContext context, int value, Widget? child) {
      final bool someBoardHighlighted = gameEphemeral.highlightedBoard != -1;
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: someBoardHighlighted ? 1 : numBoards,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: someBoardHighlighted
              ? 1
              : numBoards ~/ screen.numPresentationBigRowsOfBoards,
          childAspectRatio:
              (someBoardHighlighted
                  ? 1
                  : 1 /
                        ((numBoards / screen.numPresentationBigRowsOfBoards) /
                            screen.numPresentationBigRowsOfBoards)) /
              screen.keyAspectRatioLive *
              (10 / kbRowLength),
        ),
        itemBuilder: (BuildContext context, int subIndex) {
          return _kbMiniSquareColorChooser(kbLetter, subIndex);
        },
      );
    },
  );
}

/// Listens to multiple game states to determine the color of a mini-square in a key.
Widget _kbMiniSquareColorChooser(String kbLetter, int subIndex) {
  return ListenableBuilder(
    listenable: Listenable.merge(<Listenable?>[
      gameState,
      gameState.pushUpStepsNotifier,
      gameState.targetWordsChangedNotifier,
      gameFlips.abCardFlourishFlipAnglesNotifier,
    ]),
    builder: (BuildContext context, _) {
      return _kbMiniSquareColorChooserReal(kbLetter, subIndex);
    },
  );
}

/// Retrieves the actual color for a mini-square based on the game logic.
Widget _kbMiniSquareColorChooserReal(String kbLetter, int subIndex) {
  final Color color = cardColors.getBestColorForKeyboardLetter(
    kbLetter,
    subIndex,
  );
  final double radius = 0.1 * screen.keyboardSingleKeyLiveMaxPixelHeight;
  final int numRows = screen.numPresentationBigRowsOfBoards;
  final bool specialHighlighting = gameEphemeral.highlightedBoard != -1;
  return _kbMiniSquareColorRounded(
    color,
    subIndex,
    numRows,
    radius,
    specialHighlighting,
  ); //_kbMiniSquareColorCache[color][subIndex];
}

/// Draws a color-filled box with specific corner radii for the mini-grid in a keyboard key.
Widget _kbMiniSquareColorRounded(
  Color color,
  int subIndex,
  int numRows,
  double radius,
  bool specialHighlighting,
) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.only(
        topLeft: specialHighlighting || subIndex == 0
            ? Radius.circular(radius)
            : const Radius.circular(0),
        topRight:
            specialHighlighting ||
                subIndex == 1 && numRows == 2 ||
                subIndex == 3 && numRows == 1
            ? Radius.circular(radius)
            : const Radius.circular(0),
        bottomLeft:
            specialHighlighting ||
                subIndex == 2 && numRows == 2 ||
                subIndex == 0 && numRows == 1
            ? Radius.circular(radius)
            : const Radius.circular(0),
        bottomRight: specialHighlighting || subIndex == 3
            ? Radius.circular(radius)
            : const Radius.circular(0),
      ),
      color: color,
    ),
  );
}
