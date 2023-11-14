import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:infinitordle/wordlist.dart';

//Debug
const bool cheatMode = false;

//Branding
const String appTitle = "infinitordle";
const String appTitle1 = cheatMode ? "cheat" : "infinit";
const String appTitle3 = "rdle";
const bg = Color(0xff222222);
const grey = Color(0xff555555);
const offWhite = Color(0xff999999);
const amber = Colors.amber;
const green = Colors.green;

//Game design
const numBoards = 4; //must be divisible by 2
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
const cols = 5; //number of letters in a word
const bool infMode = true;
const infNumBacksteps = 1;
const double boardSpacer = 8;

//Helper text
final keyboardList = "qwertyuiopasdfghjkl <zxcvbnm> ".split("");
const cheatEnteredWordsInitial = ["maple", "windy", "scour", "fight", "kebab"];
const cheatTargetWordsInitial = ["scoff", "brunt", "armor", "tabby"];
final legalWords = kLegalWordsText.split("\n");
final finalWords = kFinalWordsText.split("\n");

//Device support
final isWebMobileReal = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
const noAnimations = false;
const slowDownFactor = 1;
const int durMult = noAnimations ? 0 : 1 * slowDownFactor;
const int delayMult = noAnimations ? 0 : 1 * slowDownFactor;
const gradualRevealDelay = delayMult * 150;
const slideTime = durMult * 200;
const flipTime = durMult * 500;
const gradualRevealRowTime = gradualRevealDelay * (cols - 1) + flipTime;
const visualCatchUpTime = delayMult * 750;

//Screen constants
const double dividerHeight = 2;
const double keyAspectRatioDefault = 1.5;

const bool debugFakeLogin = false;
const String gUserDefault = "JoeBloggs";
const String gUserIconDefault = "JoeBloggs";

const m3 = true;

FirebaseFirestore db = FirebaseFirestore.instance;
FirebaseAnalytics analytics = FirebaseAnalytics.instance;

//Misc
final Random random = Random();

var ssFunctionList = [];
var showResetScreenFunctionList = [];

void ss() {
  //Hack to make these functions available globally
  ssFunctionList[0]();
}

void showResetConfirmScreen() {
  //Hack to make these functions available globally
  showResetScreenFunctionList[0]();
}
