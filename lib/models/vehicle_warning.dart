enum VehicleWarningSeverity {
  caution,
  critical,
}

class VehicleWarning {
  final String id;
  final String title;
  final String message;
  final VehicleWarningSeverity severity;
  final DateTime createdAt;

  const VehicleWarning({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });
}

class VehicleParameterLimit {
  final String id;
  final String label;
  final double? cautionMin;
  final double? cautionMax;
  final double? criticalMin;
  final double? criticalMax;
  final String unit;

  const VehicleParameterLimit({
    required this.id,
    required this.label,
    required this.unit,
    this.cautionMin,
    this.cautionMax,
    this.criticalMin,
    this.criticalMax,
  });

  bool isCritical(
    double value,
  ) {
    if (criticalMin != null && value < criticalMin!) {
      return true;
    }

    if (criticalMax != null && value > criticalMax!) {
      return true;
    }

    return false;
  }

  bool isCaution(
    double value,
  ) {
    if (cautionMin != null && value < cautionMin!) {
      return true;
    }

    if (cautionMax != null && value > cautionMax!) {
      return true;
    }

    return false;
  }
}
