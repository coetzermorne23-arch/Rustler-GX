import 'package:flutter/material.dart';

import '../services/capability_runtime_service.dart';
import '../services/installation_identity_service.dart';

class InstallationSettingsScreen extends StatefulWidget {
  const InstallationSettingsScreen({
    super.key,
  });

  @override
  State<InstallationSettingsScreen> createState() =>
      _InstallationSettingsScreenState();
}

class _InstallationSettingsScreenState
    extends State<InstallationSettingsScreen> {
  final InstallationIdentityService identity =
      InstallationIdentityService.instance;

  final CapabilityRuntimeService runtime = CapabilityRuntimeService.instance;

  final TextEditingController nameController = TextEditingController();

  String installationId = '';
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    installationId = await identity.getInstallationId();

    nameController.text = await identity.getInstallationName();

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
    });

    try {
      await identity.setInstallationName(
        nameController.text,
      );

      await runtime.restartHubAdvertising();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Installation settings saved.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Installation',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Installation',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Installation name',
              hintText: 'Caravan Hub',
              prefixIcon: Icon(Icons.edit),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.fingerprint,
              ),
              title: const Text(
                'Installation ID',
              ),
              subtitle: SelectableText(
                installationId,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(
              Icons.save,
            ),
            label: Text(
              saving ? 'SAVING...' : 'SAVE',
            ),
          ),
        ],
      ),
    );
  }
}
