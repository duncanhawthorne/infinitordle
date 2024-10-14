// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';

void debug(dynamic x) {
  debugPrint("///// A ${DateTime.now()} ${x ?? "null"}");
}
