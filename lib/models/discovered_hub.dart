class DiscoveredHub {
  final String id;
  final String name;
  final String host;
  final int port;
  final DateTime lastSeen;

  const DiscoveredHub({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.lastSeen,
  });

  DiscoveredHub copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    DateTime? lastSeen,
  }) {
    return DiscoveredHub(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
