class NavigationPlace {
  final int? id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  final bool favourite;
  final bool isHome;
  final bool isWork;

  final int visitCount;
  final DateTime? lastVisited;

  const NavigationPlace({
    this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.favourite = false,
    this.isHome = false,
    this.isWork = false,
    this.visitCount = 0,
    this.lastVisited,
  });

  NavigationPlace copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    bool? favourite,
    bool? isHome,
    bool? isWork,
    int? visitCount,
    DateTime? lastVisited,
  }) {
    return NavigationPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      favourite: favourite ?? this.favourite,
      isHome: isHome ?? this.isHome,
      isWork: isWork ?? this.isWork,
      visitCount: visitCount ?? this.visitCount,
      lastVisited: lastVisited ?? this.lastVisited,
    );
  }
}