import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:hn_app/src/article.dart';

part 'json_parsing.g.dart';

abstract class Article implements Built<Article, ArticleBuilder> {
  int get id;

  Article._();
  factory Article([void Function(ArticleBuilder) updates]) = _$Article;
}

List<int> parseTopStories(String json) {
  return [];
  // final parsed = jsonDecode(json);
  // final listOfIds = List<int>.from(parsed);
  // return listOfIds;
}

Article? parseArticle(String json) {
  return null;
  // final parsed = jsonDecode(json);
  // Article article = Article.fromJson(parsed);
  // return article;
}
