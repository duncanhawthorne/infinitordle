// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:dh/wordlist.dart';
import 'dart:math';

Random random = Random();

String startingTitle = "infinitordle";
String appTitle = "infinitordle";
String appTitle1 = "infinit";
String appTitle2 = "o";
String appTitle3 = "rdle";
const Color bg = Color(0xff222222);
const double kbKeyMaxPix = 80;
const numberOfBoards = 4;
final _keyboardList = "qwertyuiopasdfghjkl <zxcvbnm >".split("");
final _legalWords = kLegalWordsText.split("\n");
final _finalWords = kFinalWordsText.split("\n");
final infSuccessWords = [];
final infSuccessBoardsMatchingWords = [];
final infSuccessPraise = [];
bool infinitordle = true;
bool _cheatMode = false;
const infNumBacksteps = 1;

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
        //https://github.com/flutter/flutter/issues/93140
        //fontFamily: kIsWeb && window.navigator.userAgent.contains('OS 15_')
        //    ? '-apple-system'
        //    : null,
        fontFamily: '-apple-system',
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: bg,
        ),
      ),
      home: const Duncanordle(),
    );
  }
}

List getTargetWords(numberOfBoards) {
  var starterList = [];
  for (var i = 0; i < numberOfBoards; i++) {
    starterList.add(_finalWords[random.nextInt(_finalWords.length)]);
  }
  return starterList;
}

class _DuncanordleState extends State<Duncanordle> {
  //initialise
  int _typeCountInWord = 0;
  double scW = 100; //default value
  double scH = 100;
  double verSpaceAfterTitle = 30;
  double effectiveMaxSingleKeyPixel = 10;
  int numberOfBigRowsOfBoards = 2;
  //int numberOfBoardsAcross = numberOfBoards ~/ numberOfBigRowsOfBoards;

