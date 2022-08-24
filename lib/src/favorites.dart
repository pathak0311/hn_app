import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hn_app/src/article.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'favorites.g.dart';

// this will generate a table called "favorites" for us. The rows of that table will
// be represented by a class called "favorite".
class Favorites extends Table {
  IntColumn? get id => integer().customConstraint('UNIQUE')();

  TextColumn? get title => text()();

  TextColumn? get url => text()();

  TextColumn? get category => text().nullable()();
}

// this annotation tells drift to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
@DriftDatabase(tables: [Favorites])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition.
  // Migrations are covered later in the documentation.
  @override
  int get schemaVersion => 1;

  // loads all favorite entries
  Future<List<Favorite>> get allFavoriteEntries => select(favorites).get();

  void addFavorite(Article article) {
    into(favorites).insert(Favorite(
        id: article.id,
        title: article.title!,
        url: article.url!,
        category: article.type));
  }

  void removeFavorite(int id) =>
      (delete(favorites)..where((favorite) => favorite.id.equals(id))).go();

  // watches all favorite entries in a given category. The stream will automatically
  // emit new items whenever the underlying data changes.
  Stream<bool> isFavorite(int id) {
    return select(favorites).watch().map((favoritesList) =>
        favoritesList.where((favorite) => favorite.id == id).isNotEmpty);
    return (select(favorites)..where((favorite) => favorite.id.equals(id)))
        .watch()
        .map((favoritesList) => favoritesList.isNotEmpty);
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
