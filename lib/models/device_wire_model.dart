import 'rustler_device.dart';

class DeviceWireModel {
  final String id;
  final String name;
  final String manufacturer;
  final String? model;
  final String type;
  final String source;
  final bool available;
  final String updatedAt;
  final List<String> entityIds;

  const DeviceWireModel({
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

  factory DeviceWireModel.fromDevice(
    RustlerDevice device,
  ) {
    return DeviceWireModel(
      id: device.id,
      name: device.name,
      manufacturer: device.manufacturer,
      model: device.model,
      type: device.type.name,
      source: device.source,
      available: device.available,
      updatedAt: device.updatedAt.toIso8601String(),
      entityIds: List<String>.from(
        device.entityIds,
      ),
    );
  }

  RustlerDevice toDevice() {
    return RustlerDevice(
      id: id,
      name: name,
      manufacturer: manufacturer,
      model: model,
      type: _typeFromString(
        type,
      ),
      source: source,
      available: available,
      updatedAt: DateTime.parse(
        updatedAt,
      ),
      entityIds: List<String>.from(
        entityIds,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'model': model,
      'type': type,
      'source': source,
      'available': available,
      'updatedAt': updatedAt,
      'entityIds': entityIds,
    };
  }

  factory DeviceWireModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeviceWireModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Device',
      manufacturer: json['manufacturer']?.toString() ?? 'Unknown',
      model: json['model']?.toString(),
      type: json['type']?.toString() ?? 'unknown',
      source: json['source']?.toString() ?? 'unknown',
      available: json['available'] as bool? ?? false,
      updatedAt:
          json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      entityIds: (json['entityIds'] as List?)
              ?.map(
                (item) => item.toString(),
              )
              .toList() ??
          <String>[],
    );
  }

  static RustlerDeviceType _typeFromString(
    String value,
  ) {
    for (final RustlerDeviceType type in RustlerDeviceType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return RustlerDeviceType.unknown;
  }
}
