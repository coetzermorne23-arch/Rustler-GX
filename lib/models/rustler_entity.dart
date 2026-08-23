enum RustlerEntityType {
  sensor,
  binarySensor,
  switchEntity,
  number,
  climate,
  battery,
  gps,
  media,
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
    dynamic value,
    bool? available,
    DateTime? updatedAt,
  }) {
    return RustlerEntity(
      id: id,
      name: name,
      type: type,
      value: value ?? this.value,
      unit: unit,
      source: source,
      available: available ?? this.available,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}