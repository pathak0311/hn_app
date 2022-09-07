import 'package:flutter/material.dart';
import 'package:hn_app/src/favorites.dart';
import 'package:provider/provider.dart';

import '../widgets/webpage.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var myDatabase = Provider.of<MyDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: StreamBuilder(
        stream: myDatabase.allFavoriteEntries.asStream(),
        builder:
            (BuildContext context, AsyncSnapshot<List<Favorite>> snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                            leading: IconButton(
                              icon: const Icon(Icons.star),
                              onPressed: () {
                                myDatabase
                                    .removeFavorite(snapshot.data![index].id);
                                setState(() {});
                              },
                            ),
                            title: Text(snapshot.data![index].title),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HackerNewsWebPage(
                                          url: snapshot.data![index].url)));
                            });
                      }),
                )
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
