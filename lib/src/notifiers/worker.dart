import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:built_value/serializer.dart';
import 'package:hn_app/src/article.dart';
import 'package:hn_app/src/notifiers/hn_api.dart';
import 'package:http/http.dart';

class Worker {
  static const _baseURL = "https://hacker-news.firebaseio.com/v0/";
  late SendPort _sendPort;

  late Isolate _isolate;

  Completer<List<int>>? _ids;

  final _isolateReady = Completer<void>();

  Worker() {
    init();
  }

  Future<List<Article>> fetch(StoriesType type) async {
    final ids = await _fetchIds(type);
    return _getArticles(ids!);
  }

  Future<List<int>>? _fetchIds(StoriesType type) {
    final partUrl = (type == StoriesType.topStories) ? 'top' : 'new';
    final url = "$_baseURL${partUrl}stories.json";

    _sendPort.send(url);
    _ids = Completer<List<int>>();
    return _ids?.future;
  }

  Future<List<Article>> _getArticles(List<int> articleIds) async {
    final results = <Article>[];

    final futureArticles = articleIds.map<Future<void>>((id) async {
      try {
        var article = await _getArticle(id);
        results.add(article);
      } on HackerNewsApiException catch (e) {
        print(e);
      }
    });
    await Future.wait(futureArticles);
    final filtered = results.where((article) => article.title != null).toList();
    return filtered;
  }

  Future<Article> _getArticle(int id) async {
    final storyUrl = "${_baseURL}item/$id.json";
    try {
      final storyRes = await get(Uri.parse(storyUrl));
      if (storyRes.statusCode == 200) {
        return parseArticle(storyRes.body);
      } else {
        throw HackerNewsApiException(
            storyRes.statusCode, 'Article $id couldn\'t be fetched');
      }
    } on DeserializationError {
      throw HackerNewsApiException(200, 'Article $id can\'t be parsed');
    } on ClientException {
      throw HackerNewsApiException(200, 'Client Exception');
    }
  }

  Future<void> init() async {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    errorPort.listen(print);

    receivePort.listen(_handleMessage);
    _isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort,
        onError: errorPort.sendPort);
  }

  static Future<List<int>> _getIds(String url) async {
    Response response;
    try {
      response = await get(Uri.parse(url));
    } on SocketException catch (e) {
      throw HackerNewsApiException(300, '$url can\' be fetched: $e');
    }

    if (response.statusCode != 200) {
      // throw HackerNewsApiException('Stories $type can\' be fetched.');
      throw HackerNewsApiException(300, '$url returned non-HTTP200');
    }

    var result = parseStoryIds(response.body);

    return result.take(10).toList();
  }

  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _isolateReady.complete();
      return;
    }

    if (message is List<int>) {
      _ids?.complete(message);
      _ids = null;
      return;
    }
  }

  Future<void> get isReady => _isolateReady.future;

  static void _isolateEntry(dynamic message) {
    late SendPort sendPort;
    final receivePort = ReceivePort();

    receivePort.listen((dynamic message) async {
      assert(message is String);
      final ids = await _getIds(message);
      sendPort.send(ids);
    });

    if (message is SendPort) {
      sendPort = message;
      sendPort.send(receivePort.sendPort);
      return;
    }
  }

  void dispose() {
    _isolate.kill();
  }
}
