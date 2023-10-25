// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/secrets.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> gSignIn() async {
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

Future<void> gSignOut() async {
  if (debugFakeLogin) {
  } else {
    await googleSignIn.disconnect();
  }
  gUser = gUserDefault;
  await save.saveUser();
  game.resetBoard(true);
  await save.loadKeys();
}
