import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/entity_wire_model.dart';
import '../models/hub_message.dart';
import 'entity_service.dart';

class HubServerService {
  HubServerService._();

  static final HubServerService instance =
      HubServerService._();

  final EntityService entities =
      EntityService.instance;

  HttpServer? _server;

  final Set<WebSocket> _clients =
      <WebSocket>{};

  VoidCallback? _entityListener;

  bool get isRunning =>
      _server != null;

  int? get port =>
      _server?.port;

  Future<void> start({
    int port = 8765,
  }) async {
    if (_server != null) {
      return;
    }

    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      port,
    );

    debugPrint(
      'Rustler GX Hub running on port '
      '${_server!.port}',
    );

    _entityListener = () {
      unawaited(
        _broadcastEntities(),
      );
    };

    entities.entities.addListener(
      _entityListener!,
    );

    unawaited(
      _listen(),
    );
  }

  Future<void> _listen() async {
    final HttpServer? server =
        _server;

    if (server == null) {
      return;
    }

    await for (final request in server) {
      try {
        await _handleRequest(
          request,
        );
      } catch (error) {
        debugPrint(
          'Hub request error: $error',
        );

        try {
          request.response
            ..statusCode =
                HttpStatus.internalServerError
            ..write(
              jsonEncode({
                'error':
                    error.toString(),
              }),
            );

          await request.response.close();
        } catch (_) {}
      }
    }
  }

  Future<void> _handleRequest(
    HttpRequest request,
  ) async {
    final String path =
        request.uri.path;

    if (path == '/status') {
      await _jsonResponse(
        request,
        {
          'name': 'Rustler GX Hub',
          'online': true,
          'entities':
              entities.entities.value.length,
          'clients':
              _clients.length,
          'timestamp':
              DateTime.now()
                  .toIso8601String(),
        },
      );

      return;
    }

    if (path == '/entities') {
      await _jsonResponse(
        request,
        _entityJsonList(),
      );

      return;
    }

    if (path == '/ws') {
      await _upgradeWebSocket(
        request,
      );

      return;
    }

    request.response
      ..statusCode =
          HttpStatus.notFound
      ..write(
        'Rustler GX Hub',
      );

    await request.response.close();
  }

  Future<void> _jsonResponse(
    HttpRequest request,
    Object value,
  ) async {
    request.response.headers.contentType =
        ContentType.json;

    request.response.write(
      jsonEncode(value),
    );

    await request.response.close();
  }

  List<Map<String, dynamic>>
      _entityJsonList() {
    return entities.entities.value.values
        .map(
          (entity) =>
              EntityWireModel.fromEntity(
            entity,
          ).toJson(),
        )
        .toList();
  }

  Future<void> _upgradeWebSocket(
    HttpRequest request,
  ) async {
    if (!WebSocketTransformer
        .isUpgradeRequest(request)) {
      request.response
        ..statusCode =
            HttpStatus.badRequest
        ..write(
          'WebSocket upgrade required',
        );

      await request.response.close();
      return;
    }

    final WebSocket socket =
        await WebSocketTransformer.upgrade(
      request,
    );

    _clients.add(socket);

    debugPrint(
      'Hub client connected. '
      'Clients: ${_clients.length}',
    );

    socket.add(
      HubMessage(
        type: 'entities',
        data: {
          'items':
              _entityJsonList(),
        },
      ).encode(),
    );

    socket.listen(
      (message) {
        debugPrint(
          'Hub client message: $message',
        );
      },
      onDone: () {
        _clients.remove(socket);

        debugPrint(
          'Hub client disconnected. '
          'Clients: ${_clients.length}',
        );
      },
      onError: (error) {
        _clients.remove(socket);

        debugPrint(
          'Hub WebSocket error: $error',
        );
      },
      cancelOnError: true,
    );
  }

  Future<void> _broadcastEntities() async {
    if (_clients.isEmpty) {
      return;
    }

    final String message =
        HubMessage(
      type: 'entities',
      data: {
        'items':
            _entityJsonList(),
      },
    ).encode();

    final dead =
        <WebSocket>[];

    for (final socket in _clients) {
      try {
        socket.add(
          message,
        );
      } catch (_) {
        dead.add(socket);
      }
    }

    for (final socket in dead) {
      _clients.remove(socket);

      try {
        await socket.close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    final listener =
        _entityListener;

    if (listener != null) {
      entities.entities.removeListener(
        listener,
      );
    }

    _entityListener = null;

    for (final socket in _clients) {
      try {
        await socket.close();
      } catch (_) {}
    }

    _clients.clear();

    final server =
        _server;

    _server = null;

    if (server != null) {
      await server.close(
        force: true,
      );
    }

    debugPrint(
      'Rustler GX Hub stopped',
    );
  }
}