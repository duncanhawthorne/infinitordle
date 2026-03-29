import 'package:flutter/foundation.dart';

import 'constants.dart';

/// Notifier for managing card flip flourish animations.
class CustomMapNotifier extends ValueNotifier<Map<int, List<double>>> {
  CustomMapNotifier() : super(<int, List<double>>{});

  int _numberNonZeroItems() {
    int count = 0;
    for (int key in value.keys) {
      for (int i = 0; i < cols; i++) {
        if (value[key]![i] > 0) {
          count++;
        }
      }
    }
    return count;
  }

  int numberNotYetFlourishFlipped = 0;

  void set(int abRow, int column, double tvalue) {
    if (!value.containsKey(abRow)) {
      value[abRow] = List<double>.generate(cols, (int i) => 0.0);
    }
    value[abRow]![column] = tvalue;
    numberNotYetFlourishFlipped = _numberNonZeroItems();
    notifyListeners();
  }

  void remove(int key) {
    if (value.containsKey(key)) {
      value.remove(key);
    }
    numberNotYetFlourishFlipped = _numberNonZeroItems();
    notifyListeners();
  }
}
