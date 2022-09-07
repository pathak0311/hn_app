import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsBlocError extends Error {
  final String message;

  PrefsBlocError(this.message);
}

class PrefsState {
  final bool showWebView;
  final bool userSetDarkMode;

  const PrefsState(this.showWebView, this.userSetDarkMode);
}

class PrefsNotifier with ChangeNotifier {
  PrefsState _currentPrefs = const PrefsState(false, false);

  PrefsNotifier() {
    _loadSharedPrefs();
  }

  bool get showWebView => _currentPrefs.showWebView;
  bool get userDarkMode => _currentPrefs.userSetDarkMode;

  set showWebView(bool newValue) {
    if (newValue == _currentPrefs.showWebView) return;
    _currentPrefs = PrefsState(newValue, _currentPrefs.userSetDarkMode);
    notifyListeners();
    _saveNewPrefs();
  }

  set userDarkMode(bool newValue) {
    if (newValue == _currentPrefs.userSetDarkMode) return;
    _currentPrefs = PrefsState(_currentPrefs.showWebView, newValue);
    notifyListeners();
    _saveNewPrefs();
  }

  Future<void> _loadSharedPrefs() async {
    var sharedPrefs = await SharedPreferences.getInstance();
    var showWebView = sharedPrefs.getBool('showWebView') ?? false;
    var userSetDarkMode = sharedPrefs.getBool('userDarkMode') ?? false;
    _currentPrefs = PrefsState(showWebView, userSetDarkMode);
    notifyListeners();
  }

  Future<void> _saveNewPrefs() async {
    var sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool('showWebView', _currentPrefs.showWebView);
    await sharedPrefs.setBool('userDarkMode', _currentPrefs.userSetDarkMode);
  }
}