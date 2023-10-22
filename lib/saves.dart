import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/game_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Save {
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    gUser = prefs.getString('gUser') ?? gUserDefault;
    gUserIcon = prefs.getString('gUserIcon') ?? gUserIconDefault;
    p(["loadUser", gUser, gUserIcon]);
  }

  Future<void> saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', gUser);
    await prefs.setString('gUserIcon', gUserIcon);
    p(["saveUser", gUser, gUserIcon]);
  }

  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    String gameEncoded = "";

    if (gUser == gUserDefault) {
      //load from local save
      gameEncoded = prefs.getString('game') ?? "";
    } else {
      //load from firebase
      gameEncoded = "";
      final docRef = db.collection("states").doc(gUser);
      await docRef.get().then(
        (DocumentSnapshot doc) {
          final gameEncodedTmp = doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        // ignore: avoid_print
        onError: (e) => print("Error getting document: $e"),
      );
    }
    game.loadFromEncodedState(gameEncoded);
    //var ss = globalFunctions[0];
    ss(); //GLOBALSS
  }

  Future<void> saveKeys() async {
    saveOrLoadKeysCountCache++;
    String gameEncoded = game.getEncodeCurrentGameState();
    //p(["SAVE keys",gameEncoded]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('game', gameEncoded);

    firebasePush(gameEncoded);
  }

  Future<void> firebasePush(state) async {
    if (gUser != gUserDefault) {
      // Create a new user with a first and last name
      final dhState = <String, dynamic>{"data": state};
      db
          .collection("states")
          .doc(gUser)
          .set(dhState)
          // ignore: avoid_print
          .onError((e, _) => print("Error writing document: $e"));
    }
  }

  String firebasePull(snapshot) {
    String snapshotCurrent = "";
    snapshot.data!.docs
        .map((DocumentSnapshot document) {
          if (document.id == gUser) {
            Map<String, dynamic> dataTmpQ =
                document.data() as Map<String, dynamic>;
            snapshotCurrent = dataTmpQ["data"].toString();
            return null;
          }
        })
        .toList()
        .cast();
    return snapshotCurrent;
  }
}

Save save = Save();
