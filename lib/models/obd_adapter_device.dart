class ObdAdapterDevice {
  final String name;
  final String address;

  const ObdAdapterDevice({
    required this.name,
    required this.address,
  });

  factory ObdAdapterDevice.fromMap(Map<dynamic, dynamic> map) {
    return ObdAdapterDevice(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'OBD adapter',
      address: (map['address'] as String?) ?? '',
    );
  }
}
