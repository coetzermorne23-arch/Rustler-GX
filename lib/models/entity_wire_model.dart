import 'rustler_entity.dart';

class EntityWireModel {
  final String id;
  final String name;
  final String type;
  final dynamic value;
  final String? unit;
  final String source;
  final bool available;
  final String updatedAt;

  const EntityWireModel({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.unit,
    required this.source,
    required this.available,
    required this.updatedAt,
  });

  factory EntityWireModel.fromEntity(
    RustlerEntity entity,
  ) {
    return EntityWireModel(
      id: entity.id,
      name: entity.name,
      type: entity.type.name,
      value: entity.value,
      unit: entity.unit,
      source: entity.source,
      available: entity.available,
      updatedAt:
          entity.updatedAt.toIso8601String(),
    );
  }

  RustlerEntity toEntity() {
    return RustlerEntity(
      id: id,
      name: name,
      type: _typeFromString(type),
      value: value,
      unit: unit,
      source: source,
      available: available,
      updatedAt:
          DateTime.parse(updatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'unit': unit,
      'source': source,
      'available': available,
      'updatedAt': updatedAt,
    };
  }

  factory EntityWireModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EntityWireModel(
      id:
          json['id'] as String? ?? '',
      name:
          json['name'] as String? ?? '',
      type:
          json['type'] as String? ?? 'sensor',
      value: json['value'],
      unit:
          json['unit'] as String?,
      source:
          json['source'] as String? ?? 'unknown',
      available:
          json['available'] as bool? ?? false,
      updatedAt:
          json['updatedAt'] as String? ??
              DateTime.now()
                  .toIso8601String(),
    );
  }

  static RustlerEntityType _typeFromString(
    String value,
  ) {
    for (final type
        in RustlerEntityType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return RustlerEntityType.sensor;
  }
}