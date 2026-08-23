enum RustlerDeviceType {
  batteryMonitor,
  solarCharger,
  acCharger,
  dcDcCharger,
  fridge,
  waterTank,
  gps,
  media,
  relay,
  sensor,
  hub,
  unknown,
}

class RustlerDevice {
  final String id;
  final String name;
  final String manufacturer;
  final String? model;

  final RustlerDeviceType type;

  final String source;

  final bool available;

  final DateTime updatedAt;

  final List<String> entityIds;

  const RustlerDevice({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.type,
    required this.source,
    required this.available,
    required this.updatedAt,
    required this.entityIds,
  });

  RustlerDevice copyWith({
    String? name,
    String? manufacturer,
    String? model,
    RustlerDeviceType? type,
    String? source,
    bool? available,
    DateTime? updatedAt,
    List<String>? entityIds,
  }) {
    return RustlerDevice(
      id: id,
      name: name ?? this.name,
      manufacturer:
          manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      type: type ?? this.type,
      source: source ?? this.source,
      available:
          available ?? this.available,
      updatedAt:
          updatedAt ?? this.updatedAt,
      entityIds:
          entityIds ?? this.entityIds,
    );
  }
}