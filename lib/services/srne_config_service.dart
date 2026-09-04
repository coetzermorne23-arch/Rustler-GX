import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SrneConfig {
  final String host;
  final int port;
  final int unitId;
  final bool enabled;
  const SrneConfig(
      {this.host = '', this.port = 502, this.unitId = 1, this.enabled = false});
}

class SrneConfigService {
  SrneConfigService._();
  static final SrneConfigService instance = SrneConfigService._();
  final ValueNotifier<SrneConfig> config = ValueNotifier(const SrneConfig());

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    config.value = SrneConfig(
      host: p.getString('rigos_srne_host') ?? '',
      port: p.getInt('rigos_srne_port') ?? 502,
      unitId: p.getInt('rigos_srne_unit') ?? 1,
      enabled: p.getBool('rigos_srne_enabled') ?? false,
    );
  }

  Future<void> save(SrneConfig c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('rigos_srne_host', c.host);
    await p.setInt('rigos_srne_port', c.port);
    await p.setInt('rigos_srne_unit', c.unitId);
    await p.setBool('rigos_srne_enabled', c.enabled);
    config.value = c;
  }

  Future<bool> testTcp() async {
    final c = config.value;
    if (c.host.isEmpty) return false;
    Socket? s;
    try {
      s = await Socket.connect(c.host, c.port,
          timeout: const Duration(seconds: 3));
      return true;
    } catch (_) {
      return false;
    } finally {
      await s?.close();
    }
  }
}
