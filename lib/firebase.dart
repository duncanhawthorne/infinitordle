import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'helper.dart';
import 'saves.dart';

class FireBase {
  List<String> recentSnapshotsCache = [];

  void load(AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (fbOn) {
      if (snapshot.hasError || !snapshot.hasData) {
      } else if (snapshot.connectionState == ConnectionState.waiting) {
      } else {
        DocumentSnapshot<Object?>? userDocument = snapshot.data;
        if (userDocument != null && userDocument.exists) {
          String snapshotCurrent = userDocument["data"];
          if (g.signedIn && !recentSnapshotsCache.contains(snapshotCurrent)) {
            if (snapshotCurrent != game.getEncodeCurrentGameState()) {
              game.loadFromEncodedState(snapshotCurrent, false);
            }
            recentSnapshotsCache.add(snapshotCurrent);
            if (recentSnapshotsCache.length > 5) {
              recentSnapshotsCache.removeAt(0);
            }
          }
        }
      }
    }
  }
}
