class HeadUnitStorageVolume {
  final String description;
  final String path;
  final String state;
  final bool removable;

  const HeadUnitStorageVolume({
    required this.description,
    required this.path,
    required this.state,
    required this.removable,
  });

  factory HeadUnitStorageVolume.fromMap(Map<dynamic, dynamic> map) {
    return HeadUnitStorageVolume(
      description: map['description']?.toString() ?? 'Storage',
      path: map['path']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      removable: map['removable'] == true,
    );
  }
}

class HeadUnitCallState {
  final bool active;
  final String title;
  final String text;
  final String packageName;

  const HeadUnitCallState({
    required this.active,
    required this.title,
    required this.text,
    required this.packageName,
  });

  const HeadUnitCallState.idle()
      : active = false,
        title = '',
        text = '',
        packageName = '';

  factory HeadUnitCallState.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map['active'] != true) {
      return const HeadUnitCallState.idle();
    }
    return HeadUnitCallState(
      active: true,
      title: map['title']?.toString() ?? 'Call',
      text: map['text']?.toString() ?? '',
      packageName: map['packageName']?.toString() ?? '',
    );
  }
}
