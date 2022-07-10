import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hn_app/src/hn_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/article.dart';

void main() {
  final hnBloc = HackerNewsBloc();
  runApp(MyApp(bloc: hnBloc));
}

class MyApp extends StatelessWidget {
  final HackerNewsBloc bloc;

  const MyApp({Key? key, required this.bloc}) : super(key: key);

  static const primaryColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          scaffoldBackgroundColor: primaryColor,
          appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
              iconTheme: IconThemeData(color: Colors.black)),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.white54),
          textTheme: Theme.of(context).textTheme.copyWith(
              caption: const TextStyle(color: Colors.white54),
              subtitle1: const TextStyle(
                  fontFamily: 'Garamond',
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800))),
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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(widget.title),
        leading: LoadingInfo(isLoading: widget.bloc.isLoading),
        actions: [
          Builder(builder: (context) {
            return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  final Article? result = await showSearch(
                      context: context,
                      delegate: ArticleSearch(widget.bloc.articles));

                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(result!.title!)));

                  // launchUrl(Uri.parse(result.url!));
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HackerNewsWebPage(
                                url: result.url!,
                              )));
                });
          })
        ],
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
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.arrow_drop_up), label: 'Top Stories'),
          BottomNavigationBarItem(
              icon: Icon(Icons.new_releases), label: 'New Stories')
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: ExpansionTile(
        title: Text(
          article.title!,
          style: const TextStyle(fontSize: 24.0),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('${article.descendants} Comments'),
                    const SizedBox(
                      width: 16.0,
                    ),
                    IconButton(
                        icon: const Icon(Icons.launch),
                        onPressed: () {
                          // await launchUrl(Uri.parse(article.url!));
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HackerNewsWebPage(
                                        url: article.url!,
                                      )));
                        })
                  ],
                ),
                SizedBox(
                    height: 200,
                    child: WebView(
                      initialUrl: article.url!,
                      javascriptMode: JavascriptMode.unrestricted,
                      gestureRecognizers:
                          <Factory<OneSequenceGestureRecognizer>>{}..add(
                              Factory<VerticalDragGestureRecognizer>(
                                  () => VerticalDragGestureRecognizer())),
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }
}

class LoadingInfo extends StatefulWidget {
  final Stream<bool> isLoading;

  const LoadingInfo({Key? key, required this.isLoading}) : super(key: key);

  @override
  State<LoadingInfo> createState() => _LoadingInfoState();
}

class _LoadingInfoState extends State<LoadingInfo>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget.isLoading,
        builder: (BuildContext context, AsyncSnapshot<bool> loading) {
          if (loading.hasData && loading.data!) {
            _controller.forward().then((f) {
              _controller.reverse();
            });
            return FadeTransition(
              opacity: Tween(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeIn)),
              child: const Icon(FontAwesomeIcons.hackerNewsSquare),
            );
          }
          return Container();
        });
  }
}

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

class HackerNewsWebPage extends StatelessWidget {
  final String url;

  const HackerNewsWebPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Web Page')),
      body: WebView(
        initialUrl: url,
      ),
    );
  }
}
