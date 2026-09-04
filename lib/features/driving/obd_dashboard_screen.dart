import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/obd_dashboard_config.dart';
import '../../models/vehicle_obd_data.dart';
import '../../services/gps_service.dart';
import '../../services/obd_dashboard_config_service.dart';
import '../../services/obd_service.dart';
import '../../services/vehicle_data_service.dart';
import '../../services/vehicle_trip_service.dart';
import '../../widgets/obd_gauge.dart';
import 'obd_dashboard_settings_screen.dart';

class ObdDashboardScreen extends StatefulWidget {
  const ObdDashboardScreen({super.key});

  @override
  State<ObdDashboardScreen> createState() => _ObdDashboardScreenState();
}

class _ObdDashboardScreenState extends State<ObdDashboardScreen> {
  final ObdService obd = ObdService.instance;
  final VehicleDataService vehicle = VehicleDataService.instance;
  final VehicleTripService trip = VehicleTripService.instance;
  final GpsService gps = GpsService.instance;
  final ObdDashboardConfigService config = ObdDashboardConfigService.instance;

  @override
  void initState() {
    super.initState();
    config.initialise();
    obd.start();
    trip.start();
    gps.start();
  }

  Future<void> _chooseAdapter() async {
    final devices = await obd.bondedDevices();
    if (!mounted) return;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No paired Bluetooth devices. Pair the OBD scanner in Android settings first.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose paired OBD adapter'),
        children: devices
            .map(
              (device) => SimpleDialogOption(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await obd.connect(device.address);
                },
                child: ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.name),
                  subtitle: Text(device.address),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RANGER GX • VEHICLE'),
        actions: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: obd.connected,
            builder: (context, connected, child) => IconButton(
              tooltip: connected ? 'OBD connected' : 'Connect OBD',
              onPressed: _chooseAdapter,
              icon: Icon(connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_searching),
            ),
          ),
          IconButton(
            tooltip: 'Dashboard setup',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ObdDashboardSettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ValueListenableBuilder<VehicleObdData>(
        valueListenable: vehicle.data,
        builder: (context, data, child) {
          return ValueListenableBuilder<VehicleTripData>(
            valueListenable: trip.trip,
            builder: (context, tripData, child) {
              return ValueListenableBuilder<Position?>(
                valueListenable: gps.position,
                builder: (context, position, child) {
                  return ValueListenableBuilder<ObdDashboardConfig>(
                    valueListenable: config.config,
                    builder: (context, dashboard, child) {
                      return Column(
                        children: <Widget>[
                          _StatusStrip(data: data),
                          Expanded(
                            child: dashboard.metricIds.isEmpty
                                ? const Center(
                                    child: Text('No dashboard items selected.'))
                                : GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: dashboard.style ==
                                              ObdDashboardStyle.gauges
                                          ? 3
                                          : 4,
                                      childAspectRatio: dashboard.style ==
                                              ObdDashboardStyle.gauges
                                          ? 1.0
                                          : 1.55,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                    ),
                                    itemCount: dashboard.metricIds.length,
                                    itemBuilder: (context, index) {
                                      final _Metric metric = _metric(
                                        dashboard.metricIds[index],
                                        data,
                                        tripData,
                                        position,
                                      );
                                      return dashboard.style ==
                                              ObdDashboardStyle.gauges
                                          ? ObdGauge(
                                              label: metric.label,
                                              value: metric.value,
                                              unit: metric.unit,
                                              min: metric.min,
                                              max: metric.max,
                                              decimals: metric.decimals,
                                            )
                                          : _MetricCard(metric: metric);
                                    },
                                  ),
                          ),
                          if (obd.error.value != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text(
                                obd.error.value!,
                                style: const TextStyle(
                                    color: Colors.orangeAccent, fontSize: 11),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  _Metric _metric(
    String id,
    VehicleObdData data,
    VehicleTripData tripData,
    Position? position,
  ) {
    switch (id) {
      case 'boost':
        return _Metric('BOOST', data.boostBar, 'bar', -1, 2.5, 2);
      case 'coolant':
        return _Metric('COOLANT', data.coolantTemperatureC, '°C', 40, 130, 0);
      case 'rpm':
        return _Metric('RPM', data.rpm, 'rpm', 0, 5000, 0);
      case 'voltage':
        return _Metric('VOLTAGE', data.batteryVoltage, 'V', 10, 16, 1);
      case 'oil_pressure':
        return _Metric('OIL PRESSURE', data.oilPressureKpa, 'kPa', 0, 700, 0);
      case 'vehicle_speed':
        return _Metric('OBD SPEED', data.vehicleSpeedKmh, 'km/h', 0, 180, 0);
      case 'gps_speed':
        return _Metric(
          'GPS SPEED',
          position == null
              ? null
              : (position.speed < 0 ? 0 : position.speed * 3.6),
          'km/h',
          0,
          180,
          0,
        );
      case 'engine_load':
        return _Metric('ENGINE LOAD', data.engineLoadPercent, '%', 0, 100, 0);
      case 'throttle':
        return _Metric('THROTTLE', data.throttlePercent, '%', 0, 100, 0);
      case 'map':
        return _Metric(
            'MAP', data.manifoldAbsolutePressureKpa, 'kPa', 0, 300, 0);
      case 'intake':
        return _Metric(
            'INTAKE TEMP', data.intakeTemperatureC, '°C', -20, 100, 0);
      case 'maf':
        return _Metric('MAF', data.massAirFlowGps, 'g/s', 0, 250, 1);
      case 'fuel_rate':
        return _Metric(
            'FUEL RATE', data.fuelRateLitresPerHour, 'L/h', 0, 30, 1);
      case 'fuel_consumption':
        return _Metric(
            'AVG FUEL', tripData.averageLitresPer100Km, 'L/100', 0, 30, 1);
      case 'trip_fuel':
        return _Metric('TRIP FUEL', tripData.fuelUsedLitres, 'L', 0, 100, 1);
      default:
        return _Metric(id.toUpperCase(), null, '', 0, 100, 0);
    }
  }
}

class _StatusStrip extends StatelessWidget {
  final VehicleObdData data;
  const _StatusStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final String engine = switch (data.engineState) {
      VehicleEngineState.running => 'ENGINE RUNNING',
      VehicleEngineState.ignitionOnEngineOff => 'IGNITION ON',
      VehicleEngineState.unknown => 'ENGINE UNKNOWN',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: Colors.white.withValues(alpha: 0.04),
      child: Row(
        children: <Widget>[
          Icon(data.connected ? Icons.link : Icons.link_off, size: 18),
          const SizedBox(width: 8),
          Text(data.connected ? engine : 'OBD NOT CONNECTED'),
          const Spacer(),
          const Text('Generic OBD-II values only • unsupported data stays --',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(metric.label,
              style: const TextStyle(
                  color: Colors.white54, letterSpacing: 1.1, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            metric.value == null
                ? '--'
                : metric.value!.toStringAsFixed(metric.decimals),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(metric.unit, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final double? value;
  final String unit;
  final double min;
  final double max;
  final int decimals;
  const _Metric(
      this.label, this.value, this.unit, this.min, this.max, this.decimals);
}
