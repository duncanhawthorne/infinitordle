// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/secrets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:infinitordle/keyboard.dart';
import 'package:infinitordle/gameboard.dart';

FocusNode focusNode = FocusNode();

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
        final GoogleSignInAccount? user = _currentUser;
        if (user != null) {
          gUser = user.email;
        }
        p("gUser" + gUser);
      } catch (error) {
        p(error);
      }
    }
    await saveUser();
    await loadKeys();
    initiateFlipState();
    setState(() {});
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

  void ss() {
    setState(() {});
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
        ss(); // setState(() {});
      }
    } else if (keyboardList[index] == ">") {
      //submit guess
      if (typeCountInWord == 5) {
        //&& threadsafeBlockNewWord == false
        //ignore if not completed whole word
        String enteredWordLocal = gameboardEntries
            .sublist(currentWord * 5, (currentWord + 1) * 5)
            .join(""); //local variable to ensure threadsafe
        if (quickIn(legalWords, enteredWordLocal)) {
          //(legalWords.contains(enteredWordLocal)) {
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
              ss(); //setState(() {});
              Future.delayed(Duration(milliseconds: durMult * 250), () {
                //Undo the visual slide (and do this instanteously)
                oneStepState = 0;
                //Actually erase a row and step back, so state matches visual illusion above
                oneStepBack(currentWordLocal);
                ss(); //setState(() {});

                Future.delayed(Duration(milliseconds: delayMult * 1000), () {
                  //include inside other future so definitely happens after rather relying on race
                  //Give time for above code to show visually, so we have flipped, stepped back, reverse flipped next row
                  //Log the word just got in success words, which gets green to shown
                  logWinAndGetNewWord(
                      enteredWordLocal, oneMatchingWordBoardLocal);
                  ss(); //setState(() {});

                  if (streak()) {
                    Future.delayed(Duration(milliseconds: delayMult * 750), () {
                      if (currentWord > 0) {
                        //Slide the cards back visually, creating the illusion of stepping back
                        oneStepState = 1;
                        ss(); //setState(() {});
                        Future.delayed(Duration(milliseconds: durMult * 250),
                            () {
                          //Undo the visual slide (and do this instanteously)
                          oneStepState = 0;
                          //Actually erase a row and step back, so state matches visual illusion above
                          oneStepBack(currentWordLocal);
                          ss(); //setState(() {});
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
          ss(); //setState(() {});
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
          if (quickIn(
              legalWords,
              gameboardEntries
                  .sublist(currentWord * 5, (currentWord + 1) * 5)
                  .join(""))) {
            // (legalWords.contains(gameboardEntries.sublist(currentWord * 5, (currentWord + 1) * 5).join(""))) {
            oneLegalWordForRedCardsCache = true;
          }
        }
        ss(); //setState(() {});
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
            onKeyboardTapped(
                keyboardList.indexOf(keyEvent.character ?? " "));
          }
          if (keyEvent.logicalKey == LogicalKeyboardKey.enter) {
            onKeyboardTapped(keyboardList.indexOf(">"));
          }
          if (keyEvent.logicalKey == LogicalKeyboardKey.backspace &&
              backspaceSafe) {
            if (backspaceSafe) {
              // (DateTime.now().millisecondsSinceEpoch > lastTimePressedDelete + 200) {
              //workaround to bug which was firing delete key twice
              backspaceSafe = false;
              onKeyboardTapped(keyboardList.indexOf("<"));
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
                    numBoards ~/ 2, (index) => gameboardWidget(index)),
              ),
              Wrap(
                spacing: boardSpacer,
                runSpacing: boardSpacer,
                children: List.generate(numBoards ~/ 2,
                    (index) => gameboardWidget(numBoards ~/ 2 + index)),
              ),
            ],
          ),
          const Divider(
            color: Colors.transparent,
            height: dividerHeight,
          ),
          keyboardRowWidget(0, 10, onKeyboardTapped),
          keyboardRowWidget(10, 9, onKeyboardTapped),
          keyboardRowWidget(20, 9, onKeyboardTapped)
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
