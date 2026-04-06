// ignore_for_file: camel_case_types

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stroke_text/stroke_text.dart';

import 'card_colors.dart';
import 'constants.dart';
import 'ephemeral.dart';
import 'flips.dart';
import 'sequencer.dart';
import 'state.dart';

/// Coordinate System:
/// AB (Absolute Board): The overall index/row of the game across all historical guesses.
/// GB (Game Board): The localized index/row currently visible on the screen.
/// RGB (Reverse Game Board): Used for the GridView to allow bottom-up stacking.

const double _notionalCardSize = 1.0;
const int _renderTwoFramesTime =
    delayMult *
    33; // so that set state and animations don't happen exactly simultaneously
const double _tau = 2 * pi;

/// Builds the gameboard widget for a specific [boardNumber].
/// Listens to [expandingBoardNotifier] and [pushUpStepsNotifier] to handle layouts.
class gameboardWidget extends StatelessWidget {
  const gameboardWidget(this.boardNumber, this.cardLiveMaxPixel, {super.key});

  final int boardNumber;
  final double cardLiveMaxPixel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: state.expandingBoardNotifier,
      builder: (BuildContext context, bool value, Widget? child) {
        /// If expandingBoard need new grid with each guess so need listener
        /// Else grid is fixed but need each card to have a listener
        return state.expandingBoard
            ? ListenableBuilder(
                listenable: state.pushUpStepsNotifier,
                builder: (BuildContext context, _) {
                  return _gameboardWidgetReal(boardNumber, cardLiveMaxPixel);
                },
              )
            : _gameboardWidgetReal(boardNumber, cardLiveMaxPixel);
      },
    );
  }
}

/// Internal helper to build the actual board container and gesture detector.
class _gameboardWidgetReal extends StatelessWidget {
  const _gameboardWidgetReal(this.boardNumber, this.cardLiveMaxPixel);

  final int boardNumber;
  final double cardLiveMaxPixel;

  @override
  Widget build(BuildContext context) {
    final bool expandingBoard = state.expandingBoard;
    final int boardNumberRows = state.gbLiveNumRowsPerBoard;
    return SizedBox(
      //whether expanding or not, space showing is equal to non-expanding
      height: numRowsPerBoard * cardLiveMaxPixel, //notionalCardSize,
      width: cols * cardLiveMaxPixel, //notionalCardSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(0.2 * cardLiveMaxPixel),
          onTap: () {
            ephemeral.toggleHighlightedBoard(boardNumber);
          },
          child: _gameboardWidgetWithNRows(
            boardNumber,
            boardNumberRows,
            expandingBoard,
          ),
        ),
      ),
    );
  }
}

/// Builds the grid of cards for the gameboard.
class _gameboardWidgetWithNRows extends StatelessWidget {
  const _gameboardWidgetWithNRows(
    this.boardNumber,
    this.boardNumberRows,
    this.expandingBoard,
  );

  final int boardNumber;
  final int boardNumberRows;
  final bool expandingBoard;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      //https://github.com/flutter/flutter/issues/20241
      cacheExtent: 10000,
      //prevents top card reloading (and flipping) on scroll
      reverse: true,
      //makes stick to bottom
      physics: expandingBoard
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      //turns off ios scrolling
      itemCount: boardNumberRows * cols,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
      ),
      itemBuilder: (BuildContext context, int rGbIndex) {
        /// If expandingBoard, each card has fixed meaning given changes in grid size above
        /// Else each card changes meaning based on pushUpSteps
        return state.expandingBoard
            ? _cardFlipperAlts(_getABIndexFromRGBIndex(rGbIndex), boardNumber)
            : ValueListenableBuilder<int>(
                valueListenable: state.pushUpStepsNotifier,
                builder: (BuildContext context, int value, Widget? child) {
                  return _cardFlipperAlts(
                    _getABIndexFromRGBIndex(rGbIndex),
                    boardNumber,
                  );
                },
              );
      },
    );
  }
}

