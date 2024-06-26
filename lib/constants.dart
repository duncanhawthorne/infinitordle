import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinitordle/firebase_options.dart';
import 'package:infinitordle/secrets.dart';
import 'package:infinitordle/wordlist.dart';

//Debug
const bool cheatMode = false;
const bool newLoginButtons = false;

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
const dgreen = Color(0xff61B063);
const damber = Color(0xffFFCF40);
const dred = Color(0xffF55549);
const offWhite = Color(0xff939393);
const transp = Colors.transparent;
final Map colorMap = {
  green: dgreen,
  amber: damber,
  red: dred,
  white: offWhite,
  //grey: grey
  bg: transp,
};

final List colorsList = [
  red,
  amber,
  green,
  grey,
  transp,
  dgreen,
  damber,
  dred,
  offWhite,
  white,
  grey
];
final List cardColorsList = [
  red,
  amber,
  green,
  grey,
  transp,
  dgreen,
  damber,
  dred
];
final List kbColorsList = [red, amber, green, grey, transp];
final List borderColorsList = [green, dgreen, transp];

//Game design
const numBoards = 4; //must be divisible by 2
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
const cols = 5; //number of letters in a word
const bool infMode = true;
const infNumBacksteps = 1;
const double boardSpacer = 8;

//Helper text
const keyboardList = kKbdList;
const cheatEnteredWordsInitial = ["maple", "windy", "scour", "fight", "kebab"];
const cheatTargetWordsInitial = ["scoff", "brunt", "armor", "tabby"];
const legalWords = kLegalWordsList;
const winnableWords = kWinnableWordsList;

//Device support
final isWebMobileReal = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
const noAnimations = false;
const slowDownFactor = cheatMode ? 1 : 1;
const int durMult = noAnimations ? 0 : 1 * slowDownFactor;
const int delayMult = noAnimations ? 0 : 1 * slowDownFactor;
const gradualRevealDelayTime = delayMult * 150;
const slideTime = durMult * 200;
const flipTime = durMult * 500;
const renderTwoFramesTime = delayMult *
    33; // so that set state and animations don't happen exactly simultaneously
const gradualRevealRowTime = gradualRevealDelayTime * (cols - 1) + flipTime;
const visualCatchUpTime = delayMult * 750;

//Screen constants
const double dividerHeight = 2;
const double keyAspectRatioDefault = 1.5;
const double notionalCardSize = 1.0;

const bool debugFakeLogin = false;
const String gUserFakeLogin = "joebloggs@gmail.com";
const String gUserDefault = "JoeBloggs";
const String gUserIconDefault = "JoeBloggs";
final fbOn = firebaseOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
final fbAnalytics = fbOn && true;
final gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
const m3 = true;

FirebaseFirestore? db = fbOn ? FirebaseFirestore.instance : null;
FirebaseAnalytics? analytics = fbAnalytics ? FirebaseAnalytics.instance : null;

//Misc
final Random random = Random();

var ssFunctionList = [];
var showResetScreenFunctionList = [];

void setStateGlobal() {
  //Hack to make these functions available globally
  ssFunctionList[0]();
}

void showResetConfirmScreen() {
  //Hack to make these functions available globally
  showResetScreenFunctionList[0]();
}
