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
      setState(() {}); //Hack, but makes sure state set right shortly after starting
    });
  }

  void flipCard(index, toFOrB) {
    flipReal(index, toFOrB);
    setState(() {});
  }

  void delayedFlipOnAbsoluteCard(int currentWord, int i, toFOrB) {
    Future.delayed(Duration(milliseconds: durMult * 100 * i), () {
      //flip to reveal the colors with pleasing animation
      setState(() {
        flipReal((currentWord - 1) * 5 + i, toFOrB);
      });
    });
  }

  void onKeyboardTapped(int index) {
    //   setState(() {
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
      if (typeCountInWord == 5 && threadsafeBlockNewWord == false) {
        //ignore if not completed whole word
        String enteredWord = gameboardEntries
            .sublist(currentWord * 5, (currentWord + 1) * 5)
            .join("");
        if (legalWords.contains(enteredWord)) {
          //Legal word, but not necessarily correct word

          //Legal word so step forward
          resetColorsCache();
          currentWord++;
          typeCountInWord = 0;

          //Made a guess flip over the cards to see the colors
          for (int i = 0; i < 5; i++) {
            delayedFlipOnAbsoluteCard(currentWord.toInt(), i, "f");
          }

          //Test if it is correct word
          oneMatchingWord = false;
          int oneMatchingWordBoard = -1;
          //if (infMode) {
          //Code for single win in infMode
          for (var board = 0; board < numBoards; board++) {
            if (detectBoardSolvedByRow(board, currentWord)) {
              threadsafeBlockNewWord = true;
              oneMatchingWord = true;
              oneMatchingWordBoard = board;
            }
          }
          // }

          //Code for losing game
          if (!oneMatchingWord && currentWord >= numRowsPerBoard) {
            //didn't get it in time
            showResetConfirmScreen();
          }

          if (!infMode && oneMatchingWord) {
            //Code for totally winning game across all boards
            bool totallySolved = true;
            for (var i = 0; i < numBoards; i++) {
              if (!detectBoardSolvedByRow(i, currentWord)) {
                totallySolved = false;
              }
            }
            if (totallySolved) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(appTitle)));
            }
            threadsafeBlockNewWord = false;
          }

          if (infMode && oneMatchingWord) {
            Future.delayed(Duration(milliseconds: durMult * 1500), () {
              //Give time for above code to show visually, so we have flipped
              setState(() {
                //Erase a row and step back
                for (var j = 0; j < infNumBacksteps; j++) {
                  for (var i = 0; i < 5; i++) {
                    gameboardEntries.removeAt(0);
                    gameboardEntries.add("");
                  }
                  /*
                    var tmpGameboardEntries =
                        _gameboardEntries.sublist(5, _gameboardEntries.length);
                    for (var i = 0; i < 5; i++) {
                      tmpGameboardEntries.add("");
                    }
                    _gameboardEntries = tmpGameboardEntries;
                     */
                  currentWord--;
                  //Reverse flip the card on the next row back to backside (after earlier having flipped them the right way)
                  for (var j = 0; j < 5; j++) {
                    flipCard(currentWord * 5 + j, "b");
                  }
                }
                resetColorsCache();

                Future.delayed(Duration(milliseconds: durMult * 1000), () {
                  //include inside other future so definitely happens after rather relying on race
                  //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                  setState(() {
                    //Log the word just got in success words, which gets green to shown
                    infSuccessWords.add(enteredWord);
                    infSuccessBoardsMatchingWords.add(oneMatchingWordBoard);
                    //Create new target word for the board
                    targetWords[oneMatchingWordBoard] = getTargetWord();

                    resetColorsCache();
                    threadsafeBlockNewWord = false;
                  });
                  saveKeys();
                });
              });
              saveKeys();
            });
          }
          setState(() {});
          resetColorsCache();
        } else {
          //not a legal word so just clear current word
          gameboardEntries[currentWord * 5 + 0] = "";
          gameboardEntries[currentWord * 5 + 1] = "";
          gameboardEntries[currentWord * 5 + 2] = "";
          gameboardEntries[currentWord * 5 + 3] = "";
          gameboardEntries[currentWord * 5 + 4] = "";
          typeCountInWord = 0;
          setState(() {});
        }
      }
    } else if (true) {
      //pressing regular key, as other options already dealt with above
      if (typeCountInWord < 5) {
        //still typing out word, else ignore
        gameboardEntries[currentWord * 5 + typeCountInWord] =
            keyboardList[index];
        typeCountInWord++;

        //doing this once rather than live inside the widget for speed
        oneLegalWord = false;
        if (typeCountInWord == 5) {
          //ignore if not completed whole word
          if (legalWords.contains(gameboardEntries
              .sublist(currentWord * 5, (currentWord + 1) * 5)
              .join(""))) {
            oneLegalWord = true;
          }
        }
        setState(() {});
      }
    }
