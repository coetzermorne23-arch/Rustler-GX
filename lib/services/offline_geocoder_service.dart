import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/navigation_place.dart';

class OfflineGeocoderService {
  OfflineGeocoderService._();
  static final OfflineGeocoderService instance = OfflineGeocoderService._();

  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);
  final ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<int> placeCount = ValueNotifier<int>(0);
  Database? _db;

  Future<String> get defaultPath async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/navigation');
    if (!await dir.exists()) await dir.create(recursive: true);
    return '${dir.path}/south_africa_search.sqlite';
  }

  Future<void> initialise() async {
    if (_db != null) return;
    final path = await defaultPath;
    if (await File(path).exists()) await open(path);
  }

  Future<void> open(String path) async {
    loading.value = true;
    error.value = null;
    try {
      _db?.close();
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      final schema = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='places'",
      );
      if (schema.isEmpty) {
        db.close();
        throw StateError('Invalid RigOS search database');
      }
      _db = db;
      final count = db.select('SELECT COUNT(*) AS total FROM places');
      placeCount.value = (count.first['total'] as num).toInt();
      ready.value = true;
    } catch (e) {
      ready.value = false;
      error.value = 'Offline search DB error: $e';
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  Future<void> chooseDatabase() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db'],
    );
    if (picked == null || picked.path == null) return;
    final dest = await defaultPath;
    _db?.close();
    _db = null;
    final file = File(dest);
    if (await file.exists()) await file.delete();
    await File(picked.path!).copy(dest);
    await open(dest);
  }

  Future<List<NavigationPlace>> search(
    String value, {
    double? latitude,
    double? longitude,
    int limit = 40,
  }) async {
    await initialise();
    final db = _db;
    final raw = value.trim();

    // Direct coordinate entry: -25.7479, 28.2293
    final coordinate = RegExp(
      r'^\s*(-?\d{1,2}(?:\.\d+)?)\s*[,; ]\s*(-?\d{1,3}(?:\.\d+)?)\s*$',
    ).firstMatch(raw);
    if (coordinate != null) {
      final lat = double.tryParse(coordinate.group(1)!);
      final lon = double.tryParse(coordinate.group(2)!);
      if (lat != null && lon != null && lat.abs() <= 90 && lon.abs() <= 180) {
        return <NavigationPlace>[
          NavigationPlace(
              name: 'Coordinates $lat, $lon', latitude: lat, longitude: lon),
        ];
      }
    }

    final query = _normalise(raw);
    if (db == null || query.length < 2) return const [];
    final tokens = query.split(' ').where((e) => e.isNotEmpty).take(8).toList();

    // Pass 1 is strict: every word must occur. Pass 2 is forgiving and is
    // important for OSM names where a business/street/suburb is not stored in
    // exactly the same display string the user typed.
    final strictWhere =
        List.filled(tokens.length, 'search_text LIKE ?').join(' AND ');
    final strictRows = db.select(
      'SELECT display_name,latitude,longitude,importance FROM places '
      'WHERE $strictWhere ORDER BY CASE WHEN search_text LIKE ? THEN 0 ELSE 1 END, '
      'importance DESC, display_name COLLATE NOCASE LIMIT ?',
      <Object?>[...tokens.map((e) => '%$e%'), '$query%', limit * 5],
    );
    final looseWhere =
        List.filled(tokens.length, 'search_text LIKE ?').join(' OR ');
    final looseRows = strictRows.length >= 8
        ? db.select(
            'SELECT display_name,latitude,longitude,importance FROM places WHERE 0')
        : db.select(
            'SELECT display_name,latitude,longitude,importance FROM places '
            'WHERE $looseWhere ORDER BY CASE WHEN search_text LIKE ? THEN 0 ELSE 1 END, '
            'importance DESC, display_name COLLATE NOCASE LIMIT ?',
            <Object?>[...tokens.map((e) => '%$e%'), '$query%', limit * 10],
          );
    final rows = [...strictRows, ...looseRows];
    final ranked = <String, _Ranked>{};
    for (final row in rows) {
      final lat = (row['latitude'] as num).toDouble();
      final lon = (row['longitude'] as num).toDouble();
      final name = row['display_name'] as String;
      final normal = _normalise(name);
      final importance = (row['importance'] as num).toDouble();
      final matches = tokens.where(normal.contains).length;
      if (matches == 0) continue;
      final proximity = latitude == null || longitude == null
          ? 0.0
          : ((lat - latitude).abs() + (lon - longitude).abs()) / 8.0;
      final score = importance -
          proximity +
          matches * 3 +
          (normal.startsWith(query) ? 10 : 0);
      final key = '${lat.toStringAsFixed(5)}|${lon.toStringAsFixed(5)}|$normal';
      final item = _Ranked(
          score, NavigationPlace(name: name, latitude: lat, longitude: lon));
      if (!ranked.containsKey(key) || ranked[key]!.score < score) {
        ranked[key] = item;
      }
    }
    final values = ranked.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return values.take(limit).map((e) => e.place).toList(growable: false);
  }

  String _normalise(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _Ranked {
  final double score;
  final NavigationPlace place;
  const _Ranked(this.score, this.place);
}
