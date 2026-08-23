import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/entity_wire_model.dart';
import '../models/hub_message.dart';
import '../models/rustler_entity.dart';
import 'entity_service.dart';
import 'rustler_gx_config_service.dart';

enum HubConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class HubClientService {
  HubClientService._();

  static final HubClientService instance =
      HubClientService._();

  final EntityService _entityService =
      EntityService.instance;

  final RustlerGxConfigService _config =
      RustlerGxConfigService.instance;

  final ValueNotifier<HubConnectionState>
      connectionState =
      ValueNotifier<HubConnectionState>(
    HubConnectionState.disconnected,
  );

  final ValueNotifier<String?> lastError =
      ValueNotifier<String?>(null);

  final ValueNotifier<DateTime?> lastMessageAt =
      ValueNotifier<DateTime?>(null);

  WebSocket? _socket;

  Timer? _reconnectTimer;

  bool _shouldReconnect = false;
  bool _connecting = false;

  static const Duration _reconnectDelay =
      Duration(seconds: 5);

  bool get isConnected =>
      connectionState.value ==
      HubConnectionState.connected;

  // =========================================================
  // CONNECT
  // =========================================================

  Future<void> connect() async {
    if (_connecting || isConnected) {
      return;
    }

    _connecting = true;
    _shouldReconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    connectionState.value =
        HubConnectionState.connecting;

    lastError.value = null;

    try {
      final Uri uri =
          await _config.getHubWebSocketUri();

      debugPrint(
        'Connecting to Rustler GX Hub: $uri',
      );

      final WebSocket socket =
          await WebSocket.connect(
        uri.toString(),
      ).timeout(
        const Duration(seconds: 10),
      );

      _socket = socket;

      connectionState.value =
          HubConnectionState.connected;

      lastError.value = null;

      debugPrint(
        'Connected to Rustler GX Hub',
      );

      socket.listen(
        _handleSocketMessage,
        onDone: _handleDisconnect,
        onError: (Object error) {
          _handleSocketError(error);
        },
        cancelOnError: true,
      );
    } catch (error) {
      lastError.value =
          error.toString();

      debugPrint(
        'Hub connection failed: $error',
      );

      connectionState.value =
          HubConnectionState.disconnected;

      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  // =========================================================
  // INCOMING WEBSOCKET DATA
  // =========================================================

  void _handleSocketMessage(
    dynamic rawMessage,
  ) {
    if (rawMessage is! String) {
      return;
    }

    lastMessageAt.value =
        DateTime.now();

    try {
      final HubMessage message =
          HubMessage.decode(
        rawMessage,
      );

      switch (message.type) {
        case 'entities':
          _handleEntitiesMessage(
            message,
          );
          break;

        case 'entity':
          _handleSingleEntityMessage(
            message,
          );
          break;

        case 'ping':
          _send(
            HubMessage(
              type: 'pong',
              data: {
                'timestamp':
                    DateTime.now()
                        .toIso8601String(),
              },
            ),
          );
          break;

        default:
          debugPrint(
            'Unknown Hub message: '
            '${message.type}',
          );
      }
    } catch (error) {
      debugPrint(
        'Invalid Hub message: $error',
      );
    }
  }

  void _handleEntitiesMessage(
    HubMessage message,
  ) {
    final dynamic rawItems =
        message.data['items'];

    if (rawItems is! List) {
      return;
    }

    final Set<String> receivedIds =
        <String>{};

    for (final dynamic rawItem
        in rawItems) {
      if (rawItem is! Map) {
        continue;
      }

      try {
        final EntityWireModel wire =
            EntityWireModel.fromJson(
          Map<String, dynamic>.from(
            rawItem,
          ),
        );

        final RustlerEntity remoteEntity =
            _convertRemoteEntity(
          wire.toEntity(),
        );

        receivedIds.add(
          remoteEntity.id,
        );

        _entityService.upsert(
          remoteEntity,
        );
      } catch (error) {
        debugPrint(
          'Failed to decode Hub entity: '
          '$error',
        );
      }
    }

    _markMissingHubEntitiesUnavailable(
      receivedIds,
    );
  }

  void _handleSingleEntityMessage(
    HubMessage message,
  ) {
    try {
      final EntityWireModel wire =
          EntityWireModel.fromJson(
        message.data,
      );

      _entityService.upsert(
        _convertRemoteEntity(
          wire.toEntity(),
        ),
      );
    } catch (error) {
      debugPrint(
        'Failed to decode Hub entity: '
        '$error',
      );
    }
  }

  // =========================================================
  // REMOTE ENTITY NAMESPACE
  // =========================================================

  RustlerEntity _convertRemoteEntity(
    RustlerEntity entity,
  ) {
    // Local BLE and remote Hub devices may expose the
    // same entity ID. Prefix Hub entities so they can
    // coexist safely in EntityService.

    final String remoteId =
        entity.id.startsWith('hub.')
            ? entity.id
            : 'hub.${entity.id}';

    return RustlerEntity(
      id: remoteId,
      name: entity.name,
      type: entity.type,
      value: entity.value,
      unit: entity.unit,
      source: 'hub:${entity.source}',
      available: entity.available,
      updatedAt: entity.updatedAt,
    );
  }

  void _markMissingHubEntitiesUnavailable(
    Set<String> receivedIds,
  ) {
    final Map<String, RustlerEntity>
        current =
        _entityService.entities.value;

    for (final RustlerEntity entity
        in current.values) {
      if (!entity.id.startsWith('hub.')) {
        continue;
      }

      if (receivedIds.contains(
        entity.id,
      )) {
        continue;
      }

      _entityService.upsert(
        RustlerEntity(
          id: entity.id,
          name: entity.name,
          type: entity.type,
          value: entity.value,
          unit: entity.unit,
          source: entity.source,
          available: false,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // =========================================================
  // SEND
  // =========================================================

  void _send(
    HubMessage message,
  ) {
    final WebSocket? socket =
        _socket;

    if (socket == null ||
        !isConnected) {
      return;
    }

    try {
      socket.add(
        message.encode(),
      );
    } catch (error) {
      debugPrint(
        'Hub send failed: $error',
      );
    }
  }

  void sendPing() {
    _send(
      HubMessage(
        type: 'ping',
        data: {
          'timestamp':
              DateTime.now()
                  .toIso8601String(),
        },
      ),
    );
  }

  // =========================================================
  // DISCONNECT / RECONNECT
  // =========================================================

  void _handleSocketError(
    Object error,
  ) {
    lastError.value =
        error.toString();

    debugPrint(
      'Hub socket error: $error',
    );
  }

  void _handleDisconnect() {
    _socket = null;

    if (!_shouldReconnect) {
      connectionState.value =
          HubConnectionState.disconnected;

      return;
    }

    debugPrint(
      'Rustler GX Hub disconnected',
    );

    _markAllHubEntitiesUnavailable();

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) {
      return;
    }

    if (_reconnectTimer?.isActive ??
        false) {
      return;
    }

    connectionState.value =
        HubConnectionState.reconnecting;

    _reconnectTimer = Timer(
      _reconnectDelay,
      () {
        _reconnectTimer = null;

        unawaited(
          connect(),
        );
      },
    );
  }

  void _markAllHubEntitiesUnavailable() {
    final List<RustlerEntity> remote =
        _entityService
            .entities
            .value
            .values
            .where(
              (entity) =>
                  entity.id
                      .startsWith('hub.'),
            )
            .toList();

    for (final entity in remote) {
      _entityService.upsert(
        RustlerEntity(
          id: entity.id,
          name: entity.name,
          type: entity.type,
          value: entity.value,
          unit: entity.unit,
          source: entity.source,
          available: false,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final WebSocket? socket =
        _socket;

    _socket = null;

    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {}
    }

    connectionState.value =
        HubConnectionState.disconnected;

    _markAllHubEntitiesUnavailable();

    debugPrint(
      'Rustler GX Hub client stopped',
    );
  }

  // =========================================================
  // MANUAL RECONNECT
  // =========================================================

  Future<void> reconnect() async {
    await disconnect();

    _shouldReconnect = true;

    await connect();
  }
}