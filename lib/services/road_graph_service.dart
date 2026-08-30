import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/road_graph_models.dart';

class RoadGraphService {
  RoadGraphService._();

  static final RoadGraphService instance = RoadGraphService._();

  Database? _database;

  bool get ready => _database != null;

  Future<void> initialise() async {
    if (_database != null) {
      return;
    }

    final Directory support = await getApplicationSupportDirectory();

    final Directory directory = Directory(
      '${support.path}/navigation',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    final String path = '${directory.path}/rustler_roads.db';

    _database = sqlite3.open(
      path,
    );

    _createTables();
  }

  void _createTables() {
    final Database db = _requireDatabase();

    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS road_nodes (
        id INTEGER PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      );
      ''',
    );

    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS road_edges (
        id INTEGER PRIMARY KEY,
        from_node INTEGER NOT NULL,
        to_node INTEGER NOT NULL,
        distance_metres REAL NOT NULL,
        speed_kmh REAL NOT NULL,
        road_name TEXT,
        one_way INTEGER NOT NULL DEFAULT 0
      );
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_edges_from_node
      ON road_edges(from_node);
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_edges_to_node
      ON road_edges(to_node);
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_nodes_latitude
      ON road_nodes(latitude);
      ''',
    );

    db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_nodes_longitude
      ON road_nodes(longitude);
      ''',
    );
  }

  bool get hasRoadData {
    final Database db = _requireDatabase();

    final ResultSet rows = db.select(
      '''
      SELECT COUNT(*) AS count
      FROM road_nodes;
      ''',
    );

    if (rows.isEmpty) {
      return false;
    }

    final int count = rows.first['count'] as int;

    return count > 0;
  }

  int get nodeCount {
    final Database db = _requireDatabase();

    final ResultSet rows = db.select(
      '''
      SELECT COUNT(*) AS count
      FROM road_nodes;
      ''',
    );

    return rows.first['count'] as int;
  }

  int get edgeCount {
    final Database db = _requireDatabase();

    final ResultSet rows = db.select(
      '''
      SELECT COUNT(*) AS count
      FROM road_edges;
      ''',
    );

    return rows.first['count'] as int;
  }

  RoadNode? getNode(
    int id,
  ) {
    final Database db = _requireDatabase();

    final ResultSet rows = db.select(
      '''
      SELECT *
      FROM road_nodes
      WHERE id = ?
      LIMIT 1;
      ''',
      <Object?>[
        id,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _nodeFromRow(
      rows.first,
    );
  }

  Map<int, RoadNode> getNodes(
    Iterable<int> ids,
  ) {
    final List<int> list = ids.toSet().toList();

    if (list.isEmpty) {
      return <int, RoadNode>{};
    }

    final Database db = _requireDatabase();

    final String placeholders = List<String>.filled(
      list.length,
      '?',
    ).join(',');

    final ResultSet rows = db.select(
      '''
      SELECT *
      FROM road_nodes
      WHERE id IN ($placeholders);
      ''',
      list,
    );

    return <int, RoadNode>{
      for (final Row row in rows) row['id'] as int: _nodeFromRow(row),
    };
  }

  List<RoadEdge> getOutgoingEdges(
    int nodeId,
  ) {
    final Database db = _requireDatabase();

    final ResultSet rows = db.select(
      '''
      SELECT *
      FROM road_edges
      WHERE from_node = ?;
      ''',
      <Object?>[
        nodeId,
      ],
    );

    return rows
        .map(
          _edgeFromRow,
        )
        .toList();
  }

  RoadNode? findNearestNode(
    double latitude,
    double longitude, {
    double searchRadiusDegrees = 0.03,
  }) {
    final Database db = _requireDatabase();

    ResultSet rows = db.select(
      '''
      SELECT *,
        (
          (latitude - ?) *
          (latitude - ?)
          +
          (longitude - ?) *
          (longitude - ?)
        ) AS distance_score
      FROM road_nodes
      WHERE
        latitude BETWEEN ? AND ?
        AND longitude BETWEEN ? AND ?
      ORDER BY distance_score ASC
      LIMIT 1;
      ''',
      <Object?>[
        latitude,
        latitude,
        longitude,
        longitude,
        latitude - searchRadiusDegrees,
        latitude + searchRadiusDegrees,
        longitude - searchRadiusDegrees,
        longitude + searchRadiusDegrees,
      ],
    );

    if (rows.isEmpty) {
      rows = db.select(
        '''
        SELECT *,
          (
            (latitude - ?) *
            (latitude - ?)
            +
            (longitude - ?) *
            (longitude - ?)
          ) AS distance_score
        FROM road_nodes
        ORDER BY distance_score ASC
        LIMIT 1;
        ''',
        <Object?>[
          latitude,
          latitude,
          longitude,
          longitude,
        ],
      );
    }

    if (rows.isEmpty) {
      return null;
    }

    return _nodeFromRow(
      rows.first,
    );
  }

  RoadNode _nodeFromRow(
    Row row,
  ) {
    return RoadNode(
      id: row['id'] as int,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
    );
  }

  RoadEdge _edgeFromRow(
    Row row,
  ) {
    return RoadEdge(
      id: row['id'] as int,
      fromNode: row['from_node'] as int,
      toNode: row['to_node'] as int,
      distanceMetres: (row['distance_metres'] as num).toDouble(),
      speedKmh: (row['speed_kmh'] as num).toDouble(),
      roadName: row['road_name'] as String?,
      oneWay: row['one_way'] == 1,
    );
  }

  Database _requireDatabase() {
    final Database? db = _database;

    if (db == null) {
      throw StateError(
        'RoadGraphService has not been initialised.',
      );
    }

    return db;
  }

  void close() {
    _database?.close();

    _database = null;
  }
}
