import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart'
    as vt;
import 'package:flutter_map_vector_tiles_mbtiles/flutter_map_vector_tiles_mbtiles.dart';
import 'package:path_provider/path_provider.dart';

class VectorOfflineMapService {
  VectorOfflineMapService._();

  static final VectorOfflineMapService instance =
      VectorOfflineMapService._();

  final ValueNotifier<String?> mapPath =
      ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<String?> mapName =
      ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<String?> error =
      ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<bool> loading =
      ValueNotifier<bool>(
    false,
  );

  vt.Style? _style;

  MbTilesVectorTileProvider? _provider;

  vt.Style? get style =>
      _style;

  MbTilesVectorTileProvider? get provider =>
      _provider;

  bool get ready =>
      _style != null &&
      _provider != null;

  Future<Directory> _mapDirectory() async {
    final Directory support =
        await getApplicationSupportDirectory();

    final Directory directory =
        Directory(
      '${support.path}/maps',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  Future<String> get defaultMapPath async {
    final Directory directory =
        await _mapDirectory();

    return '${directory.path}/south_africa.mbtiles';
  }

  Future<void> loadDefaultMap() async {
    final String path =
        await defaultMapPath;

    final File file =
        File(path);

    if (!await file.exists()) {
      mapPath.value =
          null;

      mapName.value =
          null;

      return;
    }

    await loadMap(
      path,
    );
  }

  Future<void> chooseMap() async {
    error.value =
        null;

    final PlatformFile? picked =
        await FilePicker.pickFile(
      type:
          FileType.custom,
      allowedExtensions:
          <String>[
        'mbtiles',
      ],
    );

    if (picked == null) {
      return;
    }

    final String? sourcePath =
        picked.path;

    if (sourcePath == null) {
      error.value =
          'Selected map has no local file path.';

      return;
    }

    loading.value =
        true;

    try {
      final File source =
          File(
        sourcePath,
      );

      final String destinationPath =
          await defaultMapPath;

      final File destination =
          File(
        destinationPath,
      );

      if (await destination.exists()) {
        await destination.delete();
      }

      await source.copy(
        destinationPath,
      );

      await loadMap(
        destinationPath,
      );
    } catch (exception) {
      error.value =
          'Could not import map: $exception';

      rethrow;
    } finally {
      loading.value =
          false;
    }
  }

  Future<void> loadMap(
    String path,
  ) async {
    loading.value =
        true;

    error.value =
        null;

    try {
      await _disposeCurrentMap();

      final File file =
          File(path);

      if (!await file.exists()) {
        throw StateError(
          'Map file does not exist.',
        );
      }

      final MbTilesVectorTileProvider archive =
          await MbTilesVectorTileProvider.open(
        path,
      );

      _provider =
          archive;

      final vt.Style loadedStyle =
          await vt.StyleReader(
        uri:
            'asset://assets/map_styles/rustler_dark.json',
        resolveProvider:
            (
          String id,
        ) async {
          if (id ==
              'openmaptiles') {
            return archive;
          }

          return null;
        },
      ).read();

      _style =
          loadedStyle;

      mapPath.value =
          path;

      mapName.value =
          file.uri.pathSegments.isEmpty
              ? 'South Africa'
              : file.uri.pathSegments.last;
    } catch (exception) {
      error.value =
          'Could not load offline map: $exception';

      await _disposeCurrentMap();

      mapPath.value =
          null;

      mapName.value =
          null;

      rethrow;
    } finally {
      loading.value =
          false;
    }
  }

  Future<void> removeMap() async {
    final String? path =
        mapPath.value;

    await _disposeCurrentMap();

    if (path != null) {
      final File file =
          File(path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    mapPath.value =
        null;

    mapName.value =
        null;

    error.value =
        null;
  }

  Future<void> _disposeCurrentMap() async {
    final vt.Style? oldStyle =
        _style;

    _style =
        null;

    _provider =
        null;

    if (oldStyle != null) {
      oldStyle.dispose();
    }
  }

  Future<void> dispose() async {
    await _disposeCurrentMap();

    mapPath.dispose();
    mapName.dispose();
    error.dispose();
    loading.dispose();
  }
}