import 'package:flutter/material.dart';
import '../../models/rig_profile.dart';
import '../../services/installation_identity_service.dart';
import '../../services/rig_profile_service.dart';

class RigOsIdentityScreen extends StatefulWidget {
  const RigOsIdentityScreen({super.key});
  @override
  State<RigOsIdentityScreen> createState() => _RigOsIdentityScreenState();
}

class _RigOsIdentityScreenState extends State<RigOsIdentityScreen> {
  final identity = InstallationIdentityService.instance;
  final profiles = RigProfileService.instance;
  final name = TextEditingController();
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await profiles.load();
    name.text = await identity.getInstallationName();
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await identity.setInstallationName(name.text);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rig identity saved')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Rig identity')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'This is the name shown on this installation. RigOS stays the platform name.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                  controller: name,
                  decoration: const InputDecoration(
                      labelText: 'Rig / vehicle name',
                      hintText: 'Ranger Rango',
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ValueListenableBuilder<RigProfileType>(
                  valueListenable: profiles.type,
                  builder: (_, v, __) =>
                      DropdownButtonFormField<RigProfileType>(
                        initialValue: v,
                        decoration: const InputDecoration(
                            labelText: 'Installation type',
                            border: OutlineInputBorder()),
                        items: RigProfileType.values
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (x) {
                          if (x != null) profiles.setType(x);
                        },
                      )),
              const SizedBox(height: 16),
              const Card(
                  child: ListTile(
                      leading: Icon(Icons.hiking),
                      title: Text('Brand badge'),
                      subtitle: Text(
                          'Ranger-hat / custom badge slot is enabled in the RigOS identity layer.'))),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE IDENTITY')),
            ]));
}
