// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../secrets.dart';
import 'google.dart';
import 'src/web_wrapper.dart' as web;

/// To run this example, replace this value with your client ID, and/or
/// update the relevant configuration files, as described in the README.
String? clientId = gID;

/// To run this example, replace this value with your server client ID, and/or
/// update the relevant configuration files, as described in the README.
String? serverClientId;

/// The SignInDemo app.
class GoogleSignInWidget extends StatefulWidget {
  ///
  const GoogleSignInWidget({super.key});

  @override
  State createState() => _GoogleSignInWidgetState();
}

class _GoogleSignInWidgetState extends State<GoogleSignInWidget> {
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    print("init");
    super.initState();

    // #docregion Setup
    final GoogleSignIn signIn = GoogleSignIn.instance;
    unawaited(
      signIn.initialize(clientId: clientId, serverClientId: serverClientId).then((
        _,
      ) {
        signIn.authenticationEvents
            .listen(_handleAuthenticationEvent)
            .onError(_handleAuthenticationError);

        /// This example always uses the stream-based approach to determining
        /// which UI state to show, rather than using the future returned here,
        /// if any, to conditionally skip directly to the signed-in state.
        signIn.attemptLightweightAuthentication();
        g.googleWidgetLogoutFunction = _handleSignOut;
      }),
    );
    // #enddocregion Setup
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    // #docregion CheckAuthorization
    final GoogleSignInAccount? user = // ...
    // #enddocregion CheckAuthorization
    switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (!mounted) {
      print("not mounted 1");
      _currentUser = user;
    } else {
      setState(() {
        _currentUser = user;
      });
    }

    if (user != null) {
      await g.extractDetailsFromLogin(user);
    } else {
      await g.extractDetailsFromLogout();
    }
  }

  Future<void> _handleAuthenticationError(Object e) async {
    if (!mounted) {
      print("not mounted 2");
      _currentUser = null;
    } else {
      setState(() {
        _currentUser = null;
      });
    }
  }

  Future<void> _handleSignOut() async {
    print("widget sign out");
    // Disconnect instead of just signing out, to reset the example state as
    // much as possible.
    await GoogleSignIn.instance.disconnect();
  }

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    return user != null
        ? ElevatedButton(
          onPressed: _handleSignOut,
          child: const Text('SIGN OUT'),
        )
        : web.renderButton();
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }
}
