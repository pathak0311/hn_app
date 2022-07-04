import 'dart:async';
import 'dart:collection';

import 'package:hn_app/src/article.dart';
import 'package:http/http.dart';
import 'package:rxdart/subjects.dart';

enum StoriesType { topStories, newStories }

class HackerNewsBloc {
  Stream<UnmodifiableListView<Article>> get articles => _articlesSubject.stream;

  final _articlesSubject = BehaviorSubject<UnmodifiableListView<Article>>();

  var _articles = <Article>[];

  Sink<StoriesType> get storiesType => _storiesTypeController.sink;

  final _storiesTypeController = StreamController<StoriesType>();

  static final List<int> _newIds = [
    31949731,
    31929941,
    31939983,
    31932808,
    31953470
  ];

  static final List<int> _topIds = [
    31932349,
    31949348,
    31945425,
    31932250,
    31941902
  ];

  HackerNewsBloc() {
    _getArticlesAndUpdate(_topIds);

    _storiesTypeController.stream.listen((storiesType) {
      List<int> _ids;
      if (storiesType == StoriesType.newStories) {
        _getArticlesAndUpdate(_newIds);
      } else {
        _getArticlesAndUpdate(_topIds);
      }

    });
  }

  _getArticlesAndUpdate(List<int> ids){
    _updateArticles(ids).then((value) {
      _articlesSubject.add(UnmodifiableListView(_articles));
    });
  }

  Future<void> _updateArticles(List<int> articleIds) async {
    final futureArticles = articleIds.map((id) => _getArticle(id));
    final articles = await Future.wait(futureArticles);
    _articles = articles;
  }

  Future<Article> _getArticle(int id) async {
    final storyUrl = "https://hacker-news.firebaseio.com/v0/item/$id.json";
    final storyRes = await get(Uri.parse(storyUrl));
    if (storyRes.statusCode == 200) {
      return parseArticle(storyRes.body);
    }
    return Article();
  }
}
