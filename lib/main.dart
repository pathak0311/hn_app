import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hn_app/src/favorites.dart';
import 'package:hn_app/src/notifiers/hn_api.dart';
import 'package:hn_app/src/notifiers/prefs.dart';
import 'package:hn_app/src/pages/favorites.dart';
import 'package:hn_app/src/pages/settings.dart';
import 'package:hn_app/src/widgets/headline.dart';
import 'package:hn_app/src/widgets/loading_info.dart';
import 'package:hn_app/src/widgets/search.dart';
import 'package:hn_app/src/widgets/webpage.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/article.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((event) {});

  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ListenableProvider<LoadingTabsCount>(
        create: (_) => LoadingTabsCount(),
        dispose: (_, value) => value.dispose(),
      ),
      Provider<MyDatabase>(create: (_) => MyDatabase()),
      ChangeNotifierProvider(
        create: (context) => HackerNewsNotifier(
            Provider.of<LoadingTabsCount>(context, listen: false)),
      ),
      ChangeNotifierProvider(create: (_) => PrefsNotifier())
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  static const primaryColor = Colors.white;

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData lightThemeData = ThemeData(
        scaffoldBackgroundColor: primaryColor,
        appBarTheme: const AppBarTheme(
            backgroundColor: primaryColor,
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
            iconTheme: IconThemeData(color: Colors.black)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.white54),
        textTheme: TextTheme(
            caption: const TextStyle(color: Colors.white54),
            subtitle1: GoogleFonts.boogaloo(fontSize: 26),
            button: GoogleFonts.boogaloo(fontSize: 18)));
    return MaterialApp(
      title: 'Flutter Demo',
      darkTheme: Provider.of<PrefsNotifier>(context).userDarkMode
          ? ThemeData.dark()
          : lightThemeData,
      theme: lightThemeData,
      home: const MyHomePage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const MyHomePage());
          case '/favorites':
            return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
              return const FavoritesPage();
            });
          case '/settings':
            return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
              return SettingsPage(initialAnimation: animation);
            }, transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                    scale: animation.drive(
                      Tween(begin: 1.3, end: 1.0).chain(
                        CurveTween(curve: Curves.easeOutCubic),
                      ),
                    ),
                    child: child),
              );
            });
          default:
            throw UnimplementedError('no route for $settings');
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

GlobalKey<NavigatorState> _pageNavigatorKey = GlobalKey<NavigatorState>();

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
    final newIndex = _pageController.page!.round();

    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });

      final hn = Provider.of<HackerNewsNotifier>(context);
      final tabs = hn.tabs;
      final current = tabs[_currentIndex];

      if (current.articles.isEmpty && !current.isLoading) {
        current.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hn = Provider.of<HackerNewsNotifier>(context);
    final tabs = hn.tabs;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Headline(text: tabs[_currentIndex].name, index: _currentIndex),
        // leading: Consumer<LoadingTabsCount>(
        //     builder: (context, loading, child) => LoadingInfo(loading)),
        leading: Consumer<LoadingTabsCount>(
          builder: (context, loading, child) {
            bool isLoading = loading.value > 0;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: isLoading
                  ? LoadingInfo(loading)
                  : IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
            );
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final Article? result = await showSearch(
                    context: context, delegate: ArticleSearch(hn.allArticles));

                if (result != null) {
                  if (mounted) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => HackerNewsWebPage(
                              url: result.url!,
                            )));
                  }
                }

                // launchUrl(Uri.parse(result.url!));
              })
        ],
      ),
      drawer: Drawer(
          child: ListView(
        children: [
          const DrawerHeader(child: Text('HN App')),
          ListTile(
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      )),
      body: Navigator(
        key: _pageNavigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == '/favorites') {
            return MaterialPageRoute(builder: (context) {
              return const FavoritesPage();
            });
          }
          return MaterialPageRoute(builder: (context) {
            return PageView.builder(
              controller: _pageController,
              itemCount: tabs.length,
              itemBuilder: (context, index) => ChangeNotifierProvider.value(
                value: tabs[index],
                child: _TabPage(index),
              ),
            );
          });
        },
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
    var myDatabase = Provider.of<MyDatabase>(context);

    assert(article.title != null);
    return Padding(
      key: PageStorageKey(article.title!),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: Column(
        children: [
          ExpansionTile(
            leading: StreamBuilder<bool>(
              stream: myDatabase.isFavorite(article.id),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!) {
                  return IconButton(
                    icon: const Icon(Icons.star),
                    onPressed: () => myDatabase.removeFavorite(article.id),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.star_border),
                  onPressed: () => myDatabase.addFavorite(article),
                );
              },
            ),
            title: Text(article.title!),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 46),
                          child: TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          HackerNewsCommentPage(
                                            id: article.id,
                                          ))),
                              child: Text('${article.descendants} Comments')),
                        ),
                        const SizedBox(
                          width: 16.0,
                        ),
                        IconButton(
                            icon: const Icon(Icons.launch),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HackerNewsWebPage(
                                          url: article.url ??
                                              'https://flutter.dev/',
                                        ))))
                      ],
                    ),
                    prefs.showWebView
                        ? SizedBox(
                            height: 200,
                            child: WebView(
                              javascriptMode: JavascriptMode.unrestricted,
                              initialUrl: article.url,
                              gestureRecognizers: <
                                  Factory<OneSequenceGestureRecognizer>>{}
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
        ],
      ),
    );
  }
}

class _TabPage extends StatelessWidget {
  final int index;

  const _TabPage(this.index, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tab = Provider.of<HackerNewsTab>(context);
    final articles = tab.articles;
    final prefs = Provider.of<PrefsNotifier>(context);

    if (tab.isLoading && articles.isEmpty) {
      return const Center(
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

class HackerNewsCommentPage extends StatelessWidget {
  final int id;

  const HackerNewsCommentPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
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
    return const Center(
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
