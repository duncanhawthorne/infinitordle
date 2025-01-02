import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'firebase_options.dart';
import 'google/google.dart';
import 'helper.dart';

final bool firebaseOn = firebaseOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
final bool fbAnalytics = firebaseOn && true;

FirebaseAnalytics? analytics;

class FBase {
  static final Logger _log = Logger('FB');

  FirebaseFirestore? get db => _db;
  FirebaseFirestore? _db;

  Future<void> initialize() async {
    if (firebaseOn) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (fbAnalytics) {
        analytics = FirebaseAnalytics.instance;
      }
      _db = FirebaseFirestore.instance;
    } else {
      _log.info("Off");
    }
  }

  Future<void> firebasePush(G g, dynamic state) async {
    if (firebaseOn && g.signedIn) {
      final Map<String, dynamic> dhState = <String, dynamic>{"data": state};
      unawaited(_db!
          .collection("states")
          .doc(g.gUser)
          .set(dhState)
          .onError((Object? e, _) => logGlobal("Error writing document: $e")));
    }
  }

  Future<String> firebasePull(G g) async {
    String gameEncoded = "";
    if (firebaseOn && g.signedIn) {
      final DocumentReference<Map<String, dynamic>> docRef =
          _db!.collection("states").doc(g.gUser);
      await docRef.get().then(
        // ignore: always_specify_types
        (DocumentSnapshot doc) {
          final Map<String, dynamic> gameEncodedTmp =
              doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (dynamic e) => logGlobal("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }
}

final FBase fBase = FBase();
