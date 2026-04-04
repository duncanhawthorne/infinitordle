// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:stroke_text/stroke_text.dart';

import 'card_colors.dart';
import 'constants.dart';
import 'ephemeral.dart';
import 'flips.dart';
import 'sequencer.dart';
import 'state.dart';

/// Builds a row of the on-screen keyboard.
/// [keyBoardStartKeyIndex] is the starting index in the [keyboardList].
/// [kbRowLength] is the number of keys in this row.
class keyboardRowWidget extends StatelessWidget {
  const keyboardRowWidget(
    this.keyBoardStartKeyIndex,
    this.kbRowLength,
    this.numBigRows, {
    super.key,
  });

  final int keyBoardStartKeyIndex;
  final int kbRowLength;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(), //ios fix
          itemCount: kbRowLength,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: kbRowLength,
            childAspectRatio:
                1 /
                ((constraints.maxHeight) /
                    (constraints.maxWidth / kMaxKbRowLength)) *
                (kMaxKbRowLength / kbRowLength),
          ),
          itemBuilder: (BuildContext context, int offsetIndex) {
            final String kbLetter =
                keyboardList[keyBoardStartKeyIndex + offsetIndex];
            return _kbKeyStack(
              kbLetter,
              kbRowLength,
              constraints.maxHeight,
              constraints.maxWidth / kbRowLength,
              numBigRows,
            );
          },
        );
      },
    );
  }
}

/// Builds an individual key on the keyboard, including its background colors and text/icon.
class _kbKeyStack extends StatelessWidget {
  const _kbKeyStack(
    this.kbLetter,
    this.kbRowLength,
    this.keyHeight,
    this.keyWidth,
    this.numBigRows,
  );

  final String kbLetter;
  final int kbRowLength;
  final double keyHeight;
  final double keyWidth;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(0.005 * keyHeight),
      child: Stack(
        children: <Widget>[
          Center(
            child: <String>[kBackspace, kEnter].contains(kbLetter)
                ? const SizedBox.shrink()
                : _kbMiniGrid(
                    kbLetter,
                    kbRowLength,
                    keyHeight,
                    keyWidth,
                    numBigRows,
                  ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(0.1 * keyHeight),
                onTap: () {
                  sequencer.onKeyboardTapped(kbLetter);
                },
                child: _kbTextSquare(
                  kbLetter,
                  kbRowLength,
                  keyHeight,
                  keyWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds the visual representation of the key's label or icon.
class _kbTextSquare extends StatelessWidget {
  const _kbTextSquare(
    this.kbLetter,
    this.kbRowLength,
    this.keyHeight,
    this.keyWidth,
  );

  final String kbLetter;
  final int kbRowLength;
  final double keyHeight;
  final double keyWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: keyHeight, //double.infinity,
      width: keyWidth * kMaxKbRowLength / kbRowLength, //double.infinity,
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: switch (kbLetter) {
          kBackspace => const _backspaceKey(),
          kEnter => const _enterKey(),
          _ => _kbRegularTextCache[kbLetter]!,
        },
      ),
    );
  }
}

/// Returns the icon widget for the backspace key.
class _backspaceKey extends StatelessWidget {
  const _backspaceKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      child: const Icon(Icons.keyboard_backspace, color: white),
    );
  }
}

/// Returns the icon widget for the enter key, dynamically changing based on game state.
class _enterKey extends StatelessWidget {
  const _enterKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      child: ValueListenableBuilder<bool>(
        valueListenable: ephemeral.illegalFiveLetterWordNotifier,
        builder: (BuildContext context, bool value, Widget? child) {
          return ephemeral.illegalFiveLetterWord
              ? const Icon(Icons.cancel, color: red)
              : ValueListenableBuilder<int>(
                  valueListenable: state.currentRowChangedNotifier,
                  builder: (BuildContext context, int value, Widget? child) {
                    return state.readyForStreakCurrentRow
                        ? const Icon(Icons.fast_forward, color: green)
                        : const Icon(Icons.keyboard_return_sharp, color: white);
                  },
                );
        },
      ),
    );
  }
}

