import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:hn_app/src/serializers.dart';

part 'article.g.dart';

abstract class Article implements Built<Article, ArticleBuilder> {
  static Serializer<Article> get serializer => _$articleSerializer;

  int get id;
  bool? get deleted;
  String get type;
  String get by;
  int get time;
  String? get text;
  bool? get dead;
  int? get parent;
  int? get poll;
  BuiltList<int> get kids;
  String? get url;
  int? get score;
  String? get title;
  BuiltList<int> get parts;
  int? get descendants;

  Article._();
  factory Article([void Function(ArticleBuilder) updates]) = _$Article;
}

List<int> parseTopStories(String json) {
  return [];
  // final parsed = jsonDecode(json);
  // final listOfIds = List<int>.from(parsed);
  // return listOfIds;
}

Article parseArticle(String json) {
  final parsed = jsonDecode(json);
  Article article = standardSerializers.deserializeWith(Article.serializer, parsed)!;
  return article;
}




// class Article {
//   final String text;
//   final String url;
//   final String by;
//   final int time;
//   final int score;
//
//   const Article(this.text, this.url, this.by, this.time, this.score);
//
//   factory Article.fromJson(Map<String, dynamic> json) {
//     return Article(json['text'] ?? '[null]', json['url'] ?? '[null]',
//         json['by'] ?? '[null]', json['time'] ?? '[null]', json['score'] ?? 0);
//   }
// }