  //production: empty initialise
  var _targetWords = getTargetWords(numberOfBoards);
  var _gameboardEntries =
      List<String>.generate(((5 + numberOfBoards) * 5), (i) => "");
  int _currentWord = 0;

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
                    "\nYou missed: " +
                    _targetWords.join(", ")),
              ],
            ),
          ),
        );
      },
    );
  }

  void _keyboardTapped(int index) {
    setState(() {
      /* //debug text to help on formatting
      _gameboardList[0] = "t";
      _gameboardList[1] = "a";
      _gameboardList[2] = "b";
      _gameboardList[3] = "l";
      _gameboardList[4] = "e";
      _whichWord = 1;
       */

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
        if (_typeCountInWord == 5) {
          if (_legalWords.contains(_gameboardEntries
              .sublist(_currentWord * 5, (_currentWord + 1) * 5)
              .join(""))) {
            //valid word so accept and move to next line
            _currentWord++;
            _typeCountInWord = 0;

            if (infinitordle) {
              //Code for winning one game
              for (var board = 0; board < numberOfBoards; board++) {
                if (_detectBoardSolvedByRow(board, _currentWord)) {
                  true; //execute infinturdle code
                  for (var j = 0; j < infNumBacksteps; j++) {
                    var tmpGameboardEntries =
                        _gameboardEntries.sublist(5, _gameboardEntries.length);
                    for (var i = 0; i < 5; i++) {
                      tmpGameboardEntries.add("");
                    }
                    _gameboardEntries = tmpGameboardEntries;
                    _currentWord--;
                  }
                  _targetWords[board] =
                      _finalWords[random.nextInt(_finalWords.length)];
                  //_keyboardList[19] = (int.parse(_keyboardList[19])+1).toString();
                  if (appTitle2 == "o") {
                    appTitle2 = "∞";
                  } else {
                    // ignore: prefer_interpolation_to_compose_strings
                    appTitle2 = appTitle2 + "∞";
                  }
                  //appTitle = appTitle.substring(0, 7) +
                  //    "∞" +
                  //    appTitle.substring(
                  //        appTitle.contains("o") ? 8 : 7,
                  //        appTitle
                  //            .length); //first time replace o with inf, then just add inf
                  infSuccessWords.add(_gameboardEntries
                      .sublist((_currentWord - 1) * 5, (_currentWord) * 5)
                      .join(""));
                  infSuccessBoardsMatchingWords.add(board);
                  infSuccessPraise.add(board);
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    setState(() {
                      infSuccessPraise.removeLast();
                    });
                  });
                }
              }
            }

            //Code for totally winning game across all boards
            bool totallySolved = true;
            for (var i = 0; i < numberOfBoards; i++) {
              if (!_detectBoardSolvedByRow(i, _currentWord)) {
                totallySolved = false;
              }
            }
            if (totallySolved) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(appTitle)));
            }

            //Code for losing game
            if (_currentWord >= 5 + numberOfBoards) {
              //didn't get it in time
              _showTargetWordsSolution();
            }
          } else {
            //not a word so just reset current word
            _gameboardEntries[_currentWord * 5 + 0] = "";
            _gameboardEntries[_currentWord * 5 + 1] = "";
            _gameboardEntries[_currentWord * 5 + 2] = "";
            _gameboardEntries[_currentWord * 5 + 3] = "";
            _gameboardEntries[_currentWord * 5 + 4] = "";
            _typeCountInWord = 0;
          }
        }
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

  void _resetBoard() {
    setState(() {
      //initialise on reset
      _typeCountInWord = 0;
      _currentWord = 0;
      _gameboardEntries =
          List<String>.generate(((5 + numberOfBoards) * 5), (i) => "");
      _targetWords = getTargetWords(numberOfBoards);
      appTitle2 = "o";
      infSuccessWords.clear();
      infSuccessBoardsMatchingWords.clear();

      //speed initialise
      if (_cheatMode) {
        _targetWords[0] = "scoff";
        if (numberOfBoards == 4) {
          _targetWords[1] = "brunt";
          _targetWords[2] = "chair";
          _targetWords[3] = "table";
        }
        const cheatString = "maplewindyscourfightkebab";
        for (var j = 0; j < cheatString.length; j++) {
          _gameboardEntries[j] = cheatString[j];
        }
        //_gameboardEntries = "maplewindyscourfightkebab     ".split("");
        _currentWord = 5;
      }
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
    return const Color(0xff555555); //not yet used
  }

  Color _getGameboardSquareColor(index, boardNumber) {
    if (index >= (_currentWord) * 5) {
      //later rows
      return Colors.black;
    } else {
      if (_targetWords[boardNumber][index % 5] == _gameboardEntries[index]) {
        return Colors.green;
      } else if (_targetWords[boardNumber].contains(_gameboardEntries[index])) {
        return Colors.amber;
      } else {
        return Colors.black;
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
    scW = MediaQuery.of(context).size.width;
    scH = MediaQuery.of(context).size.height;
    //print(scW);
    verSpaceAfterTitle = scH - 70;
    effectiveMaxSingleKeyPixel = min(scW/10,min(kbKeyMaxPix,verSpaceAfterTitle * 0.25 /3));
    //_resetBoard();
    return Scaffold(
      appBar: AppBar(
        title: _titleWidget(),
      ),
      body: Container(
        color: Colors.black87,

        child: Column(
          //color: Colors.grey,
          children: [
            Wrap(
              //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(numberOfBoards, (index) => _gameboardWidget(index)),
            ),

            //Row(
            //  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //  children: List.generate(
            //      numberOfBoardsAcross, (index) => _gameboardWidget(index + numberOfBoardsAcross)),
            //),
            const Divider(color: Colors.transparent),
            _keyboardWidget(),
          ],
        ),
      ),
    );
  }

  Widget _titleWidget() {
    return GestureDetector(
        onTap: () {
          _resetBoard();
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(appTitle1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  )),
              Text(appTitle2,
                  style: TextStyle(
                    color: appTitle2 == "o" ? Colors.white : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  )),
              Text(appTitle3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  )),
            ],
          ),
        ));
  }

  Widget _gameboardWidget(boardNumber) {
    //double scW = MediaQuery.of(context).size.width;
    //double scH = MediaQuery.of(context).size.height;
    //double verSpaceAfterTitle = scH - 70;



    int numBoardRows = 5 + numberOfBoards;
    double boardMinPix = 80;
    double vertSpaceForBoard = verSpaceAfterTitle - effectiveMaxSingleKeyPixel * 3;

    //double effectiveMaxSingleBPixelNoWrap = min(boardMinPix,min(vertSpaceForBoard / 1 / numBoardRows, scW / (numberOfBoards ~/ 1)/5));

    if (scW < 850) { //FIXME harcoded number //|| scH > scW
      numberOfBigRowsOfBoards = 2;
    }
    else {
      numberOfBigRowsOfBoards = 1;
    }

    //print([scW, numberOfBigRowsOfBoards, effectiveMaxSingleBPixelNoWrap, effectiveMaxSingleBPixelNoWrap * (numberOfBoards * 5)]);

    double effectiveMaxSingleBPixel = min(boardMinPix,min(vertSpaceForBoard / numberOfBigRowsOfBoards / numBoardRows, scW / (numberOfBoards ~/ numberOfBigRowsOfBoards)/5));



    //print([scW, scH, effectiveKbPix, vertSpaceForBoard]);
    return Container(
      //constraints: BoxConstraints(maxWidth: 250, maxHeight: (5 + numberOfBoards.toDouble()) * 50),
      constraints: BoxConstraints(
          maxWidth: 0.97 * 5 * effectiveMaxSingleBPixel, //restriction on single gameboard
          maxHeight: 0.97 * numBoardRows * effectiveMaxSingleBPixel
      ), //restriction on single gameboard
      child: GridView.builder(
          itemCount: numBoardRows * 5,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _square("gameboard", index, boardNumber, "unused");
          }),
    );
  }

  Widget _keyboardWidget() {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(
            maxWidth: effectiveMaxSingleKeyPixel*10,
            maxHeight: effectiveMaxSingleKeyPixel*3),
        child: GridView.builder(
            itemCount: 30,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
            ),
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                  onTap: () {
                    _keyboardTapped(index);
                  },
                  child: _keyStackWithMiniGrid("keyboard", index, -1));
            }),
      ),
    );
  }

  Widget _keyStackWithMiniGrid(gameboardOrKeyboard, index, boardNumber) {
    return Stack(
      children: [
        //Center(
        //    child: _square(
        //        gameboardOrKeyboard, index, boardNumber, Colors.black45)),
        Center(
            child: _miniGridContainer(
                gameboardOrKeyboard, index, boardNumber, "not used")),
        Center(
            child: _square(
                gameboardOrKeyboard, index, boardNumber, Colors.transparent))
      ],
    );
  }

  Widget _miniGridContainer(gameboardOrKeyboard, index, boardNumber, cols) {
    return Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxSingleKeyPixel -8, maxHeight: effectiveMaxSingleKeyPixel -8),
      child: GridView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: numberOfBoards,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: numberOfBoards,
            childAspectRatio: 1 / numberOfBoards,
          ),
          itemBuilder: (BuildContext context, int subIndex) {
            return _miniSquareColor(
                gameboardOrKeyboard, index, boardNumber, subIndex);
          }),
    );
  }

  Widget _miniSquareColor(gameboardOrKeyboard, index, boardNumber, subIndex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      height: 1000,
      decoration: BoxDecoration(
        color: _getBestColorForLetter(_keyboardList[index], subIndex),
      ),
    );
  }

  Widget _square(gameboardOrKeyboard, index, boardNumber, color) {
    bool infGolden = false;
    var wordForRow = _gameboardEntries
        .sublist((5 * (index ~/ 5)).toInt(), (5 * (index ~/ 5) + 5).toInt())
        .join("");
    if (infSuccessWords.contains(wordForRow)) {
      if (infSuccessBoardsMatchingWords[infSuccessWords.indexOf(wordForRow)] ==
          boardNumber) {
        infGolden = true;
      }
    }
    return AnimatedContainer(
      height:
          500, //oversize the container so it goes to maximum allowed in grid
      width: 500, //oversize the container so it goes to maximum allowed in grid
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      decoration: BoxDecoration(
          border: Border.all(
              color: infGolden
                  ? Colors.green
                  : gameboardOrKeyboard == "keyboard"
                      ? bg
                      : bg, //Color(0xff555555),
              width: 3),
          borderRadius: BorderRadius.circular(
              10), //gameboardOrKeyboard == "keyboard" ? null :
          color: gameboardOrKeyboard == "gameboard"
              ? infSuccessPraise.contains(boardNumber) &&
                      index ~/ 5 ==
                          _currentWord - 1 //cursor is now on the next word
                  ? Colors.green
                  : _detectBoardSolvedByRow(boardNumber, index ~/ 5)
                      ? Colors.black //hide after solved
                      : _getGameboardSquareColor(index, boardNumber)
              : Colors
                  .transparent // _getBestColorForLetter(_keyboardList[index], 0) //Colors.black
          ),
      child: FittedBox(
        fit: BoxFit
            .fitHeight, //make text expand to vertically fill box, while keeping aspect ratio
        child: _squareText(gameboardOrKeyboard, index, boardNumber),
      ),
    );
  }

  Widget _squareText(gameboardOrKeyboard, index, boardNumber) {
    return Text(
      gameboardOrKeyboard == "gameboard"
          ? _gameboardEntries[index].toUpperCase()
          : _keyboardList[index].toUpperCase(),
      style: TextStyle(
        color: gameboardOrKeyboard == "gameboard"
            ? _detectBoardSolvedByRow(boardNumber, index ~/ 5)
                ? Colors.black //hide after solved
                : Colors.white
            : Colors.white,
        fontWeight: gameboardOrKeyboard == "gameboard"
            ? FontWeight.bold
            : FontWeight.normal,
        //fontSize: gameboardOrKeyboard == "gameboard" ? 40 : 40,
      ),
    );
  }

  /*
  Widget _keyboard() {
    return KeyboardListener(
        focusNode: _miniSquareColor(1,2,3,4),
        child: _miniSquareColor(1,2,3,4),
        onKeyEvent: (event) {
          if (event.runtimeType == RawKeyDownEvent) {
            if (event.physicalKey == PhysicalKeyboardKey.keyX) {
              _gameboardEntries[0] = "q";
            }
          }
        },
    );
  }
  */

}

class Duncanordle extends StatefulWidget {
  const Duncanordle({super.key});

  @override
  State<Duncanordle> createState() => _DuncanordleState();
}
