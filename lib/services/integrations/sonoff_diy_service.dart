import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/entity_sources.dart';
import '../../models/local_http_device.dart';
import '../../models/rustler_device.dart';
import '../../models/rustler_entity.dart';
import '../device_entity_link_service.dart';

class SonoffDiyService {
  SonoffDiyService._();

  static final SonoffDiyService instance = SonoffDiyService._();

  final DeviceEntityLinkService _links = DeviceEntityLinkService.instance;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);

  final ValueNotifier<Map<String, String>> errors =
      ValueNotifier<Map<String, String>>(<String, String>{});

  Future<Map<String, dynamic>> getInfo(LocalHttpDevice device) async {
    final Map<String, dynamic> response = await _command(
      device: device,
      endpoint: '/zeroconf/info',
      data: const <String, dynamic>{},
    );
    _publishInfo(device, _responseData(response));
    return response;
  }

  Future<bool?> readSwitch(LocalHttpDevice device) async {
    final Map<String, dynamic> response = await getInfo(device);
    final String? state =
        _responseData(response)['switch']?.toString().toLowerCase();
    return switch (state) {
      'on' => true,
      'off' => false,
      _ => null,
    };
  }

  Future<void> setSwitch(LocalHttpDevice device, bool on) async {
    await _command(
      device: device,
      endpoint: '/zeroconf/switch',
      data: <String, dynamic>{'switch': on ? 'on' : 'off'},
    );
    _publishSwitch(device, on);
  }

  Future<void> toggle(LocalHttpDevice device) async {
    final bool? current = await readSwitch(device);
    await setSwitch(device, !(current ?? false));
  }

  Future<Map<String, dynamic>> _command({
    required LocalHttpDevice device,
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    final Uri uri = Uri(
      scheme: 'http',
      host: device.host,
      port: device.port,
      path: endpoint,
    );

    try {
      final HttpClientRequest request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(
        jsonEncode(<String, dynamic>{
          'deviceid': device.protocolDeviceId ?? '',
          'data': data,
        }),
      );

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 4));
      final String body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Sonoff HTTP ${response.statusCode}: $body',
            uri: uri);
      }

      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Invalid SONOFF DIY response.');
      }

      final Map<String, dynamic> result = Map<String, dynamic>.from(decoded);
      final int? errorCode = (result['error'] as num?)?.toInt();
      if (errorCode != null && errorCode != 0) {
        throw StateError('SONOFF DIY error: $errorCode');
      }

      _register(device, available: true);
      _links.setDeviceAvailability('sonoff.${device.id}', true);
      _clearError(device.id);
      return result;
    } catch (error) {
      _register(device, available: false);
      _links.setDeviceAvailability('sonoff.${device.id}', false);
      _setError(device.id, error.toString());
      rethrow;
    }
  }

  Map<String, dynamic> _responseData(Map<String, dynamic> response) {
    final dynamic raw = response['data'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  void _publishInfo(LocalHttpDevice device, Map<String, dynamic> data) {
    final String? state = data['switch']?.toString().toLowerCase();
    if (state == 'on' || state == 'off') {
      _publishSwitch(device, state == 'on');
    }

    final DateTime now = DateTime.now();
    final String deviceId = 'sonoff.${device.id}';
    _register(device, available: true, updatedAt: now);

    void publishText(String key, String name) {
      final dynamic value = data[key];
      if (value == null) return;
      _links.publishEntity(
        deviceId: deviceId,
        entity: RustlerEntity(
          id: '$deviceId.$key',
          name: name,
          type: RustlerEntityType.sensor,
          value: value,
          source: EntitySources.sonoff,
          available: true,
          updatedAt: now,
        ),
      );
    }

    publishText('startup', 'Startup State');
    publishText('pulse', 'Pulse');
    publishText('pulseWidth', 'Pulse Width');
    publishText('ssid', 'Wi-Fi SSID');
    publishText('signalStrength', 'Signal Strength');
  }

  void _publishSwitch(LocalHttpDevice device, bool on) {
    final DateTime now = DateTime.now();
    final String deviceId = 'sonoff.${device.id}';
    _register(device, available: true, updatedAt: now);
    _links.publishEntity(
      deviceId: deviceId,
      entity: RustlerEntity(
        id: '$deviceId.switch',
        name: '${device.name} Switch',
        type: RustlerEntityType.switchEntity,
        value: on,
        source: EntitySources.sonoff,
        available: true,
        updatedAt: now,
      ),
    );
  }

  void _register(
    LocalHttpDevice device, {
    required bool available,
    DateTime? updatedAt,
  }) {
    _links.registerDevice(
      RustlerDevice(
        id: 'sonoff.${device.id}',
        name: device.name,
        manufacturer: 'SONOFF',
        model: 'DIY Mode',
        type: RustlerDeviceType.relay,
        source: EntitySources.sonoff,
        available: available,
        updatedAt: updatedAt ?? DateTime.now(),
      ),
    );
  }

  void _setError(String id, String message) {
    final Map<String, String> updated = Map<String, String>.from(errors.value);
    updated[id] = message;
    errors.value = updated;
  }

  void _clearError(String id) {
    if (!errors.value.containsKey(id)) return;
    final Map<String, String> updated = Map<String, String>.from(errors.value);
    updated.remove(id);
    errors.value = updated;
  }
}
