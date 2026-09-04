enum LocalHttpDeviceKind {
  espJson,
  sonoffDiy,
  tuyaBridge,
  customJson,
}

class LocalHttpDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  final LocalHttpDeviceKind kind;
  final String statusPath;
  final String? controlPath;
  final String? protocolDeviceId;
  final Duration pollInterval;
  final bool enabled;

  const LocalHttpDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.kind,
    required this.statusPath,
    this.controlPath,
    this.protocolDeviceId,
    this.pollInterval = const Duration(seconds: 3),
    this.enabled = true,
  });

  Uri uri(String path) {
    final String normalised = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: normalised,
    );
  }

  String get displayEndpoint => '$host:$port';

  LocalHttpDevice copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    LocalHttpDeviceKind? kind,
    String? statusPath,
    String? controlPath,
    String? protocolDeviceId,
    Duration? pollInterval,
    bool? enabled,
  }) {
    return LocalHttpDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      kind: kind ?? this.kind,
      statusPath: statusPath ?? this.statusPath,
      controlPath: controlPath ?? this.controlPath,
      protocolDeviceId: protocolDeviceId ?? this.protocolDeviceId,
      pollInterval: pollInterval ?? this.pollInterval,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'kind': kind.name,
        'statusPath': statusPath,
        'controlPath': controlPath,
        'protocolDeviceId': protocolDeviceId,
        'pollIntervalMs': pollInterval.inMilliseconds,
        'enabled': enabled,
      };

  factory LocalHttpDevice.fromJson(Map<String, dynamic> json) {
    final String kindName =
        json['kind']?.toString() ?? LocalHttpDeviceKind.customJson.name;

    return LocalHttpDevice(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Local device',
      host: json['host']?.toString() ?? '',
      port: (json['port'] as num?)?.toInt() ?? 80,
      kind: LocalHttpDeviceKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => LocalHttpDeviceKind.customJson,
      ),
      statusPath: json['statusPath']?.toString() ?? '/status',
      controlPath: _nullableString(json['controlPath']),
      protocolDeviceId: _nullableString(json['protocolDeviceId']),
      pollInterval: Duration(
        milliseconds: (json['pollIntervalMs'] as num?)?.toInt() ?? 3000,
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  static String? _nullableString(dynamic value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
