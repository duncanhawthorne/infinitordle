import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/helper.dart';
import 'dart:math';
import 'package:infinitordle/constants.dart';

FocusNode focusNode = FocusNode();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        fontFamily:
            '-apple-system', //https://github.com/flutter/flutter/issues/93140
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: bg,
        ),
      ),
      home: const Infinitordle(),
    );
  }
}

class Infinitordle extends StatefulWidget {
  const Infinitordle({super.key});

  @override
  State<Infinitordle> createState() => _InfinitordleState();
}

class _InfinitordleState extends State<Infinitordle> {
  @override
  initState() {
    super.initState();
    resetColorsCache();
    loadKeys();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(
          () {}); //Hack, but makes sure state set right shortly after starting
    });
  }

  void flipCard(index, toFOrB) {
    flipCardReal(index, toFOrB);
    setState(() {});
  }

  void delayedFlipOnAbsoluteCard(int currentWord, int i, toFOrB) {
    Future.delayed(Duration(milliseconds: delayMult * i * (durMult == 1 ? 100 : 250)), () {
      //flip to reveal the colors with pleasing animation
      flipCardReal((currentWord - 1) * 5 + i, toFOrB);
      setState(() {});
    });
  }

  void onKeyboardTapped(int index) {
    cheatPrintTargetWords();

    if (keyboardList[index] == " ") {
      //ignore pressing of non-keys

    } else if (keyboardList[index] == "<") {
      //backspace
      if (typeCountInWord > 0) {
        typeCountInWord--;
        gameboardEntries[currentWord * 5 + typeCountInWord] = "";
        setState(() {});
      }
    } else if (keyboardList[index] == ">") {
      //submit guess
      if (typeCountInWord == 5) {
        //&& threadsafeBlockNewWord == false
        //ignore if not completed whole word
        String enteredWordLocal = gameboardEntries
            .sublist(currentWord * 5, (currentWord + 1) * 5)
            .join(""); //local variable to ensure threadsafe
        if (legalWords.contains(enteredWordLocal)) {
          //Legal word, but not necessarily correct word

          //Legal word so step forward
          resetColorsCache();
          currentWord++;
          int currentWordLocal = currentWord;
          typeCountInWord = 0;

          if (onStreakForKeyboardIndicatorCache) {
            //purely for the visual indicator on the return key. Test this every legal word, rather than every correct word
            onStreakForKeyboardIndicatorCache = streak();
          }

          saveKeys();

          //Made a guess flip over the cards to see the colors
          for (int i = 0; i < 5; i++) {
            delayedFlipOnAbsoluteCard(currentWordLocal.toInt(), i, "f");
          }

          //Test if it is correct word
          bool oneMatchingWordLocal = false;
          oneMatchingWordForResetScreenCache = false;
          int oneMatchingWordBoardLocal =
              -1; //local variable to ensure threadsafe
          for (var board = 0; board < numBoards; board++) {
            if (detectBoardSolvedByRow(board, currentWord)) {
              //threadsafeBlockNewWord = true;
              oneMatchingWordLocal = true;
              oneMatchingWordForResetScreenCache = true;
              oneMatchingWordBoardLocal = board;
            }
          }

          //Code for losing game
          if (!oneMatchingWordLocal && currentWord >= numRowsPerBoard) {
            //didn't get it in time
            showResetConfirmScreen();
          }

          if (!infMode && oneMatchingWordLocal) {
            //Code for totally winning game across all boards
            bool totallySolvedLocal = true;
            for (var i = 0; i < numBoards; i++) {
              if (!detectBoardSolvedByRow(i, currentWord)) {
                totallySolvedLocal = false;
              }
            }
            if (totallySolvedLocal) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(appTitle)));
            }
          }

          if (infMode && oneMatchingWordLocal) {
            Future.delayed(Duration(milliseconds: delayMult * 1500), () {
              //Give time for above code to show visually, so we have flipped
              //Erase a row and step back
              oneStepBack(currentWordLocal);
              setState(() {});

              Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                //include inside other future so definitely happens after rather relying on race
                //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                //Log the word just got in success words, which gets green to shown
                logWinAndGetNewWord(
                    enteredWordLocal, oneMatchingWordBoardLocal);
                setState(() {});

                if (streak()) {
                  Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                    if (currentWord > 0) {
                      oneStepBack(currentWordLocal);
                      setState(() {});
                    }
                  });
                }
              });
            });
          }
        } else {
          //not a legal word so just clear current word
          for (var i = 0; i < 5; i++) {
            gameboardEntries[currentWord * 5 + i] = "";
          }
          typeCountInWord = 0;
          setState(() {});
        }
      }
    } else if (true) {
      //pressing regular key, as other options already dealt with above
      if (typeCountInWord < 5 && currentWord < numRowsPerBoard) {
        //still typing out word, else ignore
        gameboardEntries[currentWord * 5 + typeCountInWord] =
            keyboardList[index];
        typeCountInWord++;

        //doing this once rather than live inside the widget for speed
        oneLegalWordForRedCardsCache = false;
        if (typeCountInWord == 5) {
          //ignore if not completed whole word
          if (legalWords.contains(gameboardEntries
              .sublist(currentWord * 5, (currentWord + 1) * 5)
              .join(""))) {
            oneLegalWordForRedCardsCache = true;
          }
        }
        setState(() {});
      }
    }
//    });
  }

  void resetBoard() {
    resetBoardReal();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    detectAndUpdateForScreenSize(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: appBarHeight,
        title: _titleWidget(),
      ),
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (keyEvent) {
          if (keyEvent is KeyDownEvent) {
            //if (keyEvent.runtimeType.toString() == 'KeyDownEvent') {
            if (keyboardList.contains(keyEvent.character)) {
              onKeyboardTapped(keyboardList.indexOf(keyEvent.character ?? " "));
            }
            if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
              onKeyboardTapped(29);
            }
            if (keyEvent.logicalKey == LogicalKeyboardKey.backspace &&
                backspaceSafe) {
              if (backspaceSafe) {
                // (DateTime.now().millisecondsSinceEpoch > lastTimePressedDelete + 200) {
                //workaround to bug which was firing delete key twice
                backspaceSafe = false;
                onKeyboardTapped(20);
                //lastTimePressedDelete = DateTime.now().millisecondsSinceEpoch;
              }
            }
          } else if (keyEvent is KeyUpEvent) {
            if (keyEvent.logicalKey == LogicalKeyboardKey.backspace) {
              backspaceSafe = true;
            }
          }
        },
        child: Container(
          color: bg,
          child: Column(
            children: [
              Wrap(
                spacing: boardSpacer,
                runSpacing: boardSpacer,
                children: [
                  //split into 2 so that don't get a wrap on 3 + 1 basis. Note that this is why 2 is hardcoded below
                  Wrap(
                    spacing: boardSpacer,
                    runSpacing: boardSpacer,
                    children: List.generate(
                        numBoards ~/ 2, (index) => _gameboardWidget(index)),
                  ),
                  Wrap(
                    spacing: boardSpacer,
                    runSpacing: boardSpacer,
                    children: List.generate(numBoards ~/ 2,
                        (index) => _gameboardWidget(numBoards ~/ 2 + index)),
                  ),
                ],
              ),
              const Divider(
                color: Colors.transparent,
                height: dividerHeight,
              ),
              _keyboardWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleWidget() {
    var infText = infSuccessWords.isEmpty ? "o" : "∞" * (infSuccessWords.length ~/ 2) + "o" * (infSuccessWords.length % 2);
    return GestureDetector(
        onTap: () {
          showResetConfirmScreen();
        },
        child: FittedBox(
          //fit: BoxFit.fitHeight,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
              children: <TextSpan>[
                TextSpan(text: appTitle1),
                TextSpan(
                    text: infText,
                    style: TextStyle(
                        color: infSuccessWords.isEmpty ? Colors.white : Colors.green)),
                TextSpan(text: appTitle3),
              ],
            ),
          ),
        ));
  }

  Widget _gameboardWidget(boardNumber) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: 5 * cardEffectiveMaxPixel, //*0.97
          maxHeight: numRowsPerBoard * cardEffectiveMaxPixel), //*0.97
      child: GridView.builder(
          physics:
              const NeverScrollableScrollPhysics(), //turns off ios scrolling
          itemCount: numRowsPerBoard * 5,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _cardFlipper(index, boardNumber);
          }),
    );
  }

  Widget _cardFlipper(index, boardNumber) {
    return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: angles[index]),
        duration: Duration(milliseconds: durMult * 500),
        builder: (BuildContext context, double val, __) {
          return (Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateX(val * (2 * pi)),
            child: val <= 0.25
                ? _card(index, boardNumber, val, "b")
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateX(pi),
                    child: _card(index, boardNumber, val, "f"),
                  ),
          ));
        });
  }

  Widget _card(index, boardNumber, val, bf) {
    int rowOfIndex = index ~/ 5;
    var wordForRowOfIndex = gameboardEntries
        .sublist((5 * rowOfIndex).toInt(), (5 * (rowOfIndex + 1)).toInt())
        .join("");
    bool legalOrShort = typeCountInWord != 5 || oneLegalWordForRedCardsCache;

    bool infPreviousWin5 = false;
    if (infSuccessWords.contains(wordForRowOfIndex)) {
      if (infSuccessBoardsMatchingWords[
              infSuccessWords.indexOf(wordForRowOfIndex)] ==
          boardNumber) {
        infPreviousWin5 = true;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10 *
          keyboardSingleKeyEffectiveMaxPixelHeight /
          keyboardSingleKeyUnconstrainedMaxPixelHeight),
      child: Container(
        padding: const EdgeInsets.all(0.5),
        height: 500, //oversize so it renders in full and so doesn't pixelate
        width: 500, //oversize so it renders in full and so doesn't pixelate
        decoration: BoxDecoration(
            border: Border.all(
                color: bf == "b"
                    ? Colors.transparent //bg
                    : infPreviousWin5
                        ? Colors.green
                        : Colors.transparent, //bg
                width: bf == "b"
                    ? 0
                    : infPreviousWin5
                        ? 2
                        : 0),
            borderRadius: BorderRadius.circular(10 *
                keyboardSingleKeyEffectiveMaxPixelHeight /
                keyboardSingleKeyUnconstrainedMaxPixelHeight), //needed for green border
            color: !infMode && detectBoardSolvedByRow(boardNumber, rowOfIndex)
                ? Colors.transparent // bg //"hide" after solved board
                : bf == "b"
                    ? rowOfIndex == currentWord && !legalOrShort
                        ? Colors.red
                        : grey
                    : getCardColor(index, boardNumber)),
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: _cardText(index, boardNumber),
        ),
      ),
    );
  }

  Widget _cardText(index, boardNumber) {
    int rowOfIndex = index ~/ 5;
    return Text(
      gameboardEntries[index].toUpperCase(),
      style: TextStyle(
        /*
        shadows: const <Shadow>[
          Shadow(
            offset: Offset(0, 0),
            blurRadius: 1.0,
            color: bg,
          ),
        ],
         */
        fontSize: 30,
        color: !infMode && detectBoardSolvedByRow(boardNumber, rowOfIndex)
            ? Colors.transparent // bg //"hide" after being solved
            : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _keyboardWidget() {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(
            maxWidth:
                keyboardSingleKeyEffectiveMaxPixelHeight * 10 / keyAspectRatio,
            maxHeight: keyboardSingleKeyEffectiveMaxPixelHeight * 3),
        child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), //ios fix
            itemCount: 30,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              childAspectRatio: 1 / keyAspectRatio,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _kbStackWithMiniGrid(index);
            }),
      ),
    );
  }

  Widget _kbStackWithMiniGrid(index) {
    return Container(
      padding: const EdgeInsets.all(0.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        //borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Center(
              //child: Container(
              //decoration: BoxDecoration(
              //  //border: Border.all(color: bg, width: 1),
              //),
              //child:

              //ClipRRect(
              //  borderRadius: BorderRadius.circular(10),
              child: ["<", ">", " "].contains(keyboardList[index])
                  ? const SizedBox.shrink()
                  : _kbMiniGridContainer(index),
              //),
              //        )
            ),
            Center(
                child: keyboardList[index] == " "
                    ? const SizedBox.shrink()
                    // ignore: dead_code
                    : false && noAnimations
                        // ignore: dead_code
                        ? GestureDetector(
                            onTap: () {
                              onKeyboardTapped(index);
                            },
                            child: _kbTextSquare(index),
                          )
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onKeyboardTapped(index);
                              },
                              child: Container(child: _kbTextSquare(index)),
                            ),
                          )),
          ],
        ),
      ),
    );
  }

  Widget _kbTextSquare(index) {
    return SizedBox(
        height: keyboardSingleKeyEffectiveMaxPixelHeight, //500,
        width: keyboardSingleKeyEffectiveMaxPixelHeight / keyAspectRatio, //500,
        child: FittedBox(
            fit: BoxFit.fitHeight,
            child: keyboardList[index] == "<"
                ? Container(
                    padding: const EdgeInsets.all(7),
                    child: const Icon(Icons.keyboard_backspace,
                        color: Colors.white))
                : keyboardList[index] == ">"
                    ? Container(
                        padding: const EdgeInsets.all(7),
                        child: Icon(Icons.keyboard_return_sharp,
                            color: onStreakForKeyboardIndicatorCache
                                ? Colors.green
                                : Colors.white))
                    : Text(
                        keyboardList[index].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            shadows: <Shadow>[
                              Shadow(
                                offset: Offset(0, 0),
                                blurRadius: 1.0,
                                color: bg,
                              ),
                            ]),
                      )));
  }

  Widget _kbMiniGridContainer(index) {
    return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: numBoards,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: numBoards ~/ numPresentationBigRowsOfBoards,
          childAspectRatio: 1 /
              ((numBoards / numPresentationBigRowsOfBoards) /
                  numPresentationBigRowsOfBoards) /
              keyAspectRatio,
        ),
        itemBuilder: (BuildContext context, int subIndex) {
          return _kbMiniSquareColor(index, subIndex);
        });
  }

  Widget _kbMiniSquareColor(index, subIndex) {
    //return AnimatedContainer(
    //  duration: const Duration(milliseconds: 500),
    //  curve: Curves.fastOutSlowIn,
    return Container(
      height: 1000,
      decoration: BoxDecoration(
        color: getBestColorForLetter(index, subIndex),
      ),
    );
  }

  Future<void> showResetConfirmScreen() async {
    bool end = false;
    if (!oneMatchingWordForResetScreenCache && currentWord >= numRowsPerBoard) {
      end = true;
    }
    //var _helperText =  "Solve 4 boards at once. \n\nWhen you solve a board, the target word will be changed, and you get an extra guess.\n\nCan you keep going forever and reach infinitordle?\n\n";
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appTitle),
          // ignore: prefer_interpolation_to_compose_strings
          content: Text(
              // ignore: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings
              end
                  ?
                  // ignore: prefer_interpolation_to_compose_strings
                  "You got " +
                      infSuccessWords.length.toString() +
                      " word" +
                      (infSuccessWords.length == 1 ? "" : "s") +
                      ": " +
                      infSuccessWords.join(", ") +
                      "\n\nYou missed: " +
                      targetWords.join(", ") +
                      "\n\nReset the board?"
                  // ignore: prefer_interpolation_to_compose_strings
                  : "You've got " +
                      infSuccessWords.length.toString() +
                      " word" +
                      (infSuccessWords.length == 1 ? "" : "s") +
                      ' so far' +
                      (infSuccessWords.isNotEmpty ? ":" : "") +
                      ' ' +
                      infSuccessWords.join(", ") +
                      "\n\n"
                          'Lose your progress and reset the board?'),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  {focusNode.requestFocus(), Navigator.pop(context, 'Cancel')},
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => {
                resetBoard(),
                focusNode.requestFocus(),
                Navigator.pop(context, 'OK')
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
