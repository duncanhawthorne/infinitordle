import 'dart:math';
import 'package:infinitordle/wordlist.dart';

Random random = Random();
final _finalWords = kFinalWordsText.split("\n");

List getTargetWords(numberOfBoards) {
  var starterList = [];
  for (var i = 0; i < numberOfBoards; i++) {
    starterList.add(getTargetWord());
  }
  return starterList;
}

String getTargetWord() {
  return _finalWords[random.nextInt(_finalWords.length)];
}

