import 'route_instruction.dart';
import 'route_point.dart';

class NavigationRoute {
  final List<RoutePoint> points;

  final List<RouteInstruction> instructions;

  final double distanceMetres;

  final Duration estimatedDuration;

  const NavigationRoute({
    required this.points,
    required this.instructions,
    required this.distanceMetres,
    required this.estimatedDuration,
  });

  double get distanceKm => distanceMetres / 1000;

  bool get isEmpty => points.isEmpty;

  String get distanceText {
    if (distanceMetres < 1000) {
      return '${distanceMetres.round()} m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get etaText {
    final int totalMinutes = estimatedDuration.inMinutes;

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final int hours = totalMinutes ~/ 60;

    final int minutes = totalMinutes % 60;

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}m';
  }
}