//    });
    saveKeys();
  }

  void resetBoard() {
    //   setState(() {
    //initialise on reset
    typeCountInWord = 0;
    currentWord = 0;
    gameboardEntries = List<String>.generate((numRowsPerBoard * 5), (i) => "");
    targetWords = getTargetWords(numBoards);
    infSuccessWords.clear();
    infSuccessBoardsMatchingWords.clear();

    for (var j = 0; j < numRowsPerBoard * 5; j++) {
        //angles = List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);
        flipCard(j, "b");
    }


    //speed initialise entries using cheat mode for debugging
    if (cheatMode) {
      for (var j = 0; j < numBoards; j++) {
        if (cheatWords.length > j) {
          targetWords[j] = cheatWords[j];
        } else {
          targetWords[j] = getTargetWord();
        }
      }

      for (var j = 0; j < cheatString.length; j++) {
        gameboardEntries[j] = cheatString[j];
      }

      currentWord = cheatString.length ~/ 5;
      for (var j = 0; j < gameboardEntries.length; j++) {
        if (gameboardEntries[j] != "") {
          flipCard(j, "f");
        }
      }
    }
    resetColorsCache();
//    });
    setState(() {});
    saveKeys();
  }

  @override
  Widget build(BuildContext context) {
    detetctAndUpdateForScreenSize(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _titleWidget(),
      ),
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (keyDownEvent) {
          if (keyboardList.contains(keyDownEvent.character)) {
            onKeyboardTapped(
                keyboardList.indexOf(keyDownEvent.character ?? " "));
          }
          if (keyDownEvent.logicalKey == LogicalKeyboardKey.enter) {
            onKeyboardTapped(29);
          }
          if (keyDownEvent.logicalKey == LogicalKeyboardKey.backspace) {
            if (DateTime.now().millisecondsSinceEpoch >
                lastTimePressedDelete + 100) {
              //workaround to bug which was firing delete key twice
              onKeyboardTapped(20);
              lastTimePressedDelete = DateTime.now().millisecondsSinceEpoch;
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
                height: 2,
              ),
              _keyboardWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleWidget() {
    var infText = infSuccessWords.isEmpty ? "o" : "∞" * infSuccessWords.length;
    return GestureDetector(
        onTap: () {
          showResetConfirmScreen();
        },
        child: FittedBox(
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
                        color: infText == "o" ? Colors.white : Colors.green)),
                TextSpan(text: appTitle3),
              ],
            ),
          ),
        ));
  }

  Widget _gameboardWidget(boardNumber) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: 0.97 * 5 * cardEffectiveMaxPixel,
          maxHeight: 0.97 * numRowsPerBoard * cardEffectiveMaxPixel),
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
    bool legalOrShort = typeCountInWord != 5 || oneLegalWord;

    bool infPreviousWin5 = false;
    if (infSuccessWords.contains(wordForRowOfIndex)) {
      if (infSuccessBoardsMatchingWords[
              infSuccessWords.indexOf(wordForRowOfIndex)] ==
          boardNumber) {
        infPreviousWin5 = true;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10), //needed for green border
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
            maxWidth: keyboardSingleKeyEffectiveMaxPixel * 10,
            maxHeight: keyboardSingleKeyEffectiveMaxPixel * 3),
        child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), //ios fix
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
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
                    : noAnimations
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
                              child: _kbTextSquare(index),
                            ),
                          )),
          ],
        ),
      ),
    );
  }

  Widget _kbTextSquare(index) {
    return SizedBox(
        height: 500,
        width: 500,
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
                        child: const Icon(Icons.keyboard_return_sharp,
                            color: Colors.white))
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
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: numBoards,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: numBoards ~/ numPresentationBigRowsOfBoards,
          childAspectRatio: 1 /
              ((numBoards / numPresentationBigRowsOfBoards) /
                  numPresentationBigRowsOfBoards),
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
    if (!oneMatchingWord && currentWord >= numRowsPerBoard) {
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
