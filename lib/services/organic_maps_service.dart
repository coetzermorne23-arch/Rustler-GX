import 'package:flutter/services.dart';

/// RigOS bridge for Organic Maps.
///
/// Phase 2 supports an embedded Android PlatformView when the locally-built
/// Organic Maps SDK AARs are bundled. The existing external-app bridge stays
/// available as a fallback.
class OrganicMapsService {
  OrganicMapsService._();

  static final OrganicMapsService instance = OrganicMapsService._();

  static const MethodChannel _channel =
      MethodChannel('rustler_gx/organic_maps');

  static const String embeddedViewType = 'rustler_gx/organic_maps_view';

  Future<bool> embeddedAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('embeddedAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isInstalled() async =>
      await _channel.invokeMethod<bool>('isInstalled') ?? false;

  Future<bool> openMap() async =>
      await _channel.invokeMethod<bool>('openMap') ?? false;

  Future<bool> showPoint({
    required double latitude,
    required double longitude,
    required String name,
    double zoom = 17,
  }) async {
    return await _channel.invokeMethod<bool>(
          'showPoint',
          <String, Object>{
            'lat': latitude,
            'lon': longitude,
            'name': name,
            'zoom': zoom,
          },
        ) ??
        false;
  }
}
