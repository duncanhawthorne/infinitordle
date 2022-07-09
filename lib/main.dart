// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:infinitordle/google_logic.dart';
import 'package:infinitordle/app_structure.dart';

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
  @override
  initState() {
    super.initState();
    //fbInit();
    resetBoardReal(false);
    loadUser();
    initalSignIn();
    loadKeys();
    globalFunctions.add(ss);
    globalFunctions.add(showResetConfirmScreen);

    usersStream = db.collection('states').snapshots();

    setState(() {});
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: 1000 * i), () {
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
    final GoogleSignInAccount? user = currentUser;
    // ignore: avoid_print
    print([user, gUser]);
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
                      gUser == gUserDefault ? handleSignIn() : handleSignOut();
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
                resetBoardReal(true),
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
}
