// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/helper.dart';
import 'dart:math';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/secrets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

FocusNode focusNode = FocusNode();

//void main() {
//  runApp(const MyApp());
//}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  db = FirebaseFirestore.instance;
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
  GoogleSignInAccount? _currentUser;

  @override
  initState() {
    super.initState();
    //fbInit();
    resetBoardReal(false);
    loadUser();
    initalSignIn();
    loadKeys();

    usersStream = db.collection('states').snapshots();

    setState(() {});
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: 1000 * i), () {
        setState(
            () {}); //Hack, but makes sure state set right shortly after starting
      });
    }
  }

  Future<void> initalSignIn() async {
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
    });
    await googleSignIn.signInSilently();
    /*


    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      gUser = user.email;
    }

    print(gUser);
    await loadKeys();
    print(gUser);
    initiateFlipState();
    setState(() {});

     */
  }

  Future<void> _handleSignIn() async {
    await _handleSignInReal();
    await _handleSignInReal();
  }

  Future<void> _handleSignInReal() async {
    p("_handleSignInReal()");
    if (fakeLogin) {
      // ignore: avoid_print
      p("fakelogin");
      gUser = "X";
    } else {
      //print("real");
      try {
        p("try");
        p("gUser" + gUser);
        // ignore: await_only_futures
        await googleSignIn.onCurrentUserChanged
            .listen((GoogleSignInAccount? account) {
          _currentUser = account;
        });
        await googleSignIn.signIn();
        googleSignIn.onCurrentUserChanged
            .listen((GoogleSignInAccount? account) {
          _currentUser = account;
        });
        //await initalSignIn();
        final GoogleSignInAccount? user = _currentUser;
        //print(user);
        if (user != null) {
          gUser = user.email;
        }
        p("gUser" + gUser);
      } catch (error) {
        p(error);
      }
    }
    //print("guser"+gUser);
    await saveUser();
    await loadKeys();
    initiateFlipState();
    setState(() {});
    //_handleSignIn();
  }

  Future<void> _handleSignOut() async {
    //print("signout");
    if (fakeLogin) {
    } else {
      await googleSignIn.disconnect();
    }
    gUser = gUserDefault;
    //print(gUser);
    await saveUser();
    resetBoardReal(true);
    await loadKeys();
    initiateFlipState();
    setState(() {});
  }

  void flipCard(index, toFOrB) {
    flipCardReal(index, toFOrB);
    setState(() {});
  }

  void delayedFlipOnAbsoluteCard(int currentWord, int i, toFOrB) {
    Future.delayed(
        Duration(milliseconds: delayMult * i * (durMult == 1 ? 100 : 250)), () {
      //flip to reveal the colors with pleasing animation
      flipCardReal((currentWord - 1) * 5 + i, toFOrB);
      setState(() {});
    });
  }

  void onKeyboardTapped(int index) {
    cheatPrintTargetWords();
    //print(gUser);

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
              //Slide the cards back visually, creating the illusion of stepping back
              oneStepState = 1;
              setState(() {});
              Future.delayed(Duration(milliseconds: durMult * 250), () {
                //Undo the visual slide (and do this instanteously)
                oneStepState = 0;
                //Actually erase a row and step back, so state matches visual illusion above
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
                    Future.delayed(Duration(milliseconds: delayMult * 750), () {
                      if (currentWord > 0) {
                        //Slide the cards back visually, creating the illusion of stepping back
                        oneStepState = 1;
                        setState(() {});
                        Future.delayed(Duration(milliseconds: durMult * 250),
                            () {
                          //Undo the visual slide (and do this instanteously)
                          oneStepState = 0;
                          //Actually erase a row and step back, so state matches visual illusion above
                          oneStepBack(currentWordLocal);
                          setState(() {});
                        });
                      }
                    });
                  }
                });
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

  void resetBoard(saveReset) {
    resetBoardReal(saveReset);
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
      body: keyboardListenerWrapper(),
    );
  }

  Widget keyboardListenerWrapper() {
    return KeyboardListener(
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
      child: streamBuilderWrapperOnDocument(),
    );
  }

  Widget streamBuilderWrapperOnDocument() {
    if (gUser == gUserDefault) {
      return _wrapStructure();
    } else {
      return StreamBuilder<DocumentSnapshot>(
        stream: db.collection('states').doc(gUser).snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError || !snapshot.hasData) {
          } else if (snapshot.connectionState == ConnectionState.waiting) {
          } else {
            //print(snapshot);
            var userDocument = snapshot.data;
            //print(userDocument);
            if (userDocument != null && userDocument.exists) {
              String snapshotCurrent = userDocument["data"];
              //print(snapshotCurrent);
              if (snapshotCurrent != snapshotLast && gUser != gUserDefault) {
                loadKeysReal(snapshotCurrent);
                snapshotLast = snapshotCurrent;
              }
            }
          }

          return _wrapStructure();
        },
      );
    }
  }

  Widget streamBuilderWrapperOnCollection() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
        } else if (snapshot.connectionState == ConnectionState.waiting) {
        } else {
          String snapshotCurrent = getDataFromSnapshot(snapshot);
          if (snapshotCurrent != snapshotLast && gUser != gUserDefault) {
            loadKeysReal(snapshotCurrent);
            snapshotLast = snapshotCurrent;
          }
        }
        return _wrapStructure();
      },
    );
  }

  // ignore: unused_element
  Widget _aspectRatioStructure() {
    //bool tall = MediaQuery.of(context).size.width <
    //    2 * 0.75 * (MediaQuery.of(context).size.height - 56);
    return Center(
      child: Container(
        color: bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                flex: 75,
                child: Flex(
                    direction: numPresentationBigRowsOfBoards == 2
                        ? Axis.vertical
                        : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          flex: 50,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                    flex: 50,
                                    child: Column(
                                      children: [
                                        Expanded(
                                            flex: 50,
                                            child: AspectRatio(
                                                aspectRatio:
                                                    5 / numRowsPerBoard,
                                                child: _gameboardWidget(0))),
                                      ],
                                    )),
                                Expanded(
                                    flex: 50,
                                    child: Column(
                                      children: [
                                        Expanded(
                                            flex: 50,
                                            child: AspectRatio(
                                                aspectRatio:
                                                    5 / numRowsPerBoard,
                                                child: _gameboardWidget(0))),
                                      ],
                                    ))
                              ])),
                      Expanded(
                          flex: 50,
                          child: Row(
                              //crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                    flex: 50,
                                    child: Column(
                                      children: [
                                        Expanded(
                                            flex: 50,
                                            child: AspectRatio(
                                                aspectRatio:
                                                    5 / numRowsPerBoard,
                                                child: _gameboardWidget(0))),
                                      ],
                                    )),
                                Expanded(
                                    flex: 50,
                                    child: Column(
                                      children: [
                                        Expanded(
                                            flex: 50,
                                            child: AspectRatio(
                                                aspectRatio:
                                                    5 / numRowsPerBoard,
                                                child: _gameboardWidget(0))),
                                      ],
                                    ))
                              ])),
                    ])),
            Expanded(
                flex: 25,
                child: AspectRatio(
                    aspectRatio: 10 / (3 * keyAspectRatio),
                    child: _keyboardWidget())
                /*
              Flex(
                  direction: tall ? Axis.vertical : Axis.horizontal,
                  children: [
                    Expanded(
                        flex: 100,
                        child: Row(
                          //crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  flex: 100,
                                  child: Column(
                                    children: [
                                      Expanded(
                                          flex: 100,
                                          child: AspectRatio(
                                              aspectRatio: 10 / (3 * keyAspectRatio),
                                              child: _keyboardWidget())),
                                    ],
                                  )),

                            ])),
                  ]),
        */
                ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _wrapStructure() {
    return Container(
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
    );
  }

  Widget _titleWidget() {
    var infText = infSuccessWords.isEmpty
        ? "o"
        : "∞" * (infSuccessWords.length ~/ 2) +
            "o" * (infSuccessWords.length % 2);
    return GestureDetector(
        onTap: () {
          showResetConfirmScreen();
        },
        child: FittedBox(
          //fit: BoxFit.fitHeight,
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: appBarHeight * 40 / 56,
              ),
              children: <TextSpan>[
                TextSpan(text: appTitle1),
                TextSpan(
                    text: infText,
                    style: TextStyle(
                        color: infSuccessWords.isEmpty
                            ? Colors.white
                            : Colors.green)),
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
                    child: _positionedCard(index, boardNumber, val, "f"),
                  ),
          ));
        });
  }

  Widget _positionedCard(index, boardNumber, val, bf) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          curve: Curves.fastOutSlowIn,
          duration: Duration(milliseconds: oneStepState * durMult * 200),
          top: -cardEffectiveMaxPixel * oneStepState,
          child: SizedBox(
            height: cardEffectiveMaxPixel,
            width: cardEffectiveMaxPixel,
            child: _card(index, boardNumber, val, bf),
          ),
        ),
      ],
    );
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
    return Container(
      padding: EdgeInsets.all(0.005 * cardEffectiveMaxPixel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0.2 * cardEffectiveMaxPixel),
        child: Container(
          //padding: const EdgeInsets.all(1),
          //height: 500, //oversize so it renders in full and so doesn't pixelate
          //width: 500, //oversize so it renders in full and so doesn't pixelate
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
                          ? 0.05 * cardEffectiveMaxPixel //2
                          : 0),
              borderRadius: BorderRadius.circular(
                  0.2 * cardEffectiveMaxPixel), //needed for green border
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
        fontSize: cardEffectiveMaxPixel,
        color: !infMode && detectBoardSolvedByRow(boardNumber, rowOfIndex)
            ? Colors.transparent // bg //"hide" after being solved
            : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _keyboardWidget() {
    return Container(
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
    );
  }

  Widget _kbStackWithMiniGrid(index) {
    return Container(
      padding: EdgeInsets.all(0.005 * keyboardSingleKeyEffectiveMaxPixelHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            0.1 * keyboardSingleKeyEffectiveMaxPixelHeight),
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
        height: double.infinity, //keyboardSingleKeyEffectiveMaxPixelHeight, //500,
        width: double.infinity, // keyboardSingleKeyEffectiveMaxPixelHeight / keyAspectRatio, //500,
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
    final GoogleSignInAccount? user = _currentUser;
    // ignore: avoid_print
    print(user);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appTitle),
              GestureDetector(
                  onTap: () {
                    setState(() {
                      gUser == gUserDefault
                          ? _handleSignIn()
                          : _handleSignOut();
                      focusNode.requestFocus();
                      Navigator.pop(context);
                    });
                  },
                  child: gUser == gUserDefault
                      ? const Icon(Icons.person_off, color: bg)
                      : user == null
                          ? const Icon(Icons.face, color: bg)
                          : GoogleUserCircleAvatar(identity: user)
                  //Text((gUser.substring(0, 1).toUpperCase())),
                  )
            ],
          ),
          content: Text(end
              ? "You got " +
                  infSuccessWords.length.toString() +
                  " word" +
                  (infSuccessWords.length == 1 ? "" : "s") +
                  ": " +
                  infSuccessWords.join(", ") +
                  "\n\nYou missed: " +
                  targetWords.join(", ") +
                  "\n\nReset the board?"
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
                resetBoard(true),
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
