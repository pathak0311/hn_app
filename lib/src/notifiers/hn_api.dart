import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hn_app/src/article.dart';
import 'package:hn_app/src/notifiers/worker.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

Map<int, Article> _cachedArticles = {};

enum StoriesType { topStories, newStories }

/// The number of tabs that are currently loading.
class LoadingTabsCount extends ValueNotifier<int> {
  LoadingTabsCount() : super(0);
}

class HackerNewsNotifier with ChangeNotifier {
  late List<HackerNewsTab> _tabs;

  static final _log = Logger('HackerNewsNotifier');

  HackerNewsNotifier(LoadingTabsCount loading) {
    _log.fine('constructor called');

    _tabs = [
      HackerNewsTab(
        StoriesType.topStories,
        'Top Stories',
        Icons.arrow_drop_up,
        loading,
      ),
      HackerNewsTab(
        StoriesType.newStories,
        'New Stories',
        Icons.new_releases,
        loading,
      ),
    ];

    scheduleMicrotask(() {
      _log.fine('First refresh of first tab called.');
      _tabs.first.refresh();
    });
  }

  /// Articles from all tabs. De-duplicated.
  UnmodifiableListView<Article> get allArticles => UnmodifiableListView(
      _tabs.expand((tab) => tab.articles).toSet().toList(growable: false));

  UnmodifiableListView<HackerNewsTab> get tabs => UnmodifiableListView(_tabs);
}

class HackerNewsTab with ChangeNotifier {
  static const _baseURL = "https://hacker-news.firebaseio.com/v0/";
  late StoriesType storiesType;
  late String name;

  List<Article> _articles = [];

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  late IconData icon;
  late LoadingTabsCount loadingTabsCount;

  HackerNewsTab(this.storiesType, this.name, this.icon, this.loadingTabsCount);

  UnmodifiableListView<Article> get articles => UnmodifiableListView(_articles);

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    loadingTabsCount.value += 1;

    final worker = Worker();
    await worker.isReady;

    _articles = await worker.fetch(storiesType);
    _isLoading = false;

    worker.dispose();

    notifyListeners();
    loadingTabsCount.value -= 1;
  }

  Future<List<int>> _getIds(StoriesType type) async {
    final partUrl = (type == StoriesType.topStories) ? 'top' : 'new';
    final url = "$_baseURL${partUrl}stories.json";
    // final response = await get(Uri.parse(url));
    var error = () =>
        throw HackerNewsApiException(300, 'Stories $type can\' be fetched.');

    var response;

    try {
      response = await get(Uri.parse(url));
    } on SocketException {
      error();
    }

    if (response.statusCode != 200) {
      // throw HackerNewsApiException('Stories $type can\' be fetched.');
      error();
    }

    // var result = await compute<String, List<int>>(parseStoryIds, response.body);

    var result = parseStoryIds(response.body);

    return result.take(10).toList();
  }
}

class HackerNewsApiException implements Exception {
  final int statusCode;
  final String message;

  HackerNewsApiException(this.statusCode, this.message);
}
