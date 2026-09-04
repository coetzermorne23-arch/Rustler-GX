import 'package:flutter/material.dart';

import '../devices/devices_screen.dart';
import '../../models/victron_live_data.dart';
import '../../services/bluetooth_service.dart';
import '../settings/settings_screen.dart';

import '../history/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final VictronBluetoothService bluetooth = VictronBluetoothService.instance;

  int _selectedIndex = 0;

  Widget _dashboardPage() {
    return ValueListenableBuilder<Map<String, VictronLiveData>>(
      valueListenable: bluetooth.liveDevices,
      builder: (context, devices, child) {
        final entries = devices.entries.toList()
          ..sort(
            (a, b) => a.value.name.compareTo(
              b.value.name,
            ),
          );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'RigOS Energy & Devices',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entries.isEmpty
                  ? 'No live devices'
                  : '${entries.length} live device'
                      '${entries.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const _EmptyDashboard()
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _VictronDeviceCard(
                    data: entry.value,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _dashboardPage(),
      const DevicesScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('RigOS'),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: 'Clear live data',
              onPressed: bluetooth.clearLiveDevices,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.bluetooth,
            ),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.history,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.bluetooth_searching,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Victron live data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan for Victron devices to start '
              'receiving live data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VictronDeviceCard extends StatelessWidget {
  final VictronLiveData data;

  const _VictronDeviceCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final type = _detectType(data);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForType(type),
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name.isEmpty ? 'Victron Device' : data.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _labelForType(type),
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                _LiveIndicator(
                  updatedAt: data.updatedAt,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (type == _DashboardDeviceType.shunt) _buildShunt(),
            if (type == _DashboardDeviceType.mppt) _buildMppt(),
            if (type == _DashboardDeviceType.orion) _buildOrion(),
            if (type == _DashboardDeviceType.charger) _buildCharger(),
            if (type == _DashboardDeviceType.unknown) _buildGeneric(),
            const SizedBox(height: 12),
            Text(
              data.serial,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShunt() {
    return Column(
      children: [
        const _SectionTitle(
          title: 'BATTERY',
        ),
        _DataRow(
          label: 'Battery voltage',
          value: _voltage(
            data.batteryVoltage,
          ),
        ),
        _DataRow(
          label: 'Battery current',
          value: _amps(
            data.batteryCurrent,
          ),
        ),
        _DataRow(
          label: 'Battery power',
          value: _watts(
            _batteryPower(),
          ),
        ),
        _DataRow(
          label: 'State of charge',
          value: _percent(
            data.stateOfCharge,
          ),
        ),
        _DataRow(
          label: 'Consumed Ah',
          value: _ampHours(
            data.consumedAh,
          ),
        ),
        _DataRow(
          label: 'Time remaining',
          value: _remainingTime(
            data.remainingMinutes,
          ),
        ),
        if (data.temperature != null)
          _DataRow(
            label: 'Temperature',
            value: _temperature(
              data.temperature,
            ),
          ),
        if (data.starterVoltage != null) ...[
          const Divider(height: 24),
          const _SectionTitle(
            title: 'AUX / STARTER',
          ),
          _DataRow(
            label: 'Starter voltage',
            value: _voltage(
              data.starterVoltage,
            ),
          ),
        ],
        if (data.midpointVoltage != null) ...[
          const Divider(height: 24),
          const _SectionTitle(
            title: 'MIDPOINT',
          ),
          _DataRow(
            label: 'Midpoint voltage',
            value: _voltage(
              data.midpointVoltage,
            ),
          ),
        ],
        if (data.alarmCode != null && data.alarmCode != 0) ...[
          const Divider(height: 24),
          _DataRow(
            label: 'Alarm',
            value: 'Code ${data.alarmCode}',
          ),
        ],
      ],
    );
  }

  Widget _buildMppt() {
    return Column(
      children: [
        const _SectionTitle(
          title: 'SOLAR',
        ),
        if (data.pvVoltage != null)
          _DataRow(
            label: 'PV voltage',
            value: _voltage(
              data.pvVoltage,
            ),
          ),
        if (data.pvCurrent != null)
          _DataRow(
            label: 'PV current',
            value: _amps(
              data.pvCurrent,
            ),
          ),
        _DataRow(
          label: 'PV power',
          value: _watts(
            data.pvPower,
          ),
        ),
        _DataRow(
          label: 'Yield today',
          value: _energy(
            data.yieldToday,
          ),
        ),
        if (data.loadCurrent != null)
          _DataRow(
            label: 'Load current',
            value: _amps(
              data.loadCurrent,
            ),
          ),
        const Divider(height: 24),
        const _SectionTitle(
          title: 'BATTERY / CHARGER',
        ),
        _DataRow(
          label: 'Battery voltage',
          value: _voltage(
            data.batteryVoltage,
          ),
        ),
        _DataRow(
          label: 'Charge current',
          value: _amps(
            data.chargeCurrent,
          ),
        ),
        _DataRow(
          label: 'Output power',
          value: _watts(
            data.power,
          ),
        ),
        _DataRow(
          label: 'Charge state',
          value: data.chargeState ?? 'Waiting...',
        ),
        _DataRow(
          label: 'Charger error',
          value: _chargerError(
            data.chargerError,
          ),
        ),
      ],
    );
  }

  Widget _buildOrion() {
    return Column(
      children: [
        const _SectionTitle(
          title: 'INPUT',
        ),
        _DataRow(
          label: 'Input voltage',
          value: _voltage(
            data.inputVoltage,
          ),
        ),
        const Divider(height: 24),
        const _SectionTitle(
          title: 'OUTPUT',
        ),
        _DataRow(
          label: 'Output voltage',
          value: _voltage(
            data.outputVoltage ?? data.batteryVoltage,
          ),
        ),
        _DataRow(
          label: 'Output current',
          value: _amps(
            data.outputCurrent ?? data.chargeCurrent,
          ),
        ),
        _DataRow(
          label: 'Output power',
          value: _watts(
            data.outputPower ?? data.power,
          ),
        ),
        _DataRow(
          label: 'State',
          value: data.chargeState ?? 'Waiting...',
        ),
      ],
    );
  }

  Widget _buildCharger() {
    final bool hasError = data.chargerError != null && data.chargerError != 0;

    return Column(
      children: [
        const _SectionTitle(
          title: 'CHARGER OUTPUT',
        ),
        _DataRow(
          label: 'Battery voltage',
          value: _voltage(
            data.batteryVoltage,
          ),
        ),
        _DataRow(
          label: 'Charge current',
          value: _amps(
            data.chargeCurrent,
          ),
        ),
        _DataRow(
          label: 'Output power',
          value: _watts(
            data.power,
          ),
        ),
        const Divider(height: 24),
        const _SectionTitle(
          title: 'STATUS',
        ),
        _DataRow(
          label: 'Charge state',
          value: data.chargeState ?? 'Waiting...',
        ),
        _DataRow(
          label: 'Charger status',
          value: hasError
              ? 'ERROR ${data.chargerError}'
              : data.chargerError == 0
                  ? 'OK'
                  : 'Waiting...',
        ),
        if (data.temperature != null)
          _DataRow(
            label: 'Temperature',
            value: _temperature(
              data.temperature,
            ),
          ),
      ],
    );
  }

  Widget _buildGeneric() {
    return Column(
      children: [
        _DataRow(
          label: 'Battery voltage',
          value: _voltage(
            data.batteryVoltage,
          ),
        ),
        _DataRow(
          label: 'Battery current',
          value: _amps(
            data.batteryCurrent,
          ),
        ),
        _DataRow(
          label: 'Charge current',
          value: _amps(
            data.chargeCurrent,
          ),
        ),
        _DataRow(
          label: 'Power',
          value: _watts(
            data.power,
          ),
        ),
        _DataRow(
          label: 'SOC',
          value: _percent(
            data.stateOfCharge,
          ),
        ),
        _DataRow(
          label: 'PV voltage',
          value: _voltage(
            data.pvVoltage,
          ),
        ),
        _DataRow(
          label: 'PV power',
          value: _watts(
            data.pvPower,
          ),
        ),
        _DataRow(
          label: 'State',
          value: data.chargeState ?? 'Waiting...',
        ),
      ],
    );
  }

  double? _batteryPower() {
    if (data.power != null) {
      return data.power;
    }

    if (data.batteryVoltage == null || data.batteryCurrent == null) {
      return null;
    }

    return data.batteryVoltage! * data.batteryCurrent!;
  }

  _DashboardDeviceType _detectType(
    VictronLiveData data,
  ) {
    final name = data.name.toLowerCase();

    if (name.contains('smartshunt') ||
        name.contains('smart shunt') ||
        name.contains('bmv')) {
      return _DashboardDeviceType.shunt;
    }

    if (name.contains('smartsolar') ||
        name.contains('smart solar') ||
        name.contains('mppt')) {
      return _DashboardDeviceType.mppt;
    }

    if (name.contains('orion')) {
      return _DashboardDeviceType.orion;
    }

    if (name.contains('charger') ||
        name.contains('blue smart') ||
        name.contains('bsc')) {
      return _DashboardDeviceType.charger;
    }

    if (data.pvPower != null || data.pvVoltage != null) {
      return _DashboardDeviceType.mppt;
    }

    if (data.stateOfCharge != null) {
      return _DashboardDeviceType.shunt;
    }

    if (data.inputVoltage != null || data.outputVoltage != null) {
      return _DashboardDeviceType.orion;
    }

    return _DashboardDeviceType.unknown;
  }

  IconData _iconForType(
    _DashboardDeviceType type,
  ) {
    switch (type) {
      case _DashboardDeviceType.mppt:
        return Icons.solar_power;

      case _DashboardDeviceType.shunt:
        return Icons.battery_5_bar;

      case _DashboardDeviceType.orion:
        return Icons.electrical_services;

      case _DashboardDeviceType.charger:
        return Icons.battery_charging_full;

      case _DashboardDeviceType.unknown:
        return Icons.memory;
    }
  }

  String _labelForType(
    _DashboardDeviceType type,
  ) {
    switch (type) {
      case _DashboardDeviceType.mppt:
        return 'SmartSolar MPPT';

      case _DashboardDeviceType.shunt:
        return 'SmartShunt / BMV';

      case _DashboardDeviceType.orion:
        return 'Orion DC-DC';

      case _DashboardDeviceType.charger:
        return 'Blue Smart Charger';

      case _DashboardDeviceType.unknown:
        return 'Victron Device';
    }
  }

  String _voltage(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    return '${value.toStringAsFixed(2)} V';
  }

  String _amps(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    return '${value.toStringAsFixed(2)} A';
  }

  String _watts(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    return '${value.toStringAsFixed(0)} W';
  }

  String _percent(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    return '${value.toStringAsFixed(1)} %';
  }

  String _ampHours(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    return '${value.toStringAsFixed(1)} Ah';
  }

  String _energy(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    if (value < 1.0) {
      return '${(value * 1000).toStringAsFixed(0)} Wh';
    }

    return '${value.toStringAsFixed(2)} kWh';
  }

  String _remainingTime(int? minutes) {
    if (minutes == null) {
      return 'Waiting...';
    }

    if (minutes < 0 || minutes >= 0xffff) {
      return '--';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '$mins min';
    }

    return '${hours}h ${mins}m';
  }

  String _chargerError(int? code) {
    if (code == null) {
      return 'Waiting...';
    }

    if (code == 0) {
      return 'No error';
    }

    return 'Error $code';
  }

  String _temperature(double? value) {
    if (value == null) {
      return 'Waiting...';
    }

    return '${value.toStringAsFixed(1)} °C';
  }
}

class _LiveIndicator extends StatelessWidget {
  final DateTime updatedAt;

  const _LiveIndicator({
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(updatedAt);

    final live = age < const Duration(seconds: 45);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          live ? Icons.circle : Icons.circle_outlined,
          size: 10,
        ),
        const SizedBox(width: 5),
        Text(
          live ? 'LIVE' : 'STALE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: live ? Colors.greenAccent : Colors.white38,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum _DashboardDeviceType {
  mppt,
  shunt,
  orion,
  charger,
  unknown,
}
