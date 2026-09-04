import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/device_wire_model.dart';
import '../models/entity_wire_model.dart';
import '../models/hub_message.dart';
import '../models/rustler_device.dart';
import '../models/rustler_entity.dart';

import 'device_registry_service.dart';
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

  static final HubClientService instance = HubClientService._();

  final EntityService _entityService = EntityService.instance;

  final DeviceRegistryService _deviceRegistry = DeviceRegistryService.instance;

  final RustlerGxConfigService _config = RustlerGxConfigService.instance;

  final ValueNotifier<HubConnectionState> connectionState =
      ValueNotifier<HubConnectionState>(
    HubConnectionState.disconnected,
  );

  final ValueNotifier<String?> lastError = ValueNotifier<String?>(
    null,
  );

  final ValueNotifier<DateTime?> lastMessageAt = ValueNotifier<DateTime?>(
    null,
  );

  WebSocket? _socket;

  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _shouldReconnect = false;
  bool _connecting = false;

  static const Duration _reconnectDelay = Duration(
    seconds: 5,
  );

  static const Duration _pingInterval = Duration(
    seconds: 20,
  );

  bool get isConnected => connectionState.value == HubConnectionState.connected;

  Future<void> connect() async {
    if (_connecting || isConnected) {
      return;
    }

    _connecting = true;
    _shouldReconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    connectionState.value = HubConnectionState.connecting;

    lastError.value = null;

    try {
      final Uri uri = await _config.getHubWebSocketUri();

      debugPrint(
        'Connecting to RigOS Hub: $uri',
      );

      final WebSocket socket = await WebSocket.connect(
        uri.toString(),
      ).timeout(
        const Duration(
          seconds: 10,
        ),
      );

      _socket = socket;

      connectionState.value = HubConnectionState.connected;

      lastError.value = null;

      _startPingTimer();

      socket.listen(
        _handleSocketMessage,
        onDone: _handleDisconnect,
        onError: (
          Object error,
        ) {
          _handleSocketError(
            error,
          );
        },
        cancelOnError: true,
      );

      _send(
        const HubMessage(
          type: 'request_devices',
          data: {},
        ),
      );

      _send(
        const HubMessage(
          type: 'request_entities',
          data: {},
        ),
      );

      debugPrint(
        'Connected to RigOS Hub',
      );
    } catch (error) {
      lastError.value = error.toString();

      connectionState.value = HubConnectionState.disconnected;

      debugPrint(
        'Hub connection failed: $error',
      );

      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleSocketMessage(
    dynamic rawMessage,
  ) {
    if (rawMessage is! String) {
      return;
    }

    lastMessageAt.value = DateTime.now();

    try {
      final HubMessage message = HubMessage.decode(
        rawMessage,
      );

      switch (message.type) {
        case 'devices':
          _handleDevicesMessage(
            message,
          );
          break;

        case 'entities':
          _handleEntitiesMessage(
            message,
          );
          break;

        case 'device':
          _handleSingleDeviceMessage(
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
                'timestamp': DateTime.now().toIso8601String(),
              },
            ),
          );
          break;

        case 'pong':
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

  // =========================================================
  // DEVICES
  // =========================================================

  void _handleDevicesMessage(
    HubMessage message,
  ) {
    final dynamic rawItems = message.data['items'];

    if (rawItems is! List) {
      return;
    }

    final Set<String> receivedIds = <String>{};

    for (final dynamic item in rawItems) {
      if (item is! Map) {
        continue;
      }

      try {
        final DeviceWireModel wire = DeviceWireModel.fromJson(
          Map<String, dynamic>.from(
            item,
          ),
        );

        final RustlerDevice device = _convertRemoteDevice(
          wire.toDevice(),
        );

        receivedIds.add(
          device.id,
        );

        _deviceRegistry.upsertDevice(
          device,
        );
      } catch (error) {
        debugPrint(
          'Failed to decode Hub device: '
          '$error',
        );
      }
    }

    _markMissingHubDevicesUnavailable(
      receivedIds,
    );
  }

  void _handleSingleDeviceMessage(
    HubMessage message,
  ) {
    try {
      final DeviceWireModel wire = DeviceWireModel.fromJson(
        message.data,
      );

      _deviceRegistry.upsertDevice(
        _convertRemoteDevice(
          wire.toDevice(),
        ),
      );
    } catch (error) {
      debugPrint(
        'Failed to decode Hub device: '
        '$error',
      );
    }
  }

  RustlerDevice _convertRemoteDevice(
    RustlerDevice device,
  ) {
    final String remoteDeviceId =
        device.id.startsWith('hub.') ? device.id : 'hub.${device.id}';

    final List<String> remoteEntityIds = device.entityIds.map(
      (
        String id,
      ) {
        if (id.startsWith('hub.')) {
          return id;
        }

        return 'hub.$id';
      },
    ).toList();

    return RustlerDevice(
      id: remoteDeviceId,
      name: device.name,
      manufacturer: device.manufacturer,
      model: device.model,
      type: device.type,
      source: 'hub:${device.source}',
      available: device.available,
      updatedAt: device.updatedAt,
      entityIds: remoteEntityIds,
    );
  }

  void _markMissingHubDevicesUnavailable(
    Set<String> receivedIds,
  ) {
    final List<RustlerDevice> remote = _deviceRegistry.devices.value.values
        .where(
          (
            RustlerDevice device,
          ) =>
              device.id.startsWith(
            'hub.',
          ),
        )
        .toList();

    for (final RustlerDevice device in remote) {
      if (receivedIds.contains(
        device.id,
      )) {
        continue;
      }

      _deviceRegistry.upsertDevice(
        device.copyWith(
          available: false,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // =========================================================
  // ENTITIES
  // =========================================================

  void _handleEntitiesMessage(
    HubMessage message,
  ) {
    final dynamic rawItems = message.data['items'];

    if (rawItems is! List) {
      return;
    }

    final Set<String> receivedIds = <String>{};

    for (final dynamic rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }

      try {
        final EntityWireModel wire = EntityWireModel.fromJson(
          Map<String, dynamic>.from(
            rawItem,
          ),
        );

        final RustlerEntity remoteEntity = _convertRemoteEntity(
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
      final EntityWireModel wire = EntityWireModel.fromJson(
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

  RustlerEntity _convertRemoteEntity(
    RustlerEntity entity,
  ) {
    final String remoteId =
        entity.id.startsWith('hub.') ? entity.id : 'hub.${entity.id}';

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
    final List<RustlerEntity> remote = _entityService.entities.value.values
        .where(
          (
            RustlerEntity entity,
          ) =>
              entity.id.startsWith(
            'hub.',
          ),
        )
        .toList();

    for (final RustlerEntity entity in remote) {
      if (receivedIds.contains(
        entity.id,
      )) {
        continue;
      }

      _entityService.upsert(
        entity.copyWith(
          available: false,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // =========================================================
  // SEND / PING
  // =========================================================

  void _send(
    HubMessage message,
  ) {
    final WebSocket? socket = _socket;

    if (socket == null || !isConnected) {
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

  void _startPingTimer() {
    _pingTimer?.cancel();

    _pingTimer = Timer.periodic(
      _pingInterval,
      (_) {
        sendPing();
      },
    );
  }

  void sendPing() {
    _send(
      HubMessage(
        type: 'ping',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  // =========================================================
  // RECONNECT
  // =========================================================

  void _handleSocketError(
    Object error,
  ) {
    lastError.value = error.toString();

    debugPrint(
      'Hub socket error: $error',
    );
  }

  void _handleDisconnect() {
    _socket = null;

    _pingTimer?.cancel();
    _pingTimer = null;

    _markAllHubDataUnavailable();

    if (!_shouldReconnect) {
      connectionState.value = HubConnectionState.disconnected;

      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) {
      return;
    }

    if (_reconnectTimer?.isActive ?? false) {
      return;
    }

    connectionState.value = HubConnectionState.reconnecting;

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

  void _markAllHubDataUnavailable() {
    final List<RustlerEntity> entities = _entityService.entities.value.values
        .where(
          (
            RustlerEntity entity,
          ) =>
              entity.id.startsWith(
            'hub.',
          ),
        )
        .toList();

    for (final RustlerEntity entity in entities) {
      _entityService.upsert(
        entity.copyWith(
          available: false,
          updatedAt: DateTime.now(),
        ),
      );
    }

    final List<RustlerDevice> devices = _deviceRegistry.devices.value.values
        .where(
          (
            RustlerDevice device,
          ) =>
              device.id.startsWith(
            'hub.',
          ),
        )
        .toList();

    for (final RustlerDevice device in devices) {
      _deviceRegistry.upsertDevice(
        device.copyWith(
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

    _pingTimer?.cancel();
    _pingTimer = null;

    final WebSocket? socket = _socket;

    _socket = null;

    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {}
    }

    connectionState.value = HubConnectionState.disconnected;

    _markAllHubDataUnavailable();

    debugPrint(
      'RigOS Hub client stopped',
    );
  }

  Future<void> reconnect() async {
    await disconnect();

    _shouldReconnect = true;

    await connect();
  }
}
