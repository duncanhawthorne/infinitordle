import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/wordlist.dart';
import 'package:infinitordle/helper.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

bool _cheatMode = false; //for debugging

String appTitle = "infinitordle";
String appTitle1 = "infinit";
String appTitle3 = "rdle";
const Color bg = Color(0xff222222);
const double keyboardSingleKeyUnconstrainedMaxPixel = 80;
const numBoards = 4;
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
final _keyboardList = "qwertyuiopasdfghjkl <zxcvbnm >".split("");
final _legalWords = kLegalWordsText.split("\n");

final List<String> infSuccessWords = [];
final infSuccessBoardsMatchingWords = [];
const double boardSpacer = 8;
bool infMode = true;
const infNumBacksteps = 1;
const grey = Color(0xff555555);

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

class _InfinitordleState extends State<Infinitordle> {
  //initialise
  double scW = -1; //default value only
  double scH = -1; //default value only
  double vertSpaceAfterTitle = -1; //default value only
  double keyboardSingleKeyEffectiveMaxPixel = -1; //default value only
  int numPresentationBigRowsOfBoards = -1; //default value only

  //production: empty initialise
  var _targetWords = getTargetWords(numBoards); //gets overriden by initState()
  var _gameboardEntries =
      List<String>.generate((numRowsPerBoard * 5), (i) => "");
  int _currentWord = -1; //gets overriden by initState()
  int _typeCountInWord = 0;

  @override
  initState() {
    super.initState();
    loadKeys();
  }

  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _targetWords[0] = prefs.getString('word0') ?? getTargetWord();
    _targetWords[1] = prefs.getString('word1') ?? getTargetWord();
    _targetWords[2] = prefs.getString('word2') ?? getTargetWord();
    _targetWords[3] = prefs.getString('word3') ?? getTargetWord();
    _currentWord = prefs.getInt('currentWord') ?? 0;

    var tmpinfSuccessWords = prefs.getString('infSuccessWords') ?? "";
    for (var i = 0; i < tmpinfSuccessWords.length ~/ 5; i++) {
      var j = i * 5;
      infSuccessWords.add(tmpinfSuccessWords.substring(j, j + 5));
      infSuccessBoardsMatchingWords.add(-1);
    }

