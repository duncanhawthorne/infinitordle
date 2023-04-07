// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:infinitordle/helper.dart';
import 'package:infinitordle/constants.dart';
import 'package:infinitordle/secrets.dart';
import 'package:google_sign_in/google_sign_in.dart';

//GoogleSignInAccount? currentUser;

Future<void> gSignIn() async {
  var ss = globalFunctions[0];
  p("gSignIn()");

  GoogleSignInAccount? user;

  /*
  if (true || !isiOSMobile) {
    // ignore: unused_local_variable
    await googleSignIn.signInSilently();
    user = googleSignIn.currentUser;
    /*
    p(googleSignIn);
    p(googleSignInAccount);
    GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount!.authentication;
    p(googleSignInAuthentication);
    p(googleSignInAuthentication!.idToken);
     */
  }
  //// await googleSignIn.signIn(); //

   */

  await googleSignIn.signInSilently();
  user = googleSignIn.currentUser;

  if (user == null) {
    await googleSignIn.signIn(); //
    user = googleSignIn.currentUser;
  }

  if (user != null) {
    gUser = user.email;
    if (user.photoUrl != null) {
      gUserIcon = user.photoUrl ?? gUserIconDefault;
    }
    //currentUser = user;
    await saveUser();
    await loadKeys();
  }
  ss();
}

Future<void> gSignOut() async {
  if (debugFakeLogin) {
  } else {
    await googleSignIn.disconnect();
  }
  gUser = gUserDefault;
  await saveUser();
  resetBoard(true);
  await loadKeys();
}
