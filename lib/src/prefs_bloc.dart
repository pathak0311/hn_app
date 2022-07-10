import 'dart:async';
import 'dart:collection';

import 'package:hn_app/src/article.dart';
import 'package:http/http.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsState {
  final bool showWebView;

  PrefsState(this.showWebView);
}

class PrefsBloc {
  final _currentPrefs = BehaviorSubject<PrefsState>.seeded(PrefsState(true));
  final showWebViewPref = StreamController<bool>();

  PrefsBloc() {
    _loadSharedPrefs();

    showWebViewPref.stream.listen((result) {
      _saveNewPrefs(PrefsState(result));
    });
  }

  Stream<PrefsState> get currentPrefs => _currentPrefs.stream;

  Sink<bool> get showWebView => showWebViewPref.sink;

  void close() {
    showWebViewPref.close();
    _currentPrefs.close();
  }

  Future<void> _loadSharedPrefs() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final showWebView = sharedPrefs.getBool('showWebView') ?? true;
    _currentPrefs.add(PrefsState(showWebView));
  }

  Future<void> _saveNewPrefs(PrefsState newState) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool('showWebView', newState.showWebView);
    _currentPrefs.add(newState);
  }
}

class HackerNewsApiException implements Exception {
  final String message;

  HackerNewsApiException(this.message);
}
