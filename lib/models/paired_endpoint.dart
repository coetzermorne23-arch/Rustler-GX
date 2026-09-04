import 'dart:convert';

enum RigPairMethod { bluetooth, network, qr, usb, mqtt }

class PairedEndpoint {
  final String id;
  final String name;
  final RigPairMethod method;
  final String address;
  final String protocol;
  final int? port;
  final String? secret;
  final bool enabled;

  const PairedEndpoint({
    required this.id,
    required this.name,
    required this.method,
    required this.address,
    required this.protocol,
    this.port,
    this.secret,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method.name,
        'address': address,
        'protocol': protocol,
        'port': port,
        'secret': secret,
        'enabled': enabled,
      };

  factory PairedEndpoint.fromJson(Map<String, dynamic> j) => PairedEndpoint(
        id: '${j['id']}',
        name: '${j['name']}',
        method: RigPairMethod.values.firstWhere((e) => e.name == j['method'],
            orElse: () => RigPairMethod.network),
        address: '${j['address']}',
        protocol: '${j['protocol']}',
        port: (j['port'] as num?)?.toInt(),
        secret: j['secret']?.toString(),
        enabled: j['enabled'] as bool? ?? true,
      );

  String encodeQr() => jsonEncode({'rigos': 1, ...toJson()});
}
