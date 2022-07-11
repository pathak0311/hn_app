import 'dart:collection';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../article.dart';

class ArticleSearch extends SearchDelegate<Article> {
  final Stream<UnmodifiableListView<Article>> articles;

  ArticleSearch(this.articles);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Article());
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Article>>(
        stream: articles,
        builder: (BuildContext context,
            AsyncSnapshot<UnmodifiableListView<Article>> snapshot) {
          if (snapshot.hasData) {
            final results = snapshot.data!.where((element) =>
                element.title!.toLowerCase().contains(query.toLowerCase()));
            return ListView(
              children: results
                  .map<ListTile>((article) => ListTile(
                title: Text(
                  article.title!,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(fontSize: 16),
                ),
                leading: const Icon(Icons.book),
                subtitle: Text(article.url!),
                onTap: () {
                  // launchUrl(Uri.parse(article.url!));
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HackerNewsWebPage(
                            url: article.url!,
                          )));
                  close(context, article);
                },
              ))
                  .toList(),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Article>>(
        stream: articles,
        builder: (BuildContext context,
            AsyncSnapshot<UnmodifiableListView<Article>> snapshot) {
          if (snapshot.hasData) {
            final results = snapshot.data!.where((element) =>
                element.title!.toLowerCase().contains(query.toLowerCase()));
            return ListView(
              children: results
                  .map<ListTile>((article) => ListTile(
                title: Text(
                  article.title!,
                  style: Theme.of(context)
                      .textTheme
                      .headline6!
                      .copyWith(fontSize: 16, color: Colors.blue),
                ),
                onTap: () {
                  close(context, article);
                },
              ))
                  .toList(),
            );
          }
          return const Center(child: CircularProgressIndicator());
        });
  }
}