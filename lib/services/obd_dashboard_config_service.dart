import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/obd_dashboard_config.dart';

class ObdDashboardConfigService {
  ObdDashboardConfigService._();

  static final ObdDashboardConfigService instance =
      ObdDashboardConfigService._();

  static const String _styleKey = 'ranger_gx_obd_dashboard_style';
  static const String _metricsKey = 'ranger_gx_obd_dashboard_metrics';

  final ValueNotifier<ObdDashboardConfig> config =
      ValueNotifier<ObdDashboardConfig>(ObdDashboardConfig.defaults);

  bool _initialised = false;

  Future<void> initialise() async {
    if (_initialised) {
      return;
    }
    _initialised = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedStyle = prefs.getString(_styleKey);
    final List<String>? savedMetrics = prefs.getStringList(_metricsKey);

    config.value = ObdDashboardConfig(
      style: savedStyle == ObdDashboardStyle.cards.name
          ? ObdDashboardStyle.cards
          : ObdDashboardStyle.gauges,
      metricIds: savedMetrics == null || savedMetrics.isEmpty
          ? ObdDashboardConfig.defaults.metricIds
          : savedMetrics,
    );
  }

  Future<void> setStyle(ObdDashboardStyle style) async {
    await initialise();
    config.value = config.value.copyWith(style: style);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, style.name);
  }

  Future<void> setMetrics(List<String> ids) async {
    await initialise();
    final List<String> cleaned = ids.toSet().toList(growable: false);
    config.value = config.value.copyWith(metricIds: cleaned);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_metricsKey, cleaned);
  }

  Future<void> reset() async {
    config.value = ObdDashboardConfig.defaults;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_styleKey);
    await prefs.remove(_metricsKey);
  }
}