/// Cache for the regular letter key widgets.
final Map<String, Widget> _kbRegularTextCache = <String, Widget>{
  for (String kbLetter in keyboardList)
    (kbLetter): _kbRegularTextConst(kbLetter),
};

/// Creates a stroked text widget for a regular letter key.
class _kbRegularTextConst extends StatelessWidget {
  const _kbRegularTextConst(this.kbLetter);

  final String kbLetter;

  @override
  Widget build(BuildContext context) {
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
}

/// Builds a mini-grid inside a key to show statuses for multiple boards simultaneously.
class _kbMiniGrid extends StatelessWidget {
  const _kbMiniGrid(
    this.kbLetter,
    this.kbRowLength,
    this.keyHeight,
    this.keyWidth,
    this.numBigRows,
  );

  final String kbLetter;
  final int kbRowLength;
  final double keyHeight;
  final double keyWidth;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ephemeral.highlightedBoardNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        final bool someBoardHighlighted = ephemeral.highlightedBoard != -1;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: someBoardHighlighted ? 1 : numBoards,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: someBoardHighlighted ? 1 : numBoards ~/ numBigRows,
            childAspectRatio:
                (someBoardHighlighted
                    ? 1
                    : 1 / ((numBoards / numBigRows) / numBigRows)) /
                (keyHeight / keyWidth) *
                (kMaxKbRowLength / kbRowLength),
          ),
          itemBuilder: (BuildContext context, int subIndex) {
            return _kbMiniSquareColorChooser(
              kbLetter,
              subIndex,
              keyHeight,
              numBigRows,
            );
          },
        );
      },
    );
  }
}

/// Listens to multiple game states to determine the color of a mini-square in a key.
class _kbMiniSquareColorChooser extends StatelessWidget {
  const _kbMiniSquareColorChooser(
    this.kbLetter,
    this.subIndex,
    this.keyHeight,
    this.numBigRows,
  );

  final String kbLetter;
  final int subIndex;
  final double keyHeight;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[
        state.expandingBoardNotifier,
        state.pushUpStepsNotifier,
        state.targetWordsChangedNotifier,
        flips.abCardFlourishFlipAnglesNotifier,
      ]),
      builder: (BuildContext context, _) {
        return _kbMiniSquareColorChooserReal(
          kbLetter,
          subIndex,
          keyHeight,
          numBigRows,
        );
      },
    );
  }
}

/// Retrieves the actual color for a mini-square based on the game logic.
class _kbMiniSquareColorChooserReal extends StatelessWidget {
  const _kbMiniSquareColorChooserReal(
    this.kbLetter,
    this.subIndex,
    this.keyHeight,
    this.numBigRows,
  );

  final String kbLetter;
  final int subIndex;
  final double keyHeight;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    final Color color = cardColors.getBestColorForKeyboardLetter(
      kbLetter,
      subIndex,
    );
    final double radius = 0.1 * keyHeight;
    final int numRows = numBigRows;
    final bool specialHighlighting = ephemeral.highlightedBoard != -1;
    return _kbMiniSquareColorRounded(
      color,
      subIndex,
      numRows,
      radius,
      specialHighlighting,
    ); //_kbMiniSquareColorCache[color][subIndex];
  }
}

/// Draws a color-filled box with specific corner radii for the mini-grid in a keyboard key.
class _kbMiniSquareColorRounded extends StatelessWidget {
  const _kbMiniSquareColorRounded(
    this.color,
    this.subIndex,
    this.numRows,
    this.radius,
    this.specialHighlighting,
  );

  final Color color;
  final int subIndex;
  final int numRows;
  final double radius;
  final bool specialHighlighting;

  @override
  Widget build(BuildContext context) {
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
}
