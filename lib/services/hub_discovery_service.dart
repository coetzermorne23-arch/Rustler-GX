import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/discovered_hub.dart';

class HubDiscoveryService {
  HubDiscoveryService._();

  static final HubDiscoveryService instance = HubDiscoveryService._();

  static const int discoveryPort = 8766;

  final ValueNotifier<List<DiscoveredHub>> hubs =
      ValueNotifier<List<DiscoveredHub>>(
    <DiscoveredHub>[],
  );

  RawDatagramSocket? _listener;
  RawDatagramSocket? _broadcaster;

  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  String? _hubId;
  String? _hubName;
  int? _hubPort;

  bool get isListening => _listener != null;

  bool get isBroadcasting => _broadcaster != null;

  // =========================================================
  // CLIENT DISCOVERY
  // =========================================================

  Future<void> startListening() async {
    if (_listener != null) {
      return;
    }

    try {
      final RawDatagramSocket socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );

      socket.broadcastEnabled = true;

      _listener = socket;

      socket.listen(
        (RawSocketEvent event) {
          if (event != RawSocketEvent.read) {
            return;
          }

          Datagram? datagram;

          while ((datagram = socket.receive()) != null) {
            _handleDatagram(
              datagram!,
            );
          }
        },
        onError: (Object error) {
          debugPrint(
            'Hub discovery listener error: $error',
          );
        },
      );

      _cleanupTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          _removeExpiredHubs();
        },
      );

      debugPrint(
        'Rustler GX discovery listening on UDP '
        '$discoveryPort',
      );
    } catch (error) {
      debugPrint(
        'Could not start Hub discovery listener: '
        '$error',
      );

      rethrow;
    }
  }

  void _handleDatagram(
    Datagram datagram,
  ) {
    try {
      final String text = utf8.decode(
        datagram.data,
      );

      final dynamic decoded = jsonDecode(text);

      if (decoded is! Map) {
        return;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        decoded,
      );

      if (data['protocol'] != 'rustler-gx-discovery-v1') {
        return;
      }

      if (data['type'] != 'hub_announcement') {
        return;
      }

      final String id = data['id']?.toString() ?? '';

      final String name = data['name']?.toString() ?? 'Rustler GX Hub';

      final int? port = _parsePort(
        data['port'],
      );

      if (id.isEmpty || port == null) {
        return;
      }

      final String host = datagram.address.address;

      _upsertHub(
        DiscoveredHub(
          id: id,
          name: name,
          host: host,
          port: port,
          lastSeen: DateTime.now(),
        ),
      );
    } catch (error) {
      debugPrint(
        'Invalid Hub discovery packet: $error',
      );
    }
  }

  int? _parsePort(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  void _upsertHub(
    DiscoveredHub hub,
  ) {
    final List<DiscoveredHub> updated = List<DiscoveredHub>.from(
      hubs.value,
    );

    final int index = updated.indexWhere(
      (existing) => existing.id == hub.id,
    );

    if (index >= 0) {
      updated[index] = hub;
    } else {
      updated.add(
        hub,
      );
    }

    updated.sort(
      (a, b) => a.name.compareTo(
        b.name,
      ),
    );

    hubs.value = updated;
  }

  void _removeExpiredHubs() {
    final DateTime cutoff = DateTime.now().subtract(
      const Duration(seconds: 15),
    );

    final List<DiscoveredHub> updated = hubs.value
        .where(
          (hub) => hub.lastSeen.isAfter(cutoff),
        )
        .toList();

    if (updated.length != hubs.value.length) {
      hubs.value = updated;
    }
  }

  Future<void> stopListening() async {
    _listener?.close();
    _listener = null;

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    hubs.value = <DiscoveredHub>[];

    debugPrint(
      'Rustler GX discovery listener stopped',
    );
  }

  // =========================================================
  // HUB ANNOUNCEMENT
  // =========================================================

  Future<void> startBroadcasting({
    required String hubId,
    required String hubName,
    required int hubPort,
  }) async {
    _hubId = hubId;
    _hubName = hubName;
    _hubPort = hubPort;

    if (_broadcaster == null) {
      final RawDatagramSocket socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      socket.broadcastEnabled = true;

      _broadcaster = socket;
    }

    _broadcastTimer?.cancel();

    _broadcastTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _broadcastAnnouncement();
      },
    );

    _broadcastAnnouncement();

    debugPrint(
      'Rustler GX Hub discovery broadcasting',
    );
  }

  void _broadcastAnnouncement() {
    final RawDatagramSocket? socket = _broadcaster;

    final String? hubId = _hubId;

    final String? hubName = _hubName;

    final int? hubPort = _hubPort;

    if (socket == null || hubId == null || hubName == null || hubPort == null) {
      return;
    }

    final Map<String, dynamic> packet = <String, dynamic>{
      'protocol': 'rustler-gx-discovery-v1',
      'type': 'hub_announcement',
      'id': hubId,
      'name': hubName,
      'port': hubPort,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final List<int> bytes = utf8.encode(
      jsonEncode(packet),
    );

    try {
      socket.send(
        bytes,
        InternetAddress(
          '255.255.255.255',
        ),
        discoveryPort,
      );
    } catch (error) {
      debugPrint(
        'Hub discovery broadcast failed: $error',
      );
    }
  }

  Future<void> stopBroadcasting() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _broadcaster?.close();
    _broadcaster = null;

    _hubId = null;
    _hubName = null;
    _hubPort = null;

    debugPrint(
      'Rustler GX Hub discovery broadcasting stopped',
    );
  }

  Future<void> shutdown() async {
    await stopListening();
    await stopBroadcasting();
  }
}
