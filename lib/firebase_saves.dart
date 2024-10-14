import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'google/google.dart';
import 'helper.dart';

final bool fbOn = firebaseOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
final bool fbAnalytics = fbOn && true;

FirebaseFirestore? db = fbOn ? FirebaseFirestore.instance : null;
FirebaseAnalytics? analytics = fbAnalytics ? FirebaseAnalytics.instance : null;

class FBase {
  Future<void> firebasePush(G g, dynamic state) async {
    if (fbOn && g.signedIn) {
      final Map<String, dynamic> dhState = <String, dynamic>{"data": state};
      unawaited(db!
          .collection("states")
          .doc(g.gUser)
          .set(dhState)
          .onError((Object? e, _) => debug("Error writing document: $e")));
    }
  }

  Future<String> firebasePull(G g) async {
    String gameEncoded = "";
    if (fbOn && g.signedIn) {
      final DocumentReference<Map<String, dynamic>> docRef =
          db!.collection("states").doc(g.gUser);
      await docRef.get().then(
        // ignore: always_specify_types
        (DocumentSnapshot doc) {
          final Map<String, dynamic> gameEncodedTmp =
              doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (dynamic e) => debug("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }
}

final FBase fBase = FBase();
