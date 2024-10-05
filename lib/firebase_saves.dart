import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'google/google.dart';
import 'helper.dart';

final fbOn = firebaseOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);
final fbAnalytics = fbOn && true;

FirebaseFirestore? db = fbOn ? FirebaseFirestore.instance : null;
FirebaseAnalytics? analytics = fbAnalytics ? FirebaseAnalytics.instance : null;

class FBase {
  Future<void> firebasePush(G g, state) async {
    if (fbOn && g.signedIn) {
      final dhState = <String, dynamic>{"data": state};
      db!
          .collection("states")
          .doc(g.gUser)
          .set(dhState)
          .onError((e, _) => debug("Error writing document: $e"));
    }
  }

  Future<String> firebasePull(G g) async {
    String gameEncoded = "";
    if (fbOn && g.signedIn) {
      final docRef = db!.collection("states").doc(g.gUser);
      await docRef.get().then(
        (DocumentSnapshot doc) {
          final gameEncodedTmp = doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (e) => debug("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }
}

final FBase fBase = FBase();
