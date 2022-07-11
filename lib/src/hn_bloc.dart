import 'dart:async';
import 'dart:collection';

import 'package:hn_app/src/article.dart';
import 'package:http/http.dart';
import 'package:rxdart/subjects.dart';

enum StoriesType { topStories, newStories }

class HackerNewsBloc {
  late Map<int, Article> _cachedArticles;

  Stream<bool> get isLoading => _isLoadingSubject.stream;

  final _isLoadingSubject = BehaviorSubject<bool>.seeded(false);

  Stream<UnmodifiableListView<Article>> get topArticles =>
      _topArticlesSubject.stream;

  Stream<UnmodifiableListView<Article>> get newArticles =>
      _newArticlesSubject.stream;

  final _topArticlesSubject = BehaviorSubject<UnmodifiableListView<Article>>();
  final _newArticlesSubject = BehaviorSubject<UnmodifiableListView<Article>>();

  var _articles = <Article>[];

  Sink<StoriesType> get storiesType => _storiesTypeController.sink;

  final _storiesTypeController = StreamController<StoriesType>();

  HackerNewsBloc() : _cachedArticles = {} {
    _initializeArticles(); 

    _storiesTypeController.stream.listen((storiesType) async {
      _getArticlesAndUpdate(
          _topArticlesSubject, await _getIds(StoriesType.topStories));
      _getArticlesAndUpdate(
          _newArticlesSubject, await _getIds(StoriesType.newStories));
    });
  }

  Future<void> _initializeArticles() async {
    _getArticlesAndUpdate(
        _topArticlesSubject, await _getIds(StoriesType.topStories));
    _getArticlesAndUpdate(
        _newArticlesSubject, await _getIds(StoriesType.newStories));
  }

  void close() {
    _storiesTypeController.close();
    _topArticlesSubject.close();
    _newArticlesSubject.close();
  }

  _getArticlesAndUpdate(
      BehaviorSubject<UnmodifiableListView<Article>> subject, List<int> ids) {
    _isLoadingSubject.add(true);
    _updateArticles(ids).then((value) {
      subject.add(UnmodifiableListView(_articles));
      _isLoadingSubject.add(false);
    });
  }

  Future<void> _updateArticles(List<int> articleIds) async {
    final futureArticles = articleIds.map((id) => _getArticle(id));
    final all = await Future.wait(futureArticles);
    final filtered = all.where((article) => article.title != null).toList();
    _articles = filtered;
  }

  static const _baseURL = "https://hacker-news.firebaseio.com/v0/";

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
    final response = await get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw HackerNewsApiException('Stories $type can\' be fetched.');
    }

    return parseTopStories(response.body).take(10).toList();
  }
}

class HackerNewsApiException implements Exception {
  final String message;

  HackerNewsApiException(this.message);
}
