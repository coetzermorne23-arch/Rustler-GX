import 'package:flutter/material.dart';

import '../../models/vehicle_obd_data.dart';
import '../../services/vehicle_data_service.dart';
import '../../services/vehicle_trip_service.dart';

class RangerVehicleStatusCard extends StatefulWidget {
  const RangerVehicleStatusCard({
    super.key,
  });

  @override
  State<RangerVehicleStatusCard> createState() =>
      _RangerVehicleStatusCardState();
}

class _RangerVehicleStatusCardState extends State<RangerVehicleStatusCard> {
  final VehicleDataService vehicle = VehicleDataService.instance;

  final VehicleTripService trip = VehicleTripService.instance;

  @override
  void initState() {
    super.initState();

    trip.start();
  }

  String _value(
    double? value,
    String unit, {
    int decimals = 0,
  }) {
    if (value == null) {
      return '--';
    }

    return '${value.toStringAsFixed(decimals)} $unit';
  }

  String _engineLabel(
    VehicleObdData data,
  ) {
    switch (data.engineState) {
      case VehicleEngineState.running:
        return 'ENGINE RUNNING';
      case VehicleEngineState.ignitionOnEngineOff:
        return 'IGNITION ON';
      case VehicleEngineState.unknown:
        return data.connected ? 'ENGINE STATE UNKNOWN' : 'OBD NOT CONNECTED';
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ValueListenableBuilder<VehicleObdData>(
      valueListenable: vehicle.data,
      builder: (
        context,
        data,
        child,
      ) {
        return ValueListenableBuilder<VehicleTripData>(
          valueListenable: trip.trip,
          builder: (
            context,
            tripData,
            child,
          ) {
            return Container(
              padding: const EdgeInsets.all(
                14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
                border: Border.all(
                  color: Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        data.connected
                            ? Icons.directions_car_filled
                            : Icons.link_off_rounded,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          _engineLabel(
                            data,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (data.rpm != null)
                        Text(
                          '${data.rpm!.round()} RPM',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Wrap(
                    spacing: 18,
                    runSpacing: 10,
                    children: [
                      _Metric(
                        label: 'COOLANT',
                        value: _value(
                          data.coolantTemperatureC,
                          '°C',
                        ),
                      ),
                      _Metric(
                        label: 'BOOST',
                        value: _value(
                          data.boostBar,
                          'bar',
                          decimals: 2,
                        ),
                      ),
                      _Metric(
                        label: 'VOLTAGE',
                        value: _value(
                          data.batteryVoltage,
                          'V',
                          decimals: 1,
                        ),
                      ),
                      _Metric(
                        label: 'FUEL',
                        value: tripData.averageLitresPer100Km == null
                            ? '--'
                            : '${tripData.averageLitresPer100Km!.toStringAsFixed(1)} L/100km',
                      ),
                      _Metric(
                        label: 'TRIP FUEL',
                        value:
                            '${tripData.fuelUsedLitres.toStringAsFixed(1)} L',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              color: Colors.white54,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
