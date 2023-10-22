import 'package:flutter/material.dart';
import 'dart:math';
import 'package:infinitordle/wordlist.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Debug
const bool cheatMode = false; //

//Branding
String appTitle = "infinitordle";
String appTitle1 = cheatMode ? "cheat" : "infinit";
String appTitle3 = "rdle";
const bg = Color(0xff222222);
const grey = Color(0xff555555);
const offWhite = Color(0xff999999);
const amber = Colors.amber;
const green = Colors.green;

//Game design
const numBoards = 4;
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
bool infMode = true;
const infNumBacksteps = 1;
const double boardSpacer = 8;
bool expandingBoard = false; //true;

//Helper text
final keyboardList = "qwertyuiopasdfghjkl <zxcvbnm> ".split("");
//final keyboardList = "mapresc<>".split("");
var cheatEnteredWordsInitial = ["maple", "windy", "scour", "fight", "kebab"];
const cheatTargetWordsInitial = ["scoff", "brunt", "armor", "tabby"];
final legalWords = kLegalWordsText.split("\n");
final finalWords = kFinalWordsText.split("\n");

//Device support
final isWebMobileReal = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
final isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
final noAnimations = true && isWebMobileReal;
final int durMult = noAnimations ? 1 : 1;
final int delayMult = noAnimations ? 1 : 1;
final gradualRevealDelay = delayMult * (durMult == 1 ? 100 : 250);

//Visual state of the game
int temporaryVisualOffsetForSlide = 0;
var highlightedBoard = -1;

//Volatile helpers for state of the game
int saveOrLoadKeysCountCache = 0;
bool oneLegalWordForRedCardsCache = false;
String legalWordTestedWordCache = "";
bool backspaceSafeCache = true;

//Screen constants
const double dividerHeight = 2;
const double keyAspectRatioDefault = 1.5;

//Volatile default values for sizing
double vertSpaceForGameboard = -1;
double vertSpaceForCardWithWrap = -1;
double horizSpaceForCardNoWrap = -1;
int numPresentationBigRowsOfBoards = -1;
double cardLiveMaxPixel = -1;
double scW = -1;
double scH = -1;
double vertSpaceAfterTitle = -1;
double keyboardSingleKeyLiveMaxPixelHeight = -1;
double appBarHeight = -1;
double keyAspectRatioLive = -1;

bool debugFakeLogin = false;
var gUserDefault = "JoeBloggs";
var gUser = "JoeBloggs";
var gUserIconDefault = "JoeBloggs";
var gUserIcon = "JoeBloggs";

var db = FirebaseFirestore.instance;
String gameEncodedLast = "";
String snapshotLast = "XXXXXXX";

//Misc
Random random = Random();
var globalFunctions = [];

void ss() {
  globalFunctions[0]();
}

void showResetConfirmScreen() {
  globalFunctions[1]();
}
