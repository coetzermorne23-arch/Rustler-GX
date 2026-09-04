enum ObdDashboardStyle {
  cards,
  gauges,
}

class ObdDashboardConfig {
  final ObdDashboardStyle style;
  final List<String> metricIds;

  const ObdDashboardConfig({
    required this.style,
    required this.metricIds,
  });

  static const ObdDashboardConfig defaults = ObdDashboardConfig(
    style: ObdDashboardStyle.gauges,
    metricIds: <String>[
      'boost',
      'coolant',
      'rpm',
      'voltage',
      'fuel_consumption',
      'engine_load',
    ],
  );

  ObdDashboardConfig copyWith({
    ObdDashboardStyle? style,
    List<String>? metricIds,
  }) {
    return ObdDashboardConfig(
      style: style ?? this.style,
      metricIds: metricIds ?? this.metricIds,
    );
  }
}
