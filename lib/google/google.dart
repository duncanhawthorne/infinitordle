import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_structure.dart';
import '../constants.dart';
import '../google/src/sign_in_button/mobile.dart';
import '../helper.dart';
import 'secrets.dart';

/// The type of the onClick callback for the (mobile) Sign In Button.
//typedef HandleSignInFn = Future<void> Function();

const bool _debugFakeLogin = false;
const String _gUserFakeLogin = "joebloggs@gmail.com";

final gOn = googleOnReal &&
    !(defaultTargetPlatform == TargetPlatform.windows && !kIsWeb);

class G {
  G() {
    _startGoogleAccountChangeListener();
    _loadUser();
  }

  static const bool _newLoginButtons = false;

  void forceResetUserTo(String x) {
    debug("force reset");
    _gUser = x;
    _saveUserToFilesystem(gUser, _gUserIcon);
  }

  Widget signInRow(BuildContext context) {
    if (gOn) {
      StreamSubscription? subscription;
      subscription = g.googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        subscription!.cancel(); //FIXME doesn't work
        debug("subscription fire");
        if (account != null) {
          //login
          try {
            // ignore: use_build_context_synchronously
            if (Navigator.canPop(context)) {
              // ignore: use_build_context_synchronously
              Navigator.pop(context, 'OK');
              focusNode.requestFocus();
            }
          } catch (e) {
            debug("No pop");
          }
        }
      });
    }
    gOn && !g.signedIn
        ? _signInSilently()
        : null; //FIXME not suitable for mobile
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(!g.signedIn
            ? (_newLoginButtons && kIsWeb ? "" : "Sign in?")
            : appTitle),
        Tooltip(
          message: !g.signedIn ? "Sign in" : "Sign out",
          child: !g.signedIn
              ? _newLoginButtons
                  ? _platformAdaptiveSignInButton(context)
                  : lockStyleSignInButton(context)
              : IconButton(
                  iconSize: _gUserIcon == _gUserIconDefault ? 25 : 50,
                  icon: _gUserIcon == _gUserIconDefault
                      ? const Icon(Icons.face_outlined)
                      : CircleAvatar(backgroundImage: NetworkImage(_gUserIcon)),
                  onPressed: () {
                    g.showLogoutConfirmationScreen(context);
                    focusNode.requestFocus();
                  },
                ),
        ),
      ],
    );
  }

  Future<void> showLogoutConfirmationScreen(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: bg,
          surfaceTintColor: bg,
          title: const Text("Sign out?"),
          //content: Text("Signed in as " + g.getUser()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _signOutAndExtractDetails();
                Navigator.pop(context, 'OK');
                Navigator.pop(context, 'OK');
              },
              child: const Text('Sign out', style: TextStyle(color: red)),
            ),
          ],
        );
      },
    );
  }

  bool get signedIn => gUser != _gUserDefault;

  String get gUser => gUserNotifier.value;

  set _gUser(g) => {
        debug(["gUserChanged", g]),
        gUserNotifier.value = g
      };

  String get _gUserIcon => _gUserIconReal;

  set _gUserIcon(gui) => _gUserIconReal = gui;

  double _iconWidth = 1;
  Color _color = Colors.white;

  Widget loginLogoutWidget(
      BuildContext context, double iconWidth, Color color) {
    _iconWidth = iconWidth;
    _color = color;
    return !gOn
        ? SizedBox.shrink()
        : ValueListenableBuilder<String>(
            valueListenable: gUserNotifier,
            builder: (context, audioOn, child) {
              return !signedIn ? _loginButton(context) : _logoutButton(context);
            });
  }

  Widget _loginButton(BuildContext context) {
    const bool newLoginButtons = false;
    return newLoginButtons
        // ignore: dead_code
        ? _platformAdaptiveSignInButton(context)
        : lockStyleSignInButton(context);
  }

  Widget lockStyleSignInButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.lock, color: _color),
      onPressed: () {
        _signInSilentlyThenDirectly();
      },
    );
  }

  Widget _platformAdaptiveSignInButton(BuildContext context) {
    // different buttons depending on web or mobile. See sign_in_button folder
    return buildSignInButton(
        onPressed:
            _signInDirectly, //relevant on web only, else uses separate code
        context: context,
        g: this);
  }

  Widget _logoutButton(BuildContext context) {
    return IconButton(
      icon: _gUserIcon == G._gUserIconDefault
          ? Icon(Icons.face_outlined, color: _color)
          : CircleAvatar(
              radius: _iconWidth / 2,
              backgroundImage: NetworkImage(_gUserIcon)),
      onPressed: () {
        _signOutAndExtractDetails();
      },
    );
  }

  GoogleSignIn googleSignIn = GoogleSignIn(
    //gID defined in secrets.dart, not included in repo
    //in format XXXXXX.apps.googleusercontent.com
    clientId: gID,
    scopes: <String>[
      'email',
    ],
  );

  Future<List<String>> _loadUserFromFilesystem() async {
    final prefs = await SharedPreferences.getInstance();
    String gUser = prefs.getString('gUser') ?? G._gUserDefault;
    String gUserIcon = prefs.getString('gUserIcon') ?? G._gUserIconDefault;
    debug(["loadUser", gUser, gUserIcon]);
    return [gUser, gUserIcon];
  }

  Future<void> _saveUserToFilesystem(String gUser, String gUserIcon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gUser', gUser);
    await prefs.setString('gUserIcon', gUserIcon);
    debug(["saveUser", gUser, gUserIcon]);
  }

  static const String _gUserDefault = "JoeBloggs";
  static const String _gUserIconDefault = "JoeBloggs";

  GoogleSignInAccount? _user;

  ValueNotifier<String> gUserNotifier = ValueNotifier("JoeBloggs");
  String _gUserIconReal = "JoeBloggs";

  Future<void> _loadUser() async {
    List<String> tmp = await _loadUserFromFilesystem();
    _gUser = tmp[0];
    _gUserIcon = tmp[1];
  }

  void _startGoogleAccountChangeListener() {
    if (gOn) {
      googleSignIn.onCurrentUserChanged
          .listen((GoogleSignInAccount? account) async {
        debug("gUser changed");
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

  // ignore: unused_element
  void _signInSilently() async {
    if (gOn) {
      await googleSignIn.signInSilently();
      _successfulLoginExtractDetails();
    }
  }

  Future<void> _signInDirectly() async {
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

  Future<void> _signOut() async {
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

  Future<void> _signInSilentlyThenDirectly() async {
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
      _gUser = _user!.email;
      if (_user!.photoUrl != null) {
        _gUserIcon = _user!.photoUrl ?? _gUserIconDefault;
      }
      await _saveUserToFilesystem(gUser, _gUserIcon);
      debug(["gUser", gUser]);
    }
  }

  void _debugLoginExtractDetails() async {
    debug("debugLoginExtractDetails");
    assert(_debugFakeLogin);
    _gUser = _gUserFakeLogin;
    await _saveUserToFilesystem(gUser, _gUserIcon);
    debug(["gUser", gUser]);
  }

  void _logoutExtractDetails() async {
    debug("logout extract details");
    _gUser = _gUserDefault;
    assert(!signedIn);
    await _saveUserToFilesystem(gUser, _gUserIcon);
    debug(["gUser", gUser]);
  }

  Future<void> _signOutAndExtractDetails() async {
    debug("sign out and extract details");
    if (gOn) {
      await _signOut();
      _logoutExtractDetails();
    }
  }
}

final G g = G();