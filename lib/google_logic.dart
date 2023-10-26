// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/secrets.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Google {
  var gUser = "JoeBloggs";
  var gUserIcon = "JoeBloggs";

  bool signedIn() {
    return gUser != gUserDefault;
  }

  String getUser() {
    return gUser;
  }

  void setUser(g) {
    gUser = g;
  }

  String getUserIcon() {
    return gUserIcon;
  }

  void setUserIcon(gui) {
    gUserIcon = gui;
  }

  Future<void> signIn() async {
    //var ss = globalFunctions[0];
    p("gSignIn()");

    GoogleSignInAccount? user;

    await googleSignIn.signInSilently();
    user = googleSignIn.currentUser;

    if (user == null) {
      //if sign in silently didn't work
      await googleSignIn.signIn(); //
      user = googleSignIn.currentUser;
    }

    if (user != null) {
      gUser = user.email;
      if (user.photoUrl != null) {
        gUserIcon = user.photoUrl ?? gUserIconDefault;
      }
      await save.saveUser();
      await save.loadKeys();
    }
    ss();
  }

  Future<void> signOut() async {
    if (debugFakeLogin) {
    } else {
      await googleSignIn.disconnect();
    }
    gUser = gUserDefault;
    await save.saveUser();
    game.resetBoard(true);
    await save.loadKeys();
  }
}

Google g = Google();
