import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_structure.dart';
import 'game_logic.dart';
import 'helper.dart';
import 'saves.dart';
//gID defined in secrets.dart, not included in repo
//in format XXXXXX.apps.googleusercontent.com
import 'secrets.dart';
import 'src/sign_in_button.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
//typedef HandleSignInFn = Future<void> Function();

const bool _debugFakeLogin = false;
const String _gUserFakeLogin = "joebloggs@gmail.com";

final gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

Widget lockStyleSignInButton(BuildContext context) {
  return IconButton(
    iconSize: 25,
    icon: const Icon(Icons.lock_outlined),
    onPressed: () {
      g.signInDirectly(); //signInSilentlyThenDirectly();
      try {
        Navigator.pop(context, 'OK');
        focusNode.requestFocus();
      } catch (e) {
        debug(["No pop", e]);
      }
    },
  );
}

class G {
  G({required this.game});

  final Game game;

  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  static const String gUserDefault = "JoeBloggs";
  static const String gUserIconDefault = "JoeBloggs";

  GoogleSignInAccount? _user;

  ValueNotifier<String> gUserNotifier = ValueNotifier("JoeBloggs");
  String _gUserIcon = "JoeBloggs";

  void startGoogleAccountChangeListener() {
    if (gOn) {
      googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        _user = account;
        if (_user != null) {
          debug(["login successful", _user]);
          _successfulLoginExtractDetails();
        } else {
          debug(["logout"]);
          _logoutExtractDetails();
        }
      });
    }
  }

  void signInSilently() async {
    if (gOn) {
      await googleSignIn.signInSilently();
      _successfulLoginExtractDetails();
    }
  }

  Future<void> signInDirectly() async {
    debug("webSignIn()");
    if (gOn) {
      try {
        if (_debugFakeLogin) {
          _debugLoginExtractDetails();
        } else {
          await googleSignIn.signIn();
          _successfulLoginExtractDetails();
        }
      } catch (e) {
        debug(["signInDirectly", e]);
      }
    }
  }

  Future<void> signOut() async {
    if (gOn) {
      if (_debugFakeLogin) {
      } else {
        try {
          await googleSignIn.disconnect();
          _logoutExtractDetails();
        } catch (e) {
          debug(["signOut", e]);
        }
      }
      //logoutExtractDetails(); //now handled by listener
    }
  }

  Future<void> signInSilentlyThenDirectly() async {
    debug("mobileSignIn()");
    if (gOn) {
      if (_debugFakeLogin) {
        _debugLoginExtractDetails();
      } else {
        await googleSignIn.signInSilently();
        _user = googleSignIn.currentUser;

        if (_user == null) {
          //if sign in silently didn't work
          await googleSignIn.signIn();
          _user = googleSignIn.currentUser;
        }
        _successfulLoginExtractDetails();
      }
    }
  }

  void _successfulLoginExtractDetails() async {
    if (_user != null) {
      debug("login extract details");
      gUser = _user!.email;
      if (_user!.photoUrl != null) {
        gUserIcon = _user!.photoUrl ?? gUserIconDefault;
      }
      await save.saveUser();
      await save.loadKeys();
    }
  }

  void _debugLoginExtractDetails() async {
    debug("debugLoginExtractDetails");
    assert(_debugFakeLogin);
    gUser = _gUserFakeLogin;
    await save.saveUser();
    await save.loadKeys();
  }

  void _logoutExtractDetails() async {
    debug("logout extract details");
    gUser = gUserDefault;
    await save.saveUser();
    game.resetBoard();
    await save.loadKeys();
  }

  Future<void> signOutAndExtractDetails() async {
    debug("sign out and extract details");
    if (gOn) {
      await signOut();
      _logoutExtractDetails();
    }
  }

  Widget platformAdaptiveSignInButton(BuildContext context) {
    // different buttons depending on web or mobile. See sign_in_button folder
    return buildSignInButton(
        onPressed:
            signInDirectly, //relevant on web only, else uses separate code
        context: context);
  }

  bool get signedIn => gUser != gUserDefault;

  String get gUser => gUserNotifier.value;

  String get gUserIcon => _gUserIcon;

  set gUser(g) => gUserNotifier.value = g;

  set gUserIcon(gui) => _gUserIcon = gui;
}

final G g = G(game: game);
