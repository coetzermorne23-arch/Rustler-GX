import 'package:flutter/material.dart';
import '../dashboard/energy_flow_screen.dart';
import '../device_registry_screen.dart';
import '../driving/gps_custom_screen.dart';
import '../driving/obd_dashboard_settings_screen.dart';
import '../integrations/integrations_screen.dart';
import 'device_pairing_screen.dart';
import 'head_unit_settings_screen.dart';
import 'head_unit_app_cleanup_screen.dart';
import 'rigos_identity_screen.dart';
import 'srne_settings_screen.dart';

class RigOsSettingsScreen extends StatelessWidget {
  const RigOsSettingsScreen({super.key});
  void _open(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute<void>(builder: (_) => w));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('RigOS Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const _Header('RIG'),
        _Tile(
            Icons.badge_outlined,
            'Identity & profile',
            'Name this installation, e.g. Ranger Rango; Vehicle / Caravan / Camper / Portable / Custom',
            () => _open(context, const RigOsIdentityScreen())),
        const _Header('DEVICES & INTEGRATIONS'),
        _Tile(
            Icons.add_link,
            'Add / pair device',
            'Bluetooth • local network • IP / hostname • QR • USB/gateway architecture',
            () => _open(context, const DevicePairingScreen())),
        _Tile(
            Icons.devices_other,
            'Device registry',
            'All devices and normalized entities',
            () => _open(context, const DeviceRegistryScreen())),
        _Tile(
            Icons.hub,
            'Local integrations',
            'ESP • Sonoff DIY • Tuya bridge • custom local JSON',
            () => _open(context, const IntegrationsScreen())),
        _Tile(
            Icons.electrical_services,
            'SRNE inverter',
            'Local Wi-Fi / Modbus TCP endpoint',
            () => _open(context, const SrneSettingsScreen())),
        const _Header('DASHBOARDS'),
        _Tile(
            Icons.account_tree,
            'Energy flow',
            'Universal solar / battery / DC-DC / inverter flow',
            () => _open(context, const EnergyFlowScreen())),
        _Tile(
            Icons.satellite_alt,
            'GPS & satellites',
            'Show/hide/reorder GNSS information',
            () => _open(context, const GpsCustomScreen())),
        _Tile(Icons.speed, 'OBD dashboard', 'Dials/cards and visible data',
            () => _open(context, const ObdDashboardSettingsScreen())),
        const _Header('HEAD UNIT'),
        _Tile(
            Icons.car_crash_outlined,
            'Android head unit',
            'HOME role, boot/wake, USB, steering/call platform',
            () => _open(context, const HeadUnitSettingsScreen())),
        _Tile(
            Icons.apps_outage,
            'Head-unit app cleanup',
            'List stock launcher apps and open Android App Info to disable/force-stop bloat safely',
            () => _open(context, const HeadUnitAppCleanupScreen())),
        const SizedBox(height: 18),
        const Card(
            child: ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('Local-first by design'),
                subtitle: Text(
                    'RigOS control paths are designed to work without cloud access. Remote access can be layered through your VPN/Tailscale-capable router or gateway.'))),
      ]));
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 7),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white54)));
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback tap;
  const _Tile(this.icon, this.title, this.sub, this.tap);
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: Icon(icon),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: tap));
}
