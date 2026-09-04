import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/navigation_place.dart';

class NavigationPlaceService {
  NavigationPlaceService._();

  static final NavigationPlaceService instance = NavigationPlaceService._();

  Database? _database;

  final ValueNotifier<List<NavigationPlace>> favourites =
      ValueNotifier<List<NavigationPlace>>(
    <NavigationPlace>[],
  );

  final ValueNotifier<List<NavigationPlace>> recent =
      ValueNotifier<List<NavigationPlace>>(
    <NavigationPlace>[],
  );

  final ValueNotifier<bool> databaseInstalled = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<String?> databasePath = ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<String?> error = ValueNotifier<String?>(
    null,
  );

  Future<Directory> _navigationDirectory() async {
    final Directory support = await getApplicationSupportDirectory();

    final Directory directory = Directory(
      '${support.path}/navigation',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  Future<String> get defaultDatabasePath async {
    final Directory directory = await _navigationDirectory();

    return '${directory.path}/rustler_navigation.db';
  }

  Future<void> initialise() async {
    if (_database != null) {
      return;
    }

    final String path = await defaultDatabasePath;

    final File file = File(path);

    if (!await file.exists()) {
      await _createEmptyDatabase(
        path,
      );
    }

    _openDatabase(
      path,
    );

    await refresh();
  }

  Future<void> _createEmptyDatabase(
    String path,
  ) async {
    final Database db = sqlite3.open(
      path,
    );

    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        osm_type TEXT,
        osm_id INTEGER,

        name TEXT NOT NULL,
        address TEXT,

        latitude REAL NOT NULL,
        longitude REAL NOT NULL,

        category TEXT,

        favourite INTEGER NOT NULL DEFAULT 0,
        is_home INTEGER NOT NULL DEFAULT 0,
        is_work INTEGER NOT NULL DEFAULT 0,

        visit_count INTEGER NOT NULL DEFAULT 0,
        last_visited TEXT
      );
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS idx_places_name
      ON places(name);
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS idx_places_address
      ON places(address);
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS idx_places_recent
      ON places(last_visited);
      ''',
    );

    db.close();
  }

  void _openDatabase(
    String path,
  ) {
    _database?.close();

    _database = sqlite3.open(
      path,
    );

    databasePath.value = path;

    databaseInstalled.value = true;
  }

  Future<void> importDatabase() async {
    error.value = null;

    final PlatformFile? picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>[
        'db',
        'sqlite',
        'sqlite3',
      ],
    );

    if (picked == null) {
      return;
    }

    final String? sourcePath = picked.path;

    if (sourcePath == null) {
      error.value = 'Selected database has no local path.';

      return;
    }

    final File source = File(
      sourcePath,
    );

    if (!await source.exists()) {
      error.value = 'Selected database does not exist.';

      return;
    }

    final String destinationPath = await defaultDatabasePath;

    _database?.close();

    _database = null;

    try {
      final File destination = File(
        destinationPath,
      );

      if (await destination.exists()) {
        await destination.delete();
      }

      await source.copy(
        destinationPath,
      );

      _openDatabase(
        destinationPath,
      );

      if (!_validateDatabase()) {
        _database?.close();

        _database = null;

        await File(
          destinationPath,
        ).delete();

        databaseInstalled.value = false;

        databasePath.value = null;

        throw StateError(
          'This is not a valid RigOS navigation database.',
        );
      }

      await refresh();
    } catch (exception) {
      error.value = exception.toString();

      rethrow;
    }
  }

  bool _validateDatabase() {
    final Database db = _requireDatabase();

    final ResultSet result = db.select(
      '''
      SELECT name
      FROM sqlite_master
      WHERE
        type = 'table'
        AND name = 'places'
      LIMIT 1;
      ''',
    );

    return result.isNotEmpty;
  }

  Future<void> refresh() async {
    favourites.value = getFavourites();

    recent.value = getRecent();
  }

  Future<List<NavigationPlace>> search(
    String query, {
    int limit = 30,
  }) async {
    await initialise();

    final String cleaned = query.trim();

    if (cleaned.isEmpty) {
      return <NavigationPlace>[];
    }

    final Database db = _requireDatabase();

    final String like = '%$cleaned%';

    final ResultSet rows = db.select(
      '''
      SELECT *
      FROM places
      WHERE
        name LIKE ? COLLATE NOCASE
        OR address LIKE ? COLLATE NOCASE
        OR category LIKE ? COLLATE NOCASE
      ORDER BY
        CASE
          WHEN name LIKE ? COLLATE NOCASE
          THEN 0
          ELSE 1
        END,
        favourite DESC,
        visit_count DESC,
        name ASC
      LIMIT ?;
      ''',
      <Object?>[
        like,
        like,
        like,
        '$cleaned%',
        limit,
      ],
    );

    return rows
        .map(
          _placeFromRow,
        )
        .toList();
  }

  List<NavigationPlace> getFavourites({
    int limit = 50,
  }) {
    if (_database == null) {
      return <NavigationPlace>[];
    }

    final ResultSet rows = _database!.select(
      '''
      SELECT *
      FROM places
      WHERE favourite = 1
      ORDER BY
        name ASC
      LIMIT ?;
      ''',
      <Object?>[
        limit,
      ],
    );

    return rows
        .map(
          _placeFromRow,
        )
        .toList();
  }

  List<NavigationPlace> getRecent({
    int limit = 20,
  }) {
    if (_database == null) {
      return <NavigationPlace>[];
    }

    final ResultSet rows = _database!.select(
      '''
      SELECT *
      FROM places
      WHERE last_visited IS NOT NULL
      ORDER BY
        last_visited DESC
      LIMIT ?;
      ''',
      <Object?>[
        limit,
      ],
    );

    return rows
        .map(
          _placeFromRow,
        )
        .toList();
  }

  NavigationPlace? getHome() {
    if (_database == null) {
      return null;
    }

    final ResultSet rows = _database!.select(
      '''
      SELECT *
      FROM places
      WHERE is_home = 1
      LIMIT 1;
      ''',
    );

    if (rows.isEmpty) {
      return null;
    }

    return _placeFromRow(
      rows.first,
    );
  }

  NavigationPlace? getWork() {
    if (_database == null) {
      return null;
    }

    final ResultSet rows = _database!.select(
      '''
      SELECT *
      FROM places
      WHERE is_work = 1
      LIMIT 1;
      ''',
    );

    if (rows.isEmpty) {
      return null;
    }

    return _placeFromRow(
      rows.first,
    );
  }

  Future<NavigationPlace> addPlace({
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    bool favourite = false,
    bool isHome = false,
    bool isWork = false,
    String? category,
  }) async {
    await initialise();

    final Database db = _requireDatabase();

    if (isHome) {
      db.execute(
        '''
        UPDATE places
        SET is_home = 0;
        ''',
      );
    }

    if (isWork) {
      db.execute(
        '''
        UPDATE places
        SET is_work = 0;
        ''',
      );
    }

    db.execute(
      '''
      INSERT INTO places (
        name,
        address,
        latitude,
        longitude,
        category,
        favourite,
        is_home,
        is_work,
        visit_count
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0);
      ''',
      <Object?>[
        name,
        address,
        latitude,
        longitude,
        category,
        favourite ? 1 : 0,
        isHome ? 1 : 0,
        isWork ? 1 : 0,
      ],
    );

    final int id = db.lastInsertRowId;

    final NavigationPlace place = NavigationPlace(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      favourite: favourite,
      isHome: isHome,
      isWork: isWork,
      visitCount: 0,
      lastVisited: null,
    );

    await refresh();

    return place;
  }

  Future<void> deletePlace(
    NavigationPlace place,
  ) async {
    final int? id = place.id;

    if (id == null) {
      return;
    }

    final Database db = _requireDatabase();

    db.execute(
      '''
      DELETE FROM places
      WHERE id = ?;
      ''',
      <Object?>[
        id,
      ],
    );

    await refresh();
  }

  Future<void> toggleFavourite(
    NavigationPlace place,
  ) async {
    final int? id = place.id;

    if (id == null) {
      return;
    }

    final Database db = _requireDatabase();

    db.execute(
      '''
      UPDATE places
      SET favourite = ?
      WHERE id = ?;
      ''',
      <Object?>[
        place.favourite ? 0 : 1,
        id,
      ],
    );

    await refresh();
  }

  Future<void> setHome(
    NavigationPlace place,
  ) async {
    final int? id = place.id;

    if (id == null) {
      return;
    }

    final Database db = _requireDatabase();

    db.execute(
      '''
      UPDATE places
      SET is_home = 0;
      ''',
    );

    db.execute(
      '''
      UPDATE places
      SET is_home = 1
      WHERE id = ?;
      ''',
      <Object?>[
        id,
      ],
    );

    await refresh();
  }

  Future<void> setWork(
    NavigationPlace place,
  ) async {
    final int? id = place.id;

    if (id == null) {
      return;
    }

    final Database db = _requireDatabase();

    db.execute(
      '''
      UPDATE places
      SET is_work = 0;
      ''',
    );

    db.execute(
      '''
      UPDATE places
      SET is_work = 1
      WHERE id = ?;
      ''',
      <Object?>[
        id,
      ],
    );

    await refresh();
  }

  Future<void> markVisited(
    NavigationPlace place,
  ) async {
    final int? id = place.id;

    if (id == null) {
      return;
    }

    final Database db = _requireDatabase();

    final String now = DateTime.now().toIso8601String();

    db.execute(
      '''
      UPDATE places
      SET
        visit_count = visit_count + 1,
        last_visited = ?
      WHERE id = ?;
      ''',
      <Object?>[
        now,
        id,
      ],
    );

    await refresh();
  }

  NavigationPlace _placeFromRow(
    Row row,
  ) {
    final String? lastVisitedText = row['last_visited'] as String?;

    return NavigationPlace(
      id: row['id'] as int,
      name: row['name'] as String,
      address: row['address'] as String?,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      favourite: row['favourite'] == 1,
      isHome: row['is_home'] == 1,
      isWork: row['is_work'] == 1,
      visitCount: row['visit_count'] as int,
      lastVisited: lastVisitedText == null
          ? null
          : DateTime.tryParse(
              lastVisitedText,
            ),
    );
  }

  Database _requireDatabase() {
    final Database? db = _database;

    if (db == null) {
      throw StateError(
        'NavigationPlaceService has not been initialised.',
      );
    }

    return db;
  }

  void close() {
    _database?.close();

    _database = null;

    databaseInstalled.value = false;
  }
}
