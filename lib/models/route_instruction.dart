enum RouteInstructionType {
  start,
  straight,
  slightLeft,
  left,
  sharpLeft,
  slightRight,
  right,
  sharpRight,
  uTurn,
  arrive,
}

class RouteInstruction {
  final RouteInstructionType type;

  final String text;

  final String? roadName;

  final double distanceMetres;

  final double latitude;
  final double longitude;

  const RouteInstruction({
    required this.type,
    required this.text,
    this.roadName,
    required this.distanceMetres,
    required this.latitude,
    required this.longitude,
  });
}