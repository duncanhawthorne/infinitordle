import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'helper.dart';

class Save {
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    g.gUser = prefs.getString('gUser') ?? gUserDefault;
    g.gUserIcon = prefs.getString('gUserIcon') ?? gUserIconDefault;
    if (g.gUserIcon != gUserIconDefault) {
      NetworkImage(g.gUserIcon); //pre-load
    }
    p(["loadUser", g.gUser, g.gUserIcon]);
  }

  Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', g.gUser);
    await prefs.setString('gUserIcon', g.gUserIcon);
    p(["saveUser", g.gUser, g.gUserIcon]);
  }

  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (!fbOn || !g.signedIn) {
      // load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      // load from firebase
      gameEncoded = await firebasePull();
    }
    game.loadFromEncodedState(gameEncoded, true);
  }

  Future<void> saveKeys() async {
    String gameEncoded = game.getEncodeCurrentGameState();

    // save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    // if possible save to firebase
    if (fbOn && g.signedIn) {
      firebasePush(gameEncoded);
    }
  }

  Future<void> firebasePush(state) async {
    if (fbOn && g.signedIn) {
      final dhState = <String, dynamic>{"data": state};
      db!
          .collection("states")
          .doc(g.gUser)
          .set(dhState)
          .onError((e, _) => p("Error writing document: $e"));
    }
  }

  Future<String> firebasePull() async {
    String gameEncoded = "";
    if (fbOn && g.signedIn) {
      final docRef = db!.collection("states").doc(g.gUser);
      await docRef.get().then(
        (DocumentSnapshot doc) {
          final gameEncodedTmp = doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (e) => p("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }
}
