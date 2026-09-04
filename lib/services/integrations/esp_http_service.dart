import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/entity_sources.dart';
import '../../models/local_http_device.dart';
import '../../models/rustler_device.dart';
import '../device_entity_link_service.dart';
import 'generic_json_entity_mapper.dart';

class EspHttpService {
  EspHttpService._();

  static final EspHttpService instance = EspHttpService._();

  final DeviceEntityLinkService _links = DeviceEntityLinkService.instance;
  final GenericJsonEntityMapper _mapper = const GenericJsonEntityMapper();

  final Map<String, Timer> _timers = <String, Timer>{};
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);

  final ValueNotifier<Map<String, String>> errors =
      ValueNotifier<Map<String, String>>(<String, String>{});

  void start(LocalHttpDevice device) {
    stop(device.id);
    if (!device.enabled) return;

    _register(device, available: false);
    unawaited(poll(device));

    _timers[device.id] = Timer.periodic(
      device.pollInterval,
      (_) => unawaited(poll(device)),
    );
  }

  void stop(String deviceId) => _timers.remove(deviceId)?.cancel();

  void stopAll() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  Future<Map<String, dynamic>> poll(LocalHttpDevice device) async {
    final Uri uri = device.uri(device.statusPath);
    try {
      final Map<String, dynamic> data = await _getJson(uri);
      final DateTime now = DateTime.now();
      final String deviceId = 'esp.${device.id}';

      _register(device, available: true, updatedAt: now);

      for (final entity in _mapper.map(
        deviceId: device.id,
        source: EntitySources.esp,
        data: data,
        updatedAt: now,
      )) {
        _links.publishEntity(deviceId: deviceId, entity: entity);
      }

      _links.setDeviceAvailability(deviceId, true);
      _clearError(device.id);
      return data;
    } catch (error) {
      _links.setDeviceAvailability('esp.${device.id}', false);
      _setError(device.id, error.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setEntityValue({
    required LocalHttpDevice device,
    required String entityKey,
    required dynamic value,
  }) async {
    final String path = device.controlPath?.trim().isNotEmpty == true
        ? device.controlPath!
        : '/control';

    final Map<String, dynamic> response = await sendJson(
      device: device,
      path: path,
      body: <String, dynamic>{
        'entity': entityKey,
        'value': value,
      },
    );

    await poll(device);
    return response;
  }

  Future<Map<String, dynamic>> sendJson({
    required LocalHttpDevice device,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final Uri uri = device.uri(path);

    try {
      final HttpClientRequest request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(body));

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 4));
      final String text = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $text', uri: uri);
      }

      _clearError(device.id);
      if (text.trim().isEmpty) return <String, dynamic>{};

      final dynamic decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return <String, dynamic>{'value': decoded};
    } catch (error) {
      _setError(device.id, error.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final HttpClientRequest request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final HttpClientResponse response =
        await request.close().timeout(const Duration(seconds: 4));
    final String body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}: $body', uri: uri);
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('ESP response must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _register(
    LocalHttpDevice device, {
    required bool available,
    DateTime? updatedAt,
  }) {
    _links.registerDevice(
      RustlerDevice(
        id: 'esp.${device.id}',
        name: device.name,
        manufacturer: device.kind == LocalHttpDeviceKind.customJson
            ? 'Local HTTP'
            : 'ESP / ESP32',
        model: device.kind == LocalHttpDeviceKind.customJson
            ? 'Custom JSON'
            : 'HTTP JSON',
        type: RustlerDeviceType.sensor,
        source: EntitySources.esp,
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
