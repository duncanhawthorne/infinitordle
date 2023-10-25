import 'package:flutter/material.dart';
import 'dart:math';
import 'package:infinitordle/wordlist.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Debug
const bool cheatMode = false; //

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
const numBoards = 4;
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
const bool infMode = true;
const infNumBacksteps = 1;
const double boardSpacer = 8;

//Helper text
final keyboardList = "qwertyuiopasdfghjkl <zxcvbnm> ".split("");
//final keyboardList = "mapresc<>".split("");
const cheatEnteredWordsInitial = ["maple", "windy", "scour", "fight", "kebab"];
const cheatTargetWordsInitial = ["scoff", "brunt", "armor", "tabby"];
final legalWords = kLegalWordsText.split("\n");
final finalWords = kFinalWordsText.split("\n");

//Device support
final isWebMobileReal = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
const noAnimations = false; //guc true && isWebMobileReal;
const int durMult = noAnimations ? 0 : 1;
const int delayMult = noAnimations ? 0 : 1;
const gradualRevealDelay = delayMult * (durMult == 1 ? 100 : 250);
//int flipTimeOverrideFactor = 1;

//Screen constants
const double dividerHeight = 2;
const double keyAspectRatioDefault = 1.5;

const bool debugFakeLogin = false;
const String gUserDefault = "JoeBloggs";
const String gUserIconDefault = "JoeBloggs";

FirebaseFirestore db = FirebaseFirestore.instance;

//Misc
final Random random = Random();
var globalFunctions = [];

void ss() {
  globalFunctions[0]();
}

void showResetConfirmScreen() {
  globalFunctions[1]();
}


