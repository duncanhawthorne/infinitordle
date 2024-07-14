import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'secrets.dart';
import 'wordlist.dart';

//Debug
const bool cheatMode = false;

//Branding
const String appTitle = "infinitordle";
const String appTitle1 = cheatMode ? "cheat" : "infinit";
const String appTitle3 = "rdle";

const bg = Color(0xff222222);
const grey = Color(0xff555555);
const white = Colors.white;
const green = Colors.green;
const amber = Colors.amber;
const red = Colors.red;
const transp = Colors.transparent;

//Game design
const numBoards = 4; //must be divisible by 2
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
const cols = 5; //number of letters in a word
const bool infMode = true;
const double boardSpacer = 8;

//Helper text
const keyboardList = kKbdList;

//Animations
const _noAnimations = false;
const _slowDownFactor = cheatMode ? 1 : 1;
const int _durMult = _noAnimations ? 0 : 1 * _slowDownFactor;
const int delayMult = _noAnimations ? 0 : 1 * _slowDownFactor;
const gradualRevealDelayTime = delayMult * 150;
const slideTime = _durMult * 200;
const flipTime = _durMult * 500;

//Screen constants
const double dividerHeight = 2;

final fbOn = firebaseOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
final fbAnalytics = fbOn && true;
final gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

FirebaseFirestore? db = fbOn ? FirebaseFirestore.instance : null;
FirebaseAnalytics? analytics = fbAnalytics ? FirebaseAnalytics.instance : null;

//Global functions
Function? ssFunction;
Function? showResetScreenFunction;

void setStateGlobal() {
  //Hack to make these functions available globally
  ssFunction!();
}

void showResetConfirmScreen() {
  //Hack to make these functions available globally
  showResetScreenFunction!();
}
