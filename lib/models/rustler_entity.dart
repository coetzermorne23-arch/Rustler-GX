enum RustlerEntityType {
  sensor,
  binarySensor,
  switchEntity,
  number,
  climate,
  battery,
  gps,
  media,
  light,
  location,
  tank,
  relay,
  unknown,
}

class RustlerEntity {
  final String id;
  final String name;
  final RustlerEntityType type;
  final dynamic value;
  final String? unit;
  final String source;
  final bool available;
  final DateTime updatedAt;

  const RustlerEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.unit,
    required this.source,
    required this.available,
    required this.updatedAt,
  });

  RustlerEntity copyWith({
    String? id,
    String? name,
    RustlerEntityType? type,
    dynamic value,
    String? unit,
    String? source,
    bool? available,
    DateTime? updatedAt,
  }) {
    return RustlerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      available: available ?? this.available,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
