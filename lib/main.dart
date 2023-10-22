// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:infinitordle/google_logic.dart';
import 'package:infinitordle/app_structure.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:infinitordle/game_logic.dart';
import 'package:infinitordle/saves.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Future.delayed(const Duration(milliseconds: 1000 * 5), () {
    FlutterNativeSplash
        .remove(); //Hack, but makes sure removed shortly after starting
  });

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
        useMaterial3: false,
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
    //fbInit();
    game.resetBoard(false);
    save.loadUser();
    save.loadKeys();
    globalFunctions.add(ss);
    globalFunctions.add(showResetConfirmScreen);

    //usersStream = db.collection('states').snapshots();

    setState(() {});
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: 1000 * i), () {
        fixTitle();
        setState(
            () {}); //Hack, but makes sure state set right shortly after starting
      });
    }
  }

  void ss() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    detectAndUpdateForScreenSize(context);

    return streamBuilderWrapperOnDocument();
  }

  Widget streamBuilderWrapperOnDocument() {
    if (gUser == gUserDefault) {
      return _scaffold();
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
              if (gUser != gUserDefault && snapshotCurrent != snapshotLast) {
                if (snapshotCurrent != game.getEncodeCurrentGameState()) {
                  game.loadFromEncodedState(snapshotCurrent);
                }
                snapshotLast = snapshotCurrent;
              }
            }
          }
          return _scaffold();
        },
      );
    }
  }

  Widget _scaffold() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: appBarHeight,
        title: _titleWidget(),
      ),
      body: bodyWidget(),
    );
  }

  Widget _titleWidget() {
    int numberWinsCache = game.getWinWords().length;
    var infText = numberWinsCache == 0
        ? "o"
        : "∞" * (numberWinsCache ~/ 2) + "o" * (numberWinsCache % 2);
    //String extra = isStreak() ? "🔥" : "";
    return GestureDetector(
        onTap: () {
          showResetConfirmScreen();
        },
        child: FittedBox(
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
                        color: numberWinsCache == 0 ? Colors.white : green)),
                TextSpan(text: appTitle3),
              ],
            ),
          ),
        ));
  }

  Future<void> showResetConfirmScreen() async {
    List winWordsCache = game.getWinWords();
    int numberWinsCache = winWordsCache.length;
    bool end = false;
    if (!game.getAboutToWinCache() && game.getVisualCurrentRowInt() >= numRowsPerBoard) {
      end = true;
    }
    //var _helperText =  "Solve 4 boards at once. \n\nWhen you solve a board, the target word will be changed, and you get an extra guess.\n\nCan you keep going forever and reach infinitordle?\n\n";

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
                      if (gUser == gUserDefault) {
                        gSignIn();
                        Navigator.pop(context, 'OK');
                      } else {
                        showLogoutConfirmationScreen(context);
                      }
                      focusNode.requestFocus();
                    });
                  },
                  child: gUser == gUserDefault
                      ? const Icon(Icons.person_off, color: bg)
                      : gUserIcon == gUserIconDefault
                          ? const Icon(Icons.face, color: bg)
                          : CircleAvatar(
                              backgroundImage: NetworkImage(
                                  gUserIcon)) //  GoogleUserCircleAvatar(identity: currentUser)
                  )
            ],
          ),
          content: Text(end
              ? "You got " +
                  numberWinsCache.toString() +
                  " word" +
                  (numberWinsCache == 1 ? "" : "s") +
                  ": " +
                  winWordsCache.join(", ") +
                  "\n\nYou missed: " +
                  game.targetWords.join(", ") +
                  "\n\nReset the board?"
              : "You've got " +
                  numberWinsCache.toString() +
                  " word" +
                  (numberWinsCache == 1 ? "" : "s") +
                  ' so far' +
                  (numberWinsCache != 0 ? ":" : "") +
                  ' ' +
                  winWordsCache.join(", ") +
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
                game.resetBoard(true),
                focusNode.requestFocus(),
                Navigator.pop(context, 'OK'),
                setState(() {})
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showLogoutConfirmationScreen(context) async {
    //Navigator.pop(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Do you want to log out?"),
          content: Text("Logged in as " + gUser),
          actions: <Widget>[
            TextButton(
              onPressed: () => {Navigator.pop(context, 'Cancel')},
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => {
                gSignOut(),
                Navigator.pop(context, 'OK'),
                Navigator.pop(context, 'OK'),
                setState(() {})
              },
              child: const Text('Log out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