//move listener outside of class so made once across all cards and not rebuilt
final List<Listenable> _gbCachedListener1 = List<Listenable>.generate(
  numBoards,
  (int boardNumber) => Listenable.merge(<Listenable?>[
    flips.boardFlourishFlipRowsNotifiers[boardNumber],
    flips.abCardFlourishFlipStateNotifier,
  ]),
);

/// Orchestrates listeners for individual cards to trigger animations efficiently.
class _cardFlipperAlts extends StatelessWidget {
  const _cardFlipperAlts(this.abIndex, this.boardNumber);

  final int abIndex;
  final int boardNumber;

  @override
  Widget build(BuildContext context) {
    final int abRow = abIndex ~/ cols;
    return ValueListenableBuilder<int>(
      valueListenable: state.currentRowChangedNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return abRow > state.abCurrentRowInt
            //later rows normally just cards
            //earlier rows subject to flourish flips
            ? _cardFlipper(abIndex, boardNumber)
            : ListenableBuilder(
                listenable: _gbCachedListener1[boardNumber],
                builder: (BuildContext context, _) {
                  return _cardFlipper(abIndex, boardNumber);
                },
              );
      },
    );
  }
}

/// Handles the 3D flip animation of a card.
class _cardFlipper extends StatelessWidget {
  const _cardFlipper(this.abIndex, this.boardNumber);
  final int abIndex;
  final int boardNumber;
  @override
  Widget build(BuildContext context) {
    final Widget childFront = _cardBuilder(abIndex, boardNumber, true);
    final Widget childBack = _cardBuilder(abIndex, boardNumber, false);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: flips.getFlipAngle(abIndex, boardNumber),
      ),
      duration: const Duration(milliseconds: flipTime),
      builder: (BuildContext context, double angle, Widget? child) {
        final bool isFront = angle > 0.25;
        return (Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateX(angle * _tau + (isFront ? _tau / 2 : 0)),
          child: isFront ? childFront : childBack,
        ));
      },
    );
  }
}

/// Builds the visual card widget with a slide animation listener.
class _cardBuilder extends StatelessWidget {
  const _cardBuilder(this.abIndex, this.boardNumber, this.facingFront);

  final int abIndex;
  final int boardNumber;
  final bool facingFront;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sequencer.temporaryVisualOffsetForSlideNotifier,
      builder: (BuildContext context, int value, Widget? child) {
        return _positionedScaledCard(abIndex, boardNumber, facingFront);
      },
    );
  }
}

/// Positioned and scales the card, handling the sliding animation for board shifts.
class _positionedScaledCard extends StatelessWidget {
  const _positionedScaledCard(this.abIndex, this.boardNumber, this.facingFront);

  final int abIndex;
  final int boardNumber;
  final bool facingFront;

  @override
  Widget build(BuildContext context) {
    const double shrinkCardScaleDefault = 0.75;
    final int temporaryVisualOffsetForSlide =
        sequencer.temporaryVisualOffsetForSlide;
    final int abRow = abIndex ~/ cols;
    final int gbRow = _getGBRowFromABRow(abRow);
    final bool shouldSlideCard = abRow < state.abCurrentRowInt;
    final bool shouldShrinkCard =
        state.expandingBoard &&
        abRow - (shouldSlideCard ? temporaryVisualOffsetForSlide : 0) <
            state.abLiveNumRowsPerBoard - numRowsPerBoard;

    final double cardScaleFactor = shouldShrinkCard
        ? shrinkCardScaleDefault
        : 1.0;
    final double cardSlideOffsetFactor = shouldSlideCard
        ? -temporaryVisualOffsetForSlide.toDouble()
        : 0;

    // if offset 1, do gradually. if offset 0, do instantaneously
    // so slide visual cards into new position slowly
    // then do a real switch to what is in each card to move one place forward
    // and move visual cards back to original position instantly
    final int timeFactorOfSlide = temporaryVisualOffsetForSlide;
    final Widget chosenCard = _cardChooser(abIndex, boardNumber, facingFront);
    final Duration animationDuration = Duration(
      milliseconds: timeFactorOfSlide * (slideTime - _renderTwoFramesTime),
    );
    // move slightly quicker so have two frames to re-render final position
    final AnimatedSlide animatedCard = AnimatedSlide(
      offset: Offset(0, cardSlideOffsetFactor),
      duration: animationDuration,
      child: AnimatedScale(
        scale: cardScaleFactor,
        duration: animationDuration,
        child: chosenCard,
      ),
    );
    return ClipRect(
      clipBehavior: (gbRow == 0 && cardSlideOffsetFactor != 0)
          ? Clip.hardEdge
          : Clip.none,
      child: animatedCard,
    );
  }
}

