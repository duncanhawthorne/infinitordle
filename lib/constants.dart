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
const amber = Colors.amber;
const green = Colors.green;

//Game design
const numBoards = 4;
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
bool infMode = true;
const infNumBacksteps = 1;
const double boardSpacer = 8;

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
final noAnimations = true && isWebMobileReal;
final int durMult = noAnimations ? 1 : 1;
final int delayMult = noAnimations ? 1 : 1;

//Effectively the state of the game
var targetWords = []; //gets overridden by loadKeys()
var enteredWords = [];
var winRecordBoards = [];
var currentTyping = "";
int offsetRollback = 0;

//Visual state of the game
var cardFlipAngles = List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);
int visualOffset = 0;

//Helpers for state of the game
int saveOrLoadKeysCountCache = 0;
bool oneLegalWordForRedCardsCache = false;
String legalWordTestedWordCache = "";
bool aboutToWinCache = false;
var cardColorsCache = [];
var keyColorsCache = [];
int keyAndCardColorsTestedStateCache = 0;
bool backspaceSafeCache = true;
bool onStreakCache = false;
int onStreakTestedStateCache = 0;

//Screen constants
//const double keyboardSingleKeyUnconstrainedMaxPixelHeight = 80;
const double dividerHeight = 2;
double keyAspectRatioDefault = 1.5;

//default values for sizing
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

var db = FirebaseFirestore.instance;
String gameEncodedLast = "";
String snapshotLast = "XXXXXXX";
//Stream<QuerySnapshot> usersStream = db.collection('states').snapshots();

//Misc
Random random = Random();
var globalFunctions = [];