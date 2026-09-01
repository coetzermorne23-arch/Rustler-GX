import 'package:flutter/foundation.dart';

import '../models/vehicle_obd_data.dart';
import '../models/vehicle_warning.dart';
import 'vehicle_data_service.dart';

class VehicleWarningService {
  VehicleWarningService._() {
    vehicle.data.addListener(
      _evaluate,
    );
  }

  static final VehicleWarningService instance = VehicleWarningService._();

  final VehicleDataService vehicle = VehicleDataService.instance;

  final ValueNotifier<VehicleWarning?> activeWarning =
      ValueNotifier<VehicleWarning?>(
    null,
  );

  final Map<String, VehicleParameterLimit> _limits =
      <String, VehicleParameterLimit>{};

  void configureLimits(
    Iterable<VehicleParameterLimit> limits,
  ) {
    _limits
      ..clear()
      ..addEntries(
        limits.map(
          (
            VehicleParameterLimit limit,
          ) =>
              MapEntry<String, VehicleParameterLimit>(
            limit.id,
            limit,
          ),
        ),
      );

    _evaluate();
  }

  void clearLimits() {
    _limits.clear();
    activeWarning.value = null;
  }

  void dismiss() {
    activeWarning.value = null;
  }

  void _evaluate() {
    final VehicleObdData data = vehicle.data.value;

    if (!data.connected || data.engineState != VehicleEngineState.running) {
      activeWarning.value = null;
      return;
    }

    final List<_MeasuredParameter> values = <_MeasuredParameter>[
      _MeasuredParameter(
        id: 'coolant_temperature',
        value: data.coolantTemperatureC,
      ),
      _MeasuredParameter(
        id: 'intake_temperature',
        value: data.intakeTemperatureC,
      ),
      _MeasuredParameter(
        id: 'battery_voltage',
        value: data.batteryVoltage,
      ),
      _MeasuredParameter(
        id: 'boost',
        value: data.boostBar,
      ),
      _MeasuredParameter(
        id: 'oil_pressure',
        value: data.oilPressureKpa,
      ),
    ];

    VehicleWarning? caution;

    for (final _MeasuredParameter measured in values) {
      final double? value = measured.value;

      final VehicleParameterLimit? limit = _limits[measured.id];

      if (value == null || limit == null) {
        continue;
      }

      if (limit.isCritical(value)) {
        activeWarning.value = VehicleWarning(
          id: limit.id,
          title: '${limit.label.toUpperCase()} CRITICAL',
          message: '${value.toStringAsFixed(1)} ${limit.unit}',
          severity: VehicleWarningSeverity.critical,
          createdAt: DateTime.now(),
        );
        return;
      }

      if (caution == null && limit.isCaution(value)) {
        caution = VehicleWarning(
          id: limit.id,
          title: '${limit.label.toUpperCase()} WARNING',
          message: '${value.toStringAsFixed(1)} ${limit.unit}',
          severity: VehicleWarningSeverity.caution,
          createdAt: DateTime.now(),
        );
      }
    }

    activeWarning.value = caution;
  }
}

class _MeasuredParameter {
  final String id;
  final double? value;

  const _MeasuredParameter({
    required this.id,
    required this.value,
  });
}
