import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GnssSatellite {
  final int svid;
  final int constellation;
  final double cn0;
  final double elevation;
  final double azimuth;
  final bool usedInFix;

  const GnssSatellite({
    required this.svid,
    required this.constellation,
    required this.cn0,
    required this.elevation,
    required this.azimuth,
    required this.usedInFix,
  });

  factory GnssSatellite.fromMap(Map<Object?, Object?> map) => GnssSatellite(
        svid: (map['svid'] as num?)?.toInt() ?? 0,
        constellation: (map['constellation'] as num?)?.toInt() ?? 0,
        cn0: (map['cn0'] as num?)?.toDouble() ?? 0,
        elevation: (map['elevation'] as num?)?.toDouble() ?? 0,
        azimuth: (map['azimuth'] as num?)?.toDouble() ?? 0,
        usedInFix: map['usedInFix'] == true,
      );

  String get constellationName => switch (constellation) {
        1 => 'GPS',
        2 => 'SBAS',
        3 => 'GLONASS',
        4 => 'QZSS',
        5 => 'BEIDOU',
        6 => 'GALILEO',
        7 => 'IRNSS',
        _ => 'OTHER',
      };
}

class GnssService {
  GnssService._();
  static final GnssService instance = GnssService._();

  static const MethodChannel _channel = MethodChannel('rustler_gx/gnss');

  final ValueNotifier<List<GnssSatellite>> satellites =
      ValueNotifier<List<GnssSatellite>>(<GnssSatellite>[]);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);

  Timer? _timer;

  void start() {
    _timer ??=
        Timer.periodic(const Duration(milliseconds: 750), (_) => refresh());
    unawaited(refresh());
  }

  Future<void> refresh() async {
    try {
      final raw = await _channel.invokeListMethod<Object?>('snapshot');
      satellites.value = (raw ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(GnssSatellite.fromMap)
          .toList();
      error.value = null;
    } on PlatformException catch (e) {
      error.value = e.message ?? e.code;
    } catch (e) {
      error.value = e.toString();
    }
  }

  int count(String name) =>
      satellites.value.where((s) => s.constellationName == name).length;

  int get usedCount => satellites.value.where((s) => s.usedInFix).length;

  double get bestCn0 {
    if (satellites.value.isEmpty) return 0;
    return satellites.value.map((s) => s.cn0).reduce((a, b) => a > b ? a : b);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
