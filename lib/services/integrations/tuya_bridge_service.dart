import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/entity_sources.dart';
import '../../models/local_http_device.dart';
import '../../models/rustler_device.dart';
import '../device_entity_link_service.dart';
import 'generic_json_entity_mapper.dart';

/// Adapter for a local Tuya bridge/API.
///
/// This is deliberately not a fake implementation of Tuya's encrypted local
/// device protocol. The configured bridge must expose JSON over HTTP.
class TuyaBridgeService {
  TuyaBridgeService._();

  static final TuyaBridgeService instance = TuyaBridgeService._();

  final DeviceEntityLinkService _links = DeviceEntityLinkService.instance;
  final GenericJsonEntityMapper _mapper = const GenericJsonEntityMapper();
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);

  final ValueNotifier<Map<String, String>> errors =
      ValueNotifier<Map<String, String>>(<String, String>{});

  Future<Map<String, dynamic>> poll(LocalHttpDevice device) async {
    final Uri uri = device.uri(device.statusPath);
    try {
      final Map<String, dynamic> data = await _getJson(uri);
      final DateTime now = DateTime.now();
      final String deviceId = 'tuya.${device.id}';

      _links.registerDevice(
        RustlerDevice(
          id: deviceId,
          name: device.name,
          manufacturer: 'Tuya',
          model: 'Local bridge',
          type: RustlerDeviceType.unknown,
          source: EntitySources.tuya,
          available: true,
          updatedAt: now,
        ),
      );

      for (final entity in _mapper.map(
        deviceId: device.id,
        source: EntitySources.tuya,
        data: data,
        updatedAt: now,
      )) {
        _links.publishEntity(deviceId: deviceId, entity: entity);
      }

      _links.setDeviceAvailability(deviceId, true);
      _clearError(device.id);
      return data;
    } catch (error) {
      _links.setDeviceAvailability('tuya.${device.id}', false);
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
    final Uri uri = device.uri(path);

    try {
      final HttpClientRequest request = await _client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(<String, dynamic>{
        'entity': entityKey,
        'value': value,
      }));

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 4));
      final String body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $body', uri: uri);
      }

      _clearError(device.id);
      await poll(device);
      if (body.trim().isEmpty) return <String, dynamic>{};
      final dynamic decoded = jsonDecode(body);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{'value': decoded};
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
      throw const FormatException('Tuya bridge response must be JSON.');
    }
    return Map<String, dynamic>.from(decoded);
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
