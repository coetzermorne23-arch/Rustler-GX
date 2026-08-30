class RoadNode {
  final int id;

  final double latitude;
  final double longitude;

  const RoadNode({
    required this.id,
    required this.latitude,
    required this.longitude,
  });
}

class RoadEdge {
  final int id;

  final int fromNode;
  final int toNode;

  final double distanceMetres;

  final double speedKmh;

  final String? roadName;

  final bool oneWay;

  const RoadEdge({
    required this.id,
    required this.fromNode,
    required this.toNode,
    required this.distanceMetres,
    required this.speedKmh,
    this.roadName,
    required this.oneWay,
  });

  double get travelSeconds {
    final double speedMetresPerSecond =
        speedKmh / 3.6;

    if (speedMetresPerSecond <= 0) {
      return double.infinity;
    }

    return distanceMetres /
        speedMetresPerSecond;
  }
}