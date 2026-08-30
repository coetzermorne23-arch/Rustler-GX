import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/device_wire_model.dart';
import '../models/entity_wire_model.dart';
import '../models/hub_message.dart';

import 'device_registry_service.dart';
import 'entity_service.dart';

class HubServerService {
  HubServerService._();

  static final HubServerService instance = HubServerService._();

  final EntityService entities = EntityService.instance;

  final DeviceRegistryService devices = DeviceRegistryService.instance;

  HttpServer? _server;

  final Set<WebSocket> _clients = <WebSocket>{};

  VoidCallback? _entityListener;
  VoidCallback? _deviceListener;

  bool get isRunning => _server != null;

  int? get port => _server?.port;

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

    _deviceListener = () {
      unawaited(
        _broadcastDevices(),
      );
    };

    entities.entities.addListener(
      _entityListener!,
    );

    devices.devices.addListener(
      _deviceListener!,
    );

    unawaited(
      _listen(),
    );
  }

  Future<void> _listen() async {
    final HttpServer? server = _server;

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
            ..statusCode = HttpStatus.internalServerError
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode(
                {
                  'error': error.toString(),
                },
              ),
            );

          await request.response.close();
        } catch (_) {}
      }
    }
  }

  Future<void> _handleRequest(
    HttpRequest request,
  ) async {
    final String path = request.uri.path;

    if (path == '/status') {
      await _jsonResponse(
        request,
        {
          'name': 'Rustler GX Hub',
          'online': true,
          'devices': devices.devices.value.length,
          'entities': entities.entities.value.length,
          'clients': _clients.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return;
    }

    if (path == '/devices') {
      await _jsonResponse(
        request,
        _deviceJsonList(),
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
      ..statusCode = HttpStatus.notFound
      ..write(
        'Rustler GX Hub',
      );

    await request.response.close();
  }

  Future<void> _jsonResponse(
    HttpRequest request,
    Object value,
  ) async {
    request.response.headers.contentType = ContentType.json;

    request.response.write(
      jsonEncode(
        value,
      ),
    );

    await request.response.close();
  }

  List<Map<String, dynamic>> _entityJsonList() {
    return entities.entities.value.values
        .map(
          (entity) => EntityWireModel.fromEntity(
            entity,
          ).toJson(),
        )
        .toList();
  }

  List<Map<String, dynamic>> _deviceJsonList() {
    return devices.devices.value.values
        .map(
          (device) => DeviceWireModel.fromDevice(
            device,
          ).toJson(),
        )
        .toList();
  }

  Future<void> _upgradeWebSocket(
    HttpRequest request,
  ) async {
    if (!WebSocketTransformer.isUpgradeRequest(
      request,
    )) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(
          'WebSocket upgrade required',
        );

      await request.response.close();

      return;
    }

    final WebSocket socket = await WebSocketTransformer.upgrade(
      request,
    );

    _clients.add(
      socket,
    );

    debugPrint(
      'Hub client connected. '
      'Clients: ${_clients.length}',
    );

    socket.add(
      HubMessage(
        type: 'devices',
        data: {
          'items': _deviceJsonList(),
        },
      ).encode(),
    );

    socket.add(
      HubMessage(
        type: 'entities',
        data: {
          'items': _entityJsonList(),
        },
      ).encode(),
    );

    socket.listen(
      (message) {
        _handleClientMessage(
          socket,
          message,
        );
      },
      onDone: () {
        _clients.remove(
          socket,
        );

        debugPrint(
          'Hub client disconnected. '
          'Clients: ${_clients.length}',
        );
      },
      onError: (error) {
        _clients.remove(
          socket,
        );

        debugPrint(
          'Hub WebSocket error: $error',
        );
      },
      cancelOnError: true,
    );
  }

  void _handleClientMessage(
    WebSocket socket,
    dynamic raw,
  ) {
    if (raw is! String) {
      return;
    }

    try {
      final HubMessage message = HubMessage.decode(
        raw,
      );

      switch (message.type) {
        case 'ping':
          socket.add(
            HubMessage(
              type: 'pong',
              data: {
                'timestamp': DateTime.now().toIso8601String(),
              },
            ).encode(),
          );
          break;

        case 'request_devices':
          socket.add(
            HubMessage(
              type: 'devices',
              data: {
                'items': _deviceJsonList(),
              },
            ).encode(),
          );
          break;

        case 'request_entities':
          socket.add(
            HubMessage(
              type: 'entities',
              data: {
                'items': _entityJsonList(),
              },
            ).encode(),
          );
          break;
      }
    } catch (error) {
      debugPrint(
        'Invalid Hub client message: $error',
      );
    }
  }

  Future<void> _broadcastEntities() async {
    final String message = HubMessage(
      type: 'entities',
      data: {
        'items': _entityJsonList(),
      },
    ).encode();

    await _broadcast(
      message,
    );
  }

  Future<void> _broadcastDevices() async {
    final String message = HubMessage(
      type: 'devices',
      data: {
        'items': _deviceJsonList(),
      },
    ).encode();

    await _broadcast(
      message,
    );
  }

  Future<void> _broadcast(
    String message,
  ) async {
    if (_clients.isEmpty) {
      return;
    }

    final List<WebSocket> dead = <WebSocket>[];

    for (final WebSocket socket in _clients) {
      try {
        socket.add(
          message,
        );
      } catch (_) {
        dead.add(
          socket,
        );
      }
    }

    for (final WebSocket socket in dead) {
      _clients.remove(
        socket,
      );

      try {
        await socket.close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    final VoidCallback? entityListener = _entityListener;

    final VoidCallback? deviceListener = _deviceListener;

    if (entityListener != null) {
      entities.entities.removeListener(
        entityListener,
      );
    }

    if (deviceListener != null) {
      devices.devices.removeListener(
        deviceListener,
      );
    }

    _entityListener = null;
    _deviceListener = null;

    for (final WebSocket socket in _clients) {
      try {
        await socket.close();
      } catch (_) {}
    }

    _clients.clear();

    final HttpServer? server = _server;

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
