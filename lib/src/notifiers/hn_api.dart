import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hn_app/src/article.dart';
import 'package:http/http.dart';

Map<int, Article> _cachedArticles = {};

enum StoriesType { topStories, newStories }

/// The number of tabs that are currently loading.
class LoadingTabsCount extends ValueNotifier<int> {
  LoadingTabsCount() : super(0);
}

class HackerNewsNotifier with ChangeNotifier {
  late List<HackerNewsTab> _tabs;

  HackerNewsNotifier(LoadingTabsCount loading) {
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

    scheduleMicrotask(() => _tabs.first.refresh());
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

    final ids = await _getIds(storiesType);
    _articles = await _updateArticles(ids);
    _isLoading = false;
    notifyListeners();
    loadingTabsCount.value -= 1;
  }

  Future<Article> _getArticle(int id) async {
    if (!_cachedArticles.containsKey(id)) {
      final storyUrl = "${_baseURL}item/$id.json";
      final storyRes = await get(Uri.parse(storyUrl));
      if (storyRes.statusCode == 200) {
        _cachedArticles[id] = parseArticle(storyRes.body);
      } else {
        throw HackerNewsApiException('Article $id couldn\'t be fetched');
      }
    }

    return _cachedArticles[id] ?? Article();
  }

  Future<List<int>> _getIds(StoriesType type) async {
    final partUrl = (type == StoriesType.topStories) ? 'top' : 'new';
    final url = "$_baseURL${partUrl}stories.json";
    // final response = await get(Uri.parse(url));
    var error =
        () => throw HackerNewsApiException('Stories $type can\' be fetched.');

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

    return parseTopStories(response.body).take(10).toList();
  }

  Future<List<Article>> _updateArticles(List<int> articleIds) async {
    final futureArticles = articleIds.map((id) => _getArticle(id));
    final all = await Future.wait(futureArticles);
    final filtered = all.where((article) => article.title != null).toList();
    return filtered;
  }
}

class HackerNewsApiException implements Exception {
  final String message;

  HackerNewsApiException(this.message);
}
