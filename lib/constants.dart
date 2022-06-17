import 'package:flutter/material.dart';
import 'dart:math';
import 'package:infinitordle/wordlist.dart';
import 'package:flutter/foundation.dart';

//Debug
bool cheatMode = true;

//Branding
String appTitle = "infinitordle";
String appTitle1 = "infinit";
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
final keyboardList = "qwertyuiopasdfghjkl <zxcvbnm >".split("");
const cheatString = "";//"""maplewindyscourfightkebab";
const cheatWords = ["scoff", "brunt", "armor", "tabby"];
final legalWords = kLegalWordsText.split("\n");
final finalWords = kFinalWordsText.split("\n");

//Device support
final isWebMobileReal = kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
final noAnimations = true && isWebMobileReal;
final int durMult = noAnimations ? 0 : 1;

//Effectively the state of the game
var targetWords = []; //gets overridden by loadKeys()
var gameboardEntries = List<String>.generate((numRowsPerBoard * 5), (i) => "");
int currentWord = -1; //gets overridden by initState()
int typeCountInWord = 0;
final List<String> infSuccessWords = [];
final infSuccessBoardsMatchingWords = [];

//Visual the state of the game
var angles = List<double>.generate((numRowsPerBoard * 5 * numBoards), (i) => 0);

//Helpers for state of the game
bool oneLegalWordForRedCardsCache = false;
bool oneMatchingWordForResetScreenCache = false;
bool onStreakForKeyboardIndicatorCache = false;
var cardColorsCache = [];
var keyColorsCache = [];
bool backspaceSafe = true;

//Screen constants
const double keyboardSingleKeyUnconstrainedMaxPixel = 80;
double vertSpaceForGameboard = -1;
double vertSpaceForCardNoWrap = -1;
double horizSpaceForCardNoWrap = -1;
int numPresentationBigRowsOfBoards = -1;
double cardEffectiveMaxPixel = -1;
double scW = -1; //default value only
double scH = -1; //default value only
double vertSpaceAfterTitle = -1; //default value only
double keyboardSingleKeyEffectiveMaxPixel = -1; //default value only

//Misc
Random random = Random();
int lastTimePressedDelete = DateTime.now().millisecondsSinceEpoch;
