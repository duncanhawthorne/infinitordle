import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../constants.dart';

void fixTitleReal() {
  if (isiOSMobile) {
    fixTitle1();
    fixTitle2();
    fixTitle3();
  }
}

void fixTitle1() {
  //https://github.com/flutter/flutter/issues/98248
  if (true) {
    SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
        label: appTitle,
        primaryColor: bg
            .value //Theme.of(context).primaryColor.value, // This line is required
        ));
  }
}

void fixTitle2() {
  String url = web.window.location.href;
  web.window.history.replaceState(
    //or pushState
    web.window.history.state, // Note that we don't change the historyState
    appTitle,
    url,
  );
}

void fixTitle3() {
  String url = web.window.location.href;
  web.window.history.pushState(
    web.window.history.state, // Note that we don't change the historyState
    appTitle,
    url,
  );
}
