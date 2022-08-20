import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hn_app/src/notifiers/hn_api.dart';
import 'package:hn_app/src/notifiers/prefs.dart';
import 'package:hn_app/src/widgets/headline.dart';
import 'package:hn_app/src/widgets/loading_info.dart';
import 'package:hn_app/src/widgets/search.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/article.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<LoadingTabsCount>(
        create: (_) => LoadingTabsCount(),
      ),
      ChangeNotifierProvider(
        create: (context) => HackerNewsNotifier(
            Provider.of<LoadingTabsCount>(context, listen: false)),
      ),
      ChangeNotifierProvider(create: (_) => PrefsNotifier())
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    _pageController.addListener(_handlePageChange);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    super.dispose();
  }

  void _handlePageChange() {
    setState(() {
      _currentIndex = _pageController.page!.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hn = Provider.of<HackerNewsNotifier>(context);
    final tabs = hn.tabs;
    final current = tabs[_currentIndex];

    if (current.articles.isEmpty && !current.isLoading) {
      // New tab with no data. Let's fetch some.
      current.refresh();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Headline(text: tabs[_currentIndex].name, index: _currentIndex),
        leading: Consumer<LoadingTabsCount>(
            builder: (context, loading, child) => LoadingInfo(loading)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final Article? result = await showSearch(
                    context: context, delegate: ArticleSearch(hn.allArticles));

                if (result != null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HackerNewsWebPage(
                                url: result.url!,
                              )));
                }

                // launchUrl(Uri.parse(result.url!));
              })
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: tabs.length,
        itemBuilder: (context, index) => ChangeNotifierProvider.value(
          value: tabs[index],
          child: _TabPage(index),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          for (final tab in tabs)
            BottomNavigationBarItem(
              label: tab.name,
              icon: Icon(tab.icon),
            )
        ],
        onTap: (index) {
          _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic);
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Article article;
  final PrefsNotifier prefs;

  const _Item({Key? key, required this.article, required this.prefs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PrefsNotifier>(context);

    assert(article.title != null);
    return Padding(
      key: PageStorageKey(article.title!),
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
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HackerNewsWebPage(
                                      url:
                                          article.url ?? 'https://flutter.dev/',
                                    ))))
                  ],
                ),
                prefs.showWebView
                    ? SizedBox(
                        height: 200,
                        child: WebView(
                          javascriptMode: JavascriptMode.unrestricted,
                          initialUrl: article.url,
                          gestureRecognizers: Set()
                            ..add(Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer())),
                        ),
                      )
                    : Container(),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TabPage extends StatelessWidget {
  final int index;

  _TabPage(this.index, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tab = Provider.of<HackerNewsTab>(context);
    final articles = tab.articles;
    final prefs = Provider.of<PrefsNotifier>(context);

    if (tab.isLoading && articles.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () => tab.refresh(),
      child: ListView(
        key: PageStorageKey(index),
        children: [
          for (final article in articles)
            _Item(
              article: article,
              prefs: prefs,
            )
        ],
      ),
    );
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
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

class HackerNewsCommentPage extends StatelessWidget {
  final int id;

  HackerNewsCommentPage(this.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: WebView(
        initialUrl: 'https://news.ycombinator.com/item?id=$id',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

class PrefsSheet extends StatefulWidget {
  final PrefsNotifier prefs;

  const PrefsSheet({Key? key, required this.prefs}) : super(key: key);

  @override
  State<PrefsSheet> createState() => _PrefsSheetState();
}

class _PrefsSheetState extends State<PrefsSheet> {
  @override
  Widget build(BuildContext context) {
    return Center(
      // child: StreamBuilder<PrefsState>(
      //     stream: widget.prefs._,
      //     builder: (BuildContext context, AsyncSnapshot<PrefsState> snapshot) {
      //       return snapshot.hasData
      //           ? Switch(
      //               value: snapshot.data!.showWebView,
      //               onChanged: (value) {
      //                 widget.prefs.showWebView.add(value);
      //               })
      //           : Text('Nothing');
      //     }),
    );
  }
}
