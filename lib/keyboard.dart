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
    this.keyHeight,
    this.numBigRows, {
    super.key,
  });

  final int keyBoardStartKeyIndex;
  final int kbRowLength;
  final double keyHeight;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(kbRowLength, (int offsetIndex) {
        final String kbLetter =
            keyboardList[keyBoardStartKeyIndex + offsetIndex];
        return _kbKeyStack(kbLetter, kbRowLength, keyHeight, numBigRows);
      }),
    );
  }
}

/// Builds an individual key on the keyboard, including its background colors and text/icon.
class _kbKeyStack extends StatelessWidget {
  const _kbKeyStack(
    this.kbLetter,
    this.kbRowLength,
    this.keyHeight,
    this.numBigRows,
  );

  final String kbLetter;
  final int kbRowLength;
  final double keyHeight;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(0.005 * keyHeight),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            <String>[kBackspace, kEnter].contains(kbLetter)
                ? const SizedBox.shrink()
                : _kbMiniGrid(kbLetter, kbRowLength, keyHeight, numBigRows),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(0.1 * keyHeight),
                onTap: () {
                  sequencer.onKeyboardTapped(kbLetter);
                },
                child: _kbTextSquare(kbLetter, kbRowLength, keyHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the visual representation of the key's label or icon.
class _kbTextSquare extends StatelessWidget {
  const _kbTextSquare(this.kbLetter, this.kbRowLength, this.keyHeight);

  final String kbLetter;
  final int kbRowLength;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
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
    return const Padding(
      padding: EdgeInsets.all(7),
      child: Icon(Icons.keyboard_backspace, color: white),
    );
  }
}

/// Returns the icon widget for the enter key, dynamically changing based on game state.
class _enterKey extends StatelessWidget {
  const _enterKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable?>[
          ephemeral.illegalFiveLetterWordNotifier,
          state.currentRowChangedNotifier,
        ]),
        builder: (BuildContext context, _) {
          if (ephemeral.illegalFiveLetterWord) {
            return const Icon(Icons.cancel, color: red);
          }
          if (state.readyForStreakCurrentRow) {
            return const Icon(Icons.fast_forward, color: green);
          }
          return const Icon(Icons.keyboard_return_sharp, color: white);
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
    this.numBigRows,
  );

  final String kbLetter;
  final int kbRowLength;
  final double keyHeight;
  final int numBigRows;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ephemeral.highlightedBoardNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        final bool someBoardHighlighted = ephemeral.highlightedBoard != -1;
        if (someBoardHighlighted) {
          //1x1
          return _kbMiniSquareColorChooser(kbLetter, 0, keyHeight, numBigRows);
        }
        //2x2
        final int numCols = numBoards ~/ numBigRows;
        return Column(
          children: List<Widget>.generate(numBigRows, (int rowIndex) {
            return Expanded(
              child: Row(
                children: List<Widget>.generate(numCols, (int colIndex) {
                  final int subIndex = (rowIndex * numCols) + colIndex;
                  return Expanded(
                    child: _kbMiniSquareColorChooser(
                      kbLetter,
                      subIndex,
                      keyHeight,
                      numBigRows,
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

final Listenable _cachedListenerA = Listenable.merge(<Listenable?>[
  state.expandingBoardNotifier,
  state.pushUpStepsNotifier,
  state.targetWordsChangedNotifier,
  flips.abCardFlourishFlipStateNotifier,
]);

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
      listenable: _cachedListenerA,
      builder: (BuildContext context, _) {
        final Color color = cardColors.getBestColorForKeyboardLetter(
          kbLetter,
          subIndex,
        );
        final double radius = 0.1 * keyHeight;
        final int numRows = numBigRows;
        final bool specialHighlighting = ephemeral.highlightedBoard != -1;
        return _kbMiniSquareColorConst(
          color,
          subIndex,
          numRows,
          radius,
          specialHighlighting,
        );
      },
    );
  }
}

/// Draws a color-filled box with specific corner radii for the mini-grid in a keyboard key.
class _kbMiniSquareColorConst extends StatelessWidget {
  const _kbMiniSquareColorConst(
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
