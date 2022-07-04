import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hn_app/src/hn_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'src/article.dart';

void main() {
  final hnBloc = HackerNewsBloc();
  runApp(MyApp(bloc: hnBloc));
}

class MyApp extends StatelessWidget {
  final HackerNewsBloc bloc;

  const MyApp({Key? key, required this.bloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter Hacker News',
        bloc: bloc,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final HackerNewsBloc bloc;

  const MyHomePage({Key? key, required this.title, required this.bloc})
      : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<UnmodifiableListView<Article>>(
          stream: widget.bloc.articles,
          initialData: UnmodifiableListView<Article>([]),
          builder: (context, snapshot) {
            return ListView(
              children: snapshot.data!.map(_buildItem).toList(),
            );
          }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.arrow_drop_up), label: 'Top Stories'),
          BottomNavigationBarItem(
              icon: Icon(Icons.new_releases), label: 'New Stories')
        ],
        onTap: (index) {
          if (index == 0) {
            widget.bloc.storiesType.add(StoriesType.topStories);
          } else if (index == 1) {
            widget.bloc.storiesType.add(StoriesType.newStories);
          }
        },
      ),
    );
  }

  Widget _buildItem(Article article) {
    return Padding(
      key: Key(article.title!),
      padding: const EdgeInsets.all(16.0),
      child: ExpansionTile(
        title: Text(
          article.title!,
          style: const TextStyle(fontSize: 24.0),
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(article.type),
              IconButton(
                  icon: const Icon(Icons.launch),
                  onPressed: () async {
                    await launchUrl(Uri.parse(article.url!));
                  })
            ],
          )
        ],
      ),
    );
  }
}
