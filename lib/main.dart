import 'package:flutter/material.dart';
import 'package:dh/wordlist.dart';
import 'dart:math';

Random random = Random();

String appTitle = "infinitordle";
String appTitle1 = "infinit";
String appTitle2 = "o";
String appTitle3 = "rdle";
const Color bg = Color(0xff222222);
const double keyboardSingleKeyStarterMaxPixel = 80;
const numBoards = 4;
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
final _keyboardList = "qwertyuiopasdfghjkl <zxcvbnm >".split("");
final _legalWords = kLegalWordsText.split("\n");
final _finalWords = kFinalWordsText.split("\n");
final infSuccessWords = [];
final infSuccessBoardsMatchingWords = [];
final infSuccessPraise = [];
bool infMode = true;
bool _cheatMode = false; //for debugging
const infNumBacksteps = 1; //defunct

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

List getTargetWords(numberOfBoards) {
  var starterList = [];
  for (var i = 0; i < numberOfBoards; i++) {
    starterList.add(_finalWords[random.nextInt(_finalWords.length)]);
  }
  return starterList;
}

class _InfinitordleState extends State<Infinitordle> {
  //initialise
  double scW = 100; //default value only
  double scH = 100; //default value only
  double vertSpaceAfterTitle = 30; //default value only
  double keyboardSingleKeyEffectiveMaxPixel = 10; //default value only
  int numPresentationBigRowsOfBoards = 2; //default value only
  //int numRowsPerBoard = 1;

  //production: empty initialise
  var _targetWords = getTargetWords(numBoards);
  var _gameboardEntries =
      List<String>.generate((numRowsPerBoard * 5), (i) => "");
  int _currentWord = 0;
  int _typeCountInWord = 0;

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
          content: Text("You've got " +
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
              child: const Text('OK', style: TextStyle(
        color: Colors.red)),
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
      if (_keyboardList[index] == ">") { //submit guess
        if (_typeCountInWord == 5) { //ignore if not completed whole word
          if (_legalWords.contains(_gameboardEntries
              .sublist(_currentWord * 5, (_currentWord + 1) * 5)
              .join(""))) {
            //valid word so accept and move to next line
            _currentWord++;
            _typeCountInWord = 0;

            if (infMode) {
              //Code for single win in infMode
              for (var board = 0; board < numBoards; board++) {
                if (_detectBoardSolvedByRow(board, _currentWord)) {
                  //execute infinturdle code. Erase a row and step back
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
                      _finalWords[random.nextInt(_finalWords.length)]; //new target word
                  if (appTitle2 == "o") { //put ∞ symbols into title
                    appTitle2 = "∞";
                  } else {
                    // ignore: prefer_interpolation_to_compose_strings
                    appTitle2 = appTitle2 + "∞";
                  }
                  //record success words for conclusion and to green outline
                  infSuccessWords.add(_gameboardEntries
                      .sublist((_currentWord - 1) * 5, (_currentWord) * 5)
                      .join(""));
                  infSuccessBoardsMatchingWords.add(board);

                  //temporarily full green, by adding to praise list and then removing
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
            for (var i = 0; i < numBoards; i++) {
              if (!_detectBoardSolvedByRow(i, _currentWord)) {
                totallySolved = false;
              }
            }
            if (totallySolved) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(appTitle)));
            }

            //Code for losing game
            if (_currentWord >= numRowsPerBoard) {
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

  void _resetBoard(context) {
    Navigator.pop(context, 'OK');
    setState(() {
      //initialise on reset
      _typeCountInWord = 0;
      _currentWord = 0;
      _gameboardEntries =
          List<String>.generate((numRowsPerBoard * 5), (i) => "");
      _targetWords = getTargetWords(numBoards);
      appTitle2 = "o";
      infSuccessWords.clear();
      infSuccessBoardsMatchingWords.clear();

      //speed initialise entries using cheat mode for debugging
      if (_cheatMode) {
        _targetWords[0] = "scoff";
        if (numBoards == 4) {
          _targetWords[1] = "brunt";
          _targetWords[2] = "chair";
          _targetWords[3] = "table";
        }
        const cheatString = "maplewindyscourfightkebab";
        for (var j = 0; j < cheatString.length; j++) {
          _gameboardEntries[j] = cheatString[j];
        }
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
    //recalculate these key values regularly, for screen size changes
    scW = MediaQuery.of(context).size.width;
    scH = MediaQuery.of(context).size.height;
    vertSpaceAfterTitle = scH - 50;
    keyboardSingleKeyEffectiveMaxPixel = min(scW / 10,
        min(keyboardSingleKeyStarterMaxPixel, vertSpaceAfterTitle * 0.25 / 3));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _titleWidget(),
      ),
      body: Container(
        color: Colors.black87,
        child: Column(
          children: [
            Wrap(
              //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                //split into 2 so that dont get a wrap on 3 + 1 basis. Not that this is why 2 is hardcoded below
                Wrap(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: List.generate(
                      numBoards ~/ 2, (index) => _gameboardWidget(index)),
                ),
                Wrap(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 8.0,
                  runSpacing: 8.0,
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
    );
  }

  Widget _titleWidget() {
    return GestureDetector(
        onTap: () {
          _showResetConfirmScreen();
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
    double vertSpaceForBoard =
        vertSpaceAfterTitle - keyboardSingleKeyEffectiveMaxPixel * 3;

    if (scW < 850) {
      //((scW-8*(numberOfBoards-1)) /numberOfBoards/5 < 0.5* (verSpaceAfterTitle - 5 - effectiveMaxSingleKeyPixel*3) / numRowsPerBoard) {//(scW < 850) { //FIXME harcoded number //|| scH > scW
      numPresentationBigRowsOfBoards = 2;
    } else {
      numPresentationBigRowsOfBoards = 1;
    }

    double gameboardSingleBoxEffectiveMaxPixel = min(
        keyboardSingleKeyStarterMaxPixel,
        min(vertSpaceForBoard / numPresentationBigRowsOfBoards / numRowsPerBoard,
            scW / (numBoards ~/ numPresentationBigRowsOfBoards) / 5));

    return Container(
      //constraints: BoxConstraints(maxWidth: 250, maxHeight: (5 + numberOfBoards.toDouble()) * 50),
      constraints: BoxConstraints(
          maxWidth: 0.97 *
              5 *
              gameboardSingleBoxEffectiveMaxPixel, //restriction on single gameboard
          maxHeight: 0.97 *
              numRowsPerBoard *
              gameboardSingleBoxEffectiveMaxPixel), //restriction on single gameboard
      child: GridView.builder(
          itemCount: numRowsPerBoard * 5,
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
            maxWidth: keyboardSingleKeyEffectiveMaxPixel * 10,
            maxHeight: keyboardSingleKeyEffectiveMaxPixel * 3),
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
      constraints: BoxConstraints(
          maxWidth: keyboardSingleKeyEffectiveMaxPixel - 8,
          maxHeight: keyboardSingleKeyEffectiveMaxPixel - 8),
      child: GridView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: numBoards,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: numBoards,
            childAspectRatio: 1 / numBoards,
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
              : Colors.transparent // Colors.grey
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
                ? Colors.black //hide after solved by making text black, so invisible
                : Colors.white
            : Colors.white,
        fontWeight: gameboardOrKeyboard == "gameboard"
            ? FontWeight.bold
            : FontWeight.normal,
      ),
    );
  }
}

class Infinitordle extends StatefulWidget {
  const Infinitordle({super.key});

  @override
  State<Infinitordle> createState() => _InfinitordleState();
}
