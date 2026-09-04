import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paired_endpoint.dart';

class PairingService {
  PairingService._();
  static final PairingService instance = PairingService._();
  static const _key = 'rigos_paired_endpoints_v1';
  final ValueNotifier<List<PairedEndpoint>> endpoints = ValueNotifier(const []);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final rows = p.getStringList(_key) ?? const [];
    endpoints.value = rows
        .map((e) =>
            PairedEndpoint.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert(PairedEndpoint endpoint) async {
    final list = [...endpoints.value];
    final i = list.indexWhere((e) => e.id == endpoint.id);
    if (i < 0) {
      list.add(endpoint);
    } else {
      list[i] = endpoint;
    }
    endpoints.value = list;
    await _save();
  }

  Future<void> remove(String id) async {
    endpoints.value = endpoints.value.where((e) => e.id != id).toList();
    await _save();
  }

  PairedEndpoint decodeQr(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['rigos'] != 1) {
      throw const FormatException('Not a RigOS pairing code');
    }
    return PairedEndpoint.fromJson(map);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
        _key, endpoints.value.map((e) => jsonEncode(e.toJson())).toList());
  }
}