    var tmpGB1 = prefs.getString('gameboardEntries') ?? "";
    for (var i = 0; i < tmpGB1.length; i++) {
      _gameboardEntries[i] = tmpGB1.substring(i, i + 1);
    }
    for (var j = 0; j < _gameboardEntries.length; j++) {
      if (_gameboardEntries[j] != "") {
        _flip(j, -1);
      }
    }
    setState(() {});
    saveKeys();
  }

  Future<void> saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('word0', _targetWords[0]);
    await prefs.setString('word1', _targetWords[1]);
    await prefs.setString('word2', _targetWords[2]);
    await prefs.setString('word3', _targetWords[3]);
    await prefs.setInt('currentWord', _currentWord);
    await prefs.setString('infSuccessWords', infSuccessWords.join(""));

    var tmpGB1 = "";
    for (var i = 0; i < _gameboardEntries.length; i++) {
      tmpGB1 = tmpGB1 + _gameboardEntries[i];
    }
    await prefs.setString('gameboardEntries', tmpGB1);
  }

  Future<void> _showTargetWordsSolution() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // ignore: prefer_interpolation_to_compose_strings
                Text("You got " +
                    infSuccessWords.length.toString() +
                    " word" +
                    (infSuccessWords.length == 1 ? "" : "s") +
                    ": " +
                    infSuccessWords.join(", ") +
                    "\n\nYou missed: " +
                    _targetWords.join(", ")),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showResetConfirmScreen() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appTitle),
          // ignore: prefer_interpolation_to_compose_strings
          content: Text(
              // ignore: prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings
              "Solve 4 boards at once. \n\nWhen you solve a board, the target word will be changed, and you get an extra guess.\n\nCan you keep going forever and reach infinitordle?\n\n" +
                  "You've got " +
                  infSuccessWords.length.toString() +
                  " word" +
                  (infSuccessWords.length == 1 ? "" : "s") +
                  ' so far. \n\nLose your progress and reset the infinitordle board?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _resetBoard(context),
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _keyboardTapped(int index) {
    setState(() {
      if (_keyboardList[index] == " ") {
        //ignore pressing of non-keys
        return;
      }
      if (_keyboardList[index] == "<") {
        //backspace
        if (_typeCountInWord > 0) {
          _typeCountInWord--;
          _gameboardEntries[_currentWord * 5 + _typeCountInWord] = "";
        }
        return;
      }
      if (_keyboardList[index] == ">") {
        //submit guess
        if (_typeCountInWord == 5) {
          //ignore if not completed whole word
          if (_legalWords.contains(_gameboardEntries
              .sublist(_currentWord * 5, (_currentWord + 1) * 5)
              .join(""))) {
            //Legal word, but not necessarily correct word

            //Legal word so step forward
            oneLegalWord = true;
            _currentWord++;
            _typeCountInWord = 0;

            //Made a guess flip over the cards to see the colors
            for (var i = 0; i < 5; i++) {
              Future.delayed(Duration(milliseconds: 100 * i), () {
                //flip to reveal the colors with pleasing animation
                _flip((_currentWord - 1) * 5 + i, -1);
              });
            }

            //Test if it is correct word
            oneMatchingWord = false;
            int oneMatchingWordBoard = -1;
            if (infMode) {
              //Code for single win in infMode
              for (var board = 0; board < numBoards; board++) {
                if (_detectBoardSolvedByRow(board, _currentWord)) {
                  oneMatchingWord = true;
                  oneMatchingWordBoard = board;
                }
              }
            }

            //Code for losing game
            if (!oneMatchingWord && _currentWord >= numRowsPerBoard) {
              //didn't get it in time
              _showTargetWordsSolution();
            }

            if (!infMode && oneMatchingWord) {
              //Code for totally winning game across all boards
              bool totallySolved = true;
              for (var i = 0; i < numBoards; i++) {
                if (!_detectBoardSolvedByRow(i, _currentWord)) {
                  totallySolved = false;
                }
              }
              if (totallySolved) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(appTitle)));
              }
            }

            if (infMode && oneMatchingWord) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                //Give time for above code to show visually, so we have flipped
                setState(() {
                  //Erase a row and step back
                  for (var j = 0; j < infNumBacksteps; j++) {
                    var tmpGameboardEntries =
                        _gameboardEntries.sublist(5, _gameboardEntries.length);
                    for (var i = 0; i < 5; i++) {
                      tmpGameboardEntries.add("");
                    }
                    _gameboardEntries = tmpGameboardEntries;
                    _currentWord--;
                    //Reverse flip the card on the next row back to backside (after earlier having flipped them the right way)
                    for (var j = 0; j < 5; j++) {
                      _flip(_currentWord * 5 + j, -1);
                    }
                  }
                  saveKeys();
                });
              });

              Future.delayed(const Duration(milliseconds: 2500), () {
                //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                setState(() {
                  //Log the word just got in success words, which gets green to shown
                  infSuccessWords.add(_gameboardEntries
                      .sublist((_currentWord - 1) * 5, (_currentWord) * 5)
                      .join(""));
                  infSuccessBoardsMatchingWords.add(oneMatchingWordBoard);
                  //Create new target word for the board
                  _targetWords[oneMatchingWordBoard] =
                      getTargetWord();
                  saveKeys();
                });
              });
            }
          } else {
            //not a legal word so just reset current word
            _gameboardEntries[_currentWord * 5 + 0] = "";
            _gameboardEntries[_currentWord * 5 + 1] = "";
            _gameboardEntries[_currentWord * 5 + 2] = "";
            _gameboardEntries[_currentWord * 5 + 3] = "";
            _gameboardEntries[_currentWord * 5 + 4] = "";
            _typeCountInWord = 0;
          }
        }

        saveKeys();
        return;
      }
      if (true) {
        //pressing regular key, as other options already dealt with above
        if (_typeCountInWord < 5) {
          //still typing out word, else ignore
          _gameboardEntries[_currentWord * 5 + _typeCountInWord] =
              _keyboardList[index];
          _typeCountInWord++;
        }
        return;
      }
    });
  }

  void _resetBoard(context) {
    Navigator.pop(context, 'OK');
    setState(() {
      //initialise on reset
      _typeCountInWord = 0;
      _currentWord = 0;
      _gameboardEntries =
          List<String>.generate((numRowsPerBoard * 5), (i) => "");
      _targetWords = getTargetWords(numBoards);
      infSuccessWords.clear();
      infSuccessBoardsMatchingWords.clear();

      angles =
          List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);

      //speed initialise entries using cheat mode for debugging
      const cheatString = "maplewindyscourfightkebab";
      if (_cheatMode) {
        _targetWords[0] = "scoff";
        if (numBoards == 4) {
          _targetWords[1] = "brunt";
          _targetWords[2] = "chair";
          _targetWords[3] = "table";
        }

        for (var j = 0; j < cheatString.length; j++) {
          _gameboardEntries[j] = cheatString[j];
        }
        _currentWord = 5;
        for (var j = 0; j < _gameboardEntries.length; j++) {
          if (_gameboardEntries[j] != "") {
            _flip(j, -1);
          }
        }
      }
      saveKeys();
    });
  }

  Color _getBestColorForLetter(queryLetter, boardNumber) {
    if (queryLetter == " ") {
      return bg;
    }
    //get color for the keyboard based on best (green > yellow > grey) color on the grid
    for (var gameboardPosition = 0;
        gameboardPosition <
            _gameboardEntries.sublist(0, _currentWord * 5).length;
        gameboardPosition++) {
      if (_gameboardEntries[gameboardPosition] == queryLetter) {
        if (_getGameboardSquareColor(gameboardPosition, boardNumber) ==
            Colors.green) {
          return Colors.green;
        }
      }
    }
    for (var gameboardPosition = 0;
        gameboardPosition <
            _gameboardEntries.sublist(0, _currentWord * 5).length;
        gameboardPosition++) {
      if (_gameboardEntries[gameboardPosition] == queryLetter) {
        if (_getGameboardSquareColor(gameboardPosition, boardNumber) ==
            Colors.amber) {
          return Colors.amber;
        }
      }
    }
    for (var gameboardPosition = 0;
        gameboardPosition <
            _gameboardEntries.sublist(0, _currentWord * 5).length;
        gameboardPosition++) {
      if (_gameboardEntries[gameboardPosition] == queryLetter) {
        return bg; //grey //used and no match
      }
    }
    return grey; //not used yet by the player
  }

  Color _getGameboardSquareColor(index, boardNumber) {
    if (index >= (_currentWord) * 5) {
      return bg; //later rows
    } else {
      if (_targetWords[boardNumber][index % 5] == _gameboardEntries[index]) {
        return Colors.green;
      } else if (_targetWords[boardNumber].contains(_gameboardEntries[index])) {
        return Colors.amber;
      } else {
        return bg;
      }
    }
  }

  bool _detectBoardSolvedByRow(boardNumber, maxRowToCheck) {
    for (var q = 0; q < min(_currentWord, maxRowToCheck); q++) {
      bool result = true;
      for (var j = 0; j < 5; j++) {
        if (_getGameboardSquareColor(q * 5 + j, boardNumber) != Colors.green) {
          result = false;
        }
      }
      if (result) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    //recalculate these key values regularly, for screen size changes
    scW = MediaQuery.of(context).size.width;
    scH = MediaQuery.of(context).size.height;
    vertSpaceAfterTitle = scH - 56 - 2; //app bar and divider
    keyboardSingleKeyEffectiveMaxPixel = min(
        scW / 10,
        min(keyboardSingleKeyUnconstrainedMaxPixel,
            vertSpaceAfterTitle * 0.25 / 3));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _titleWidget(),
      ),
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (keyDownEvent) {
          if (_keyboardList.contains(keyDownEvent.character)) {
            _keyboardTapped(
                _keyboardList.indexOf(keyDownEvent.character ?? " "));
          }
          if (keyDownEvent.logicalKey == LogicalKeyboardKey.enter) {
            _keyboardTapped(29);
          }
          if (keyDownEvent.logicalKey == LogicalKeyboardKey.backspace) {
            _keyboardTapped(20);
          }
        },
        child: Container(
          color: Colors.black87,
          child: Column(
            children: [
              Wrap(
                spacing: boardSpacer,
                runSpacing: boardSpacer,
                children: [
                  //split into 2 so that dont get a wrap on 3 + 1 basis. Note that this is why 2 is hardcoded below
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
    var inftext = infSuccessWords.isEmpty ? "o" : "∞" * infSuccessWords.length;
    return GestureDetector(
        onTap: () {
          _showResetConfirmScreen();
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
                    text: inftext,
                    style: TextStyle(
                        color: inftext == "o" ? Colors.white : Colors.green)),
                TextSpan(text: appTitle3),
              ],
            ),
          ),
        ));
  }

  Widget _gameboardWidget(boardNumber) {
    double vertSpaceForGameboard =
        vertSpaceAfterTitle - keyboardSingleKeyEffectiveMaxPixel * 3;
    double vertSpaceForSingleGameboardKeyNoWrap =
        vertSpaceForGameboard / numRowsPerBoard;
    double horizSpaceForSingleGameboardKeyNoWrap =
        (scW - (numBoards - 1) * boardSpacer) / numBoards / 5;

    if (vertSpaceForSingleGameboardKeyNoWrap >
        2 * horizSpaceForSingleGameboardKeyNoWrap) {
      numPresentationBigRowsOfBoards = 2;
    } else {
      numPresentationBigRowsOfBoards = 1;
    }

    double gameboardSingleBoxEffectiveMaxPixel = min(
        keyboardSingleKeyUnconstrainedMaxPixel,
        min(
            (vertSpaceForGameboard) /
                numPresentationBigRowsOfBoards /
                numRowsPerBoard,
            (scW - (numBoards - 1) * boardSpacer) /
                (numBoards ~/ numPresentationBigRowsOfBoards) /
                5));

    return Container(
      constraints: BoxConstraints(
          maxWidth: 0.97 * 5 * gameboardSingleBoxEffectiveMaxPixel,
          maxHeight:
              0.97 * numRowsPerBoard * gameboardSingleBoxEffectiveMaxPixel),
      child: GridView.builder(
          physics:
              const NeverScrollableScrollPhysics(), //turns off ios scrolling
          itemCount: numRowsPerBoard * 5,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _gbSquareTextFlipper(index, boardNumber);
          }),
    );
  }

  var angles =
      List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);

  bool oneLegalWord = false;
  bool oneMatchingWord = false;

  void _flip(index, boardNumber) {
    setState(() {
      angles[index] = (angles[index] + 0.5) % 1;
    });
  }

  Widget _gbSquareTextFlipper(index, boardNumber) {
    return GestureDetector(
      child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: angles[index]),
          duration: const Duration(milliseconds: 500),
          builder: (BuildContext context, double val, __) {
            return (Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateX(val * (2 * pi)),
              child: Container(
                  child: val <= 0.25
                      ? _gbSquare(index, boardNumber, val, "b")
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateX(pi),
                          child: _gbSquare(index, boardNumber, val, "f"),
                        )),
            ));
          }),
    );
  }

  Widget _gbSquare(index, boardNumber, val, bf) {
    int rowOfIndex = index ~/ 5;
    var wordForRowOfIndex = _gameboardEntries
        .sublist((5 * rowOfIndex).toInt(), (5 * (rowOfIndex + 1)).toInt())
        .join("");
    bool legalOrShort =
        _typeCountInWord != 5 || _legalWords.contains(wordForRowOfIndex);

    bool infPreviousWin5 = false;
    if (infSuccessWords.contains(wordForRowOfIndex)) {
      if (infSuccessBoardsMatchingWords[
              infSuccessWords.indexOf(wordForRowOfIndex)] ==
          boardNumber) {
        infPreviousWin5 = true;
      }
    }
    return Container(
      height: 500, //oversize so it renders in full and so doesn't pixelate
      width: 500, //oversize so it renders in full and so doesn't pixelate
      decoration: BoxDecoration(
          border: Border.all(
              color: bf == "b"
                  ? bg
                  : infPreviousWin5
                      ? Colors.green
                      : bg,
              width: bf == "b"
                  ? 1
                  : infPreviousWin5
                      ? 2
                      : 0),
          borderRadius: BorderRadius.circular(10),
          color: !infMode && _detectBoardSolvedByRow(boardNumber, rowOfIndex)
              ? bg //"hide" after solved board
              : bf == "b"
                  ? rowOfIndex == _currentWord && !legalOrShort
                      ? Colors.red
                      : grey
                  : _getGameboardSquareColor(index, boardNumber)),
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: _gbSquareText(index, boardNumber),
      ),
    );
  }

  Widget _gbSquareText(index, boardNumber) {
    int rowOfIndex = index ~/ 5;
    return Text(
      _gameboardEntries[index].toUpperCase(),
      style: TextStyle(
        shadows: const <Shadow>[
          Shadow(
            offset: Offset(0, 0),
            blurRadius: 1.0,
            color: bg,
          ),
        ],
        fontSize: 100,
        color: !infMode && _detectBoardSolvedByRow(boardNumber, rowOfIndex)
            ? bg //"hide" after being solved
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
    return Stack(
      children: [
        Center(
            child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: bg, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _kbMiniGridContainer(index),
          ),
        )),
        Center(
            child: Material(
          color: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            onTap: () {
              _keyboardTapped(index);
            },
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
                height: 500,
                width: 500,
                child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Text(
                      _keyboardList[index].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(0, 0),
                              blurRadius: 1.0,
                              color: bg,
                            ),
                          ]),
                    ))),
          ),
        )),
      ],
    );
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      height: 1000,
      decoration: BoxDecoration(
        color: _getBestColorForLetter(_keyboardList[index], subIndex),
      ),
    );
  }
}

class Infinitordle extends StatefulWidget {
  const Infinitordle({super.key});

  @override
  State<Infinitordle> createState() => _InfinitordleState();
}
