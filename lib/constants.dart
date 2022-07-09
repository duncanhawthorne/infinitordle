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
const Color bg = Color(0xff222222);
const grey = Color(0xff555555);

//Game design
const numBoards = 4;
const numRowsPerBoard = 8; // originally 5 + number of boards, i.e. 9
bool infMode = true;
const infNumBacksteps = 1;
const double boardSpacer = 8;

//Helper text
final keyboardList = "qwertyuiopasdfghjkl <zxcvbnm> ".split("");
//final keyboardList = "mapresc<>".split("");
const cheatString = "maplewindyscourfightkebab";
const cheatWords = ["scoff", "brunt", "armor", "tabby"];
final legalWords = kLegalWordsText.split("\n");
final finalWords = kFinalWordsText.split("\n");

//Device support
final isWebMobileReal = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
final noAnimations = true && isWebMobileReal;
final int durMult = noAnimations ? 0 : 1;
final int delayMult = noAnimations ? 1 : 1;

//Effectively the state of the game
var targetWords = []; //gets overridden by loadKeys()
var gameboardEntries =
    []; //List<String>.generate((numRowsPerBoard * 5), (i) => "");
int currentWord = -1; //gets overridden by initState()
int typeCountInWord = 0;
var infSuccessWords = [];
var infSuccessBoardsMatchingWords = [];
Map<String, dynamic> game = {};

//Visual state of the game
var angles = List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);

//Helpers for state of the game
bool oneLegalWordForRedCardsCache = false;
bool oneMatchingWordForResetScreenCache = false;
bool onStreakForKeyboardIndicatorCache = false;
var cardColorsCache = [];
var keyColorsCache = [];
bool backspaceSafe = true;

//Screen constants
const double keyboardSingleKeyUnconstrainedMaxPixelHeight = 80;
double vertSpaceForGameboard = -1;
double vertSpaceForCardNoWrap = -1;
double horizSpaceForCardNoWrap = -1;
int numPresentationBigRowsOfBoards = -1;
double cardEffectiveMaxPixel = -1;
double scW = -1; //default value only
double scH = -1; //default value only
double vertSpaceAfterTitle = -1; //default value only
double keyboardSingleKeyEffectiveMaxPixelHeight = -1; //default value only
const double dividerHeight = 2;
double appBarHeight = 56;
double keyAspectRatioDefault = 1.5;
double keyAspectRatioLive = -1;

//Misc
Random random = Random();
//int lastTimePressedDelete = DateTime.now().millisecondsSinceEpoch;

var gUserDefault = "JoeBloggs";
var gUser = "JoeBloggs";

var db = FirebaseFirestore.instance;
String gameEncodedLast = "";
String snapshotLast = "XXXXXXX";

bool fakeLogin = false;
int oneStepState = 0;

Stream<QuerySnapshot> usersStream = db.collection('states').snapshots();

var globalFunctions = [];