//move listener outside of class so made once across all cards and not rebuilt
final Listenable _gbCachedListener2 = Listenable.merge(<Listenable?>[
  //state.targetWordsChangedNotifier,
  ephemeral.highlightedBoardNotifier,
  state.currentRowChangedNotifier,
]);

/// Listens to game state to decide which letter and color to show on a card.
class _cardChooser extends StatelessWidget {
  const _cardChooser(this.abIndex, this.boardNumber, this.facingFront);

  final int abIndex;
  final int boardNumber;
  final bool facingFront;

  @override
  Widget build(BuildContext context) {
    final int abRow = abIndex ~/ cols;

    return ListenableBuilder(
      listenable: _gbCachedListener2,
      builder: (BuildContext context, _) {
        return abRow == state.abCurrentRowInt
            ? ValueListenableBuilder<String>(
                valueListenable:
                    ephemeral.currentTypingNotifiers[abIndex % cols],
                builder: (BuildContext context, String value, Widget? child) {
                  return _cardChooserRealReal(
                    abIndex,
                    boardNumber,
                    facingFront,
                  );
                },
              )
            : _cardChooserRealReal(abIndex, boardNumber, facingFront);
      },
    );
  }
}

/// Determines visibility, letter, and colors for a card based on logic and historical state.
class _cardChooserRealReal extends StatelessWidget {
  const _cardChooserRealReal(this.abIndex, this.boardNumber, this.facingFront);

  final int abIndex;
  final int boardNumber;
  final bool facingFront;

  @override
  Widget build(BuildContext context) {
    final int abRow = abIndex ~/ cols;
    final int col = abIndex % cols;
    final bool historicalWin =
        state.getTestHistoricalAbWin(abRow, boardNumber) ||
        flips.getBoardFlourishFlipRow(boardNumber) != -1 &&
            abRow == flips.getBoardFlourishFlipRow(boardNumber);
    final bool justFlippedBackToFront =
        flips.getBoardFlourishFlipRow(boardNumber) != -1;
    final bool hideCard =
        (!infMode && state.getDetectBoardSolvedByABRow(boardNumber, abRow)) ||
        abRow < state.getFirstAbRowToShowOnBoardDueToKnowledge(boardNumber) ||
        (_rowOffTopOfMainBoard(abRow) &&
            !facingFront &&
            justFlippedBackToFront); //abRow < game.getAbCurrentRowInt() - 1

    final String cardLetter =
        abRow ==
                state.abLiveNumRowsPerBoard -
                    1 && //code is formatting final row of cards
            _getGBRowFromABRow(state.abCurrentRowInt) < 0 &&
            ephemeral.currentTypingString.length > col
        //If need to type while off top of board (unlikely), show on final row
        ? ephemeral.currentTypingString[col]
        : hideCard
        ? ""
        : _getCardLetter(abIndex);
    final bool normalHighlighting = ephemeral.isBoardNormalHighlighted(
      boardNumber,
    );
    final Color cardColor = hideCard
        ? transp
        : !facingFront
        ? grey
        : _soften(boardNumber, cardColors.getAbCardColor(abIndex, boardNumber));
    final Color borderColor = hideCard
        ? transp
        : historicalWin
        ? _soften(boardNumber, green)
        : transp;
    return _cardConst(normalHighlighting, cardLetter, cardColor, borderColor);
  }
}

/// Basic card building block with border and background color.
class _cardConst extends StatelessWidget {
  const _cardConst(
    this.normalHighlighting,
    this.cardLetter,
    this.cardColor,
    this.borderColor,
  );

  final bool normalHighlighting;
  final String cardLetter;
  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    const double cardBorderRadiusFactor = 0.2;
    const double cardSizeFixed = _notionalCardSize;
    return FittedBox(
      fit: BoxFit.contain,
      child: Padding(
        padding: const EdgeInsets.all(0.005 * cardSizeFixed),
        child: Container(
          height: cardSizeFixed,
          width: cardSizeFixed,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.05 * cardSizeFixed),
            borderRadius: BorderRadius.circular(
              cardBorderRadiusFactor * cardSizeFixed,
            ),
            color: cardColor,
          ),
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: _cardTextConst(normalHighlighting, cardLetter),
          ),
        ),
      ),
    );
  }
}

/// Creates the text widget for a card's letter.
class _cardTextConst extends StatelessWidget {
  const _cardTextConst(this.normalHighlighting, this.cardLetter);

  final bool normalHighlighting;
  final String cardLetter;

  @override
  Widget build(BuildContext context) {
    return StrokeText(
      text: cardLetter.toUpperCase(),
      strokeWidth: 0.5, //previously 0.5 * cardSize / screen.cardLiveMaxPixel,
      strokeColor: normalHighlighting ? bg : transp,
      textStyle: TextStyle(
        height: 1.15,
        leadingDistribution: TextLeadingDistribution.even,
        color: normalHighlighting ? white : _offWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

String _getCardLetter(int abIndex) {
  final int abRow = abIndex ~/ cols;
  final int col = abIndex % cols;
  if (abRow > state.abCurrentRowInt) {
    return "";
  } else if (abRow == state.abCurrentRowInt) {
    return ephemeral.getCurrentTypingAtCol(col);
  } else {
    return state.getCardLetterAtAbIndex(abIndex);
  }
}

/// Softens colors for non-highlighted boards.
Color _soften(int boardNumber, Color color) {
  if (ephemeral.isBoardNormalHighlighted(boardNumber) ||
      !_softColorMap.containsKey(color)) {
    return color;
  } else {
    return _softColorMap[color]!;
  }
}

final Map<Color, Color> _softColorMap = <Color, Color>{
  green: _softGreen,
  amber: _softAmber,
  red: _softRed,
  white: _offWhite,
  //grey: grey
  bg: transp,
};

const Color _softGreen = Color(0xff61B063);
const Color _softAmber = Color(0xffFFCF40);
const Color _softRed = Color(0xffF55549);
const Color _offWhite = Color(0xff939393);

// ignore: unused_element
int _getABRowFromGBRow(int gbRow) {
  return gbRow + state.pushOffBoardRows;
}

/// Converts a board-relative row index to an absolute row index.
int _getGBRowFromABRow(int abRow) {
  return abRow - state.pushOffBoardRows;
}

// ignore: unused_element
int _getABIndexFromGBIndex(int gbIndex) {
  return gbIndex + cols * state.pushOffBoardRows;
}

// ignore: unused_element
int _getGBIndexFromABIndex(int abIndex) {
  return abIndex - cols * state.pushOffBoardRows;
}

/// Converts a grid index to an absolute board index.
int _getABIndexFromRGBIndex(int rGbIndex) {
  return (state.abLiveNumRowsPerBoard - rGbIndex ~/ cols - 1) * cols +
      rGbIndex % cols;
}

/// Checks if a row is scrolled off the top of the main visible board.
bool _rowOffTopOfMainBoard(int abRow) {
  return abRow < state.abLiveNumRowsPerBoard - numRowsPerBoard;
}
