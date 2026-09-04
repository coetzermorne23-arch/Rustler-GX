import 'package:flutter/material.dart';
import '../../services/head_unit_app_service.dart';
import '../../services/head_unit_platform_service.dart';

class HeadUnitAppCleanupScreen extends StatefulWidget {
  const HeadUnitAppCleanupScreen({super.key});
  @override
  State<HeadUnitAppCleanupScreen> createState() => _State();
}

class _State extends State<HeadUnitAppCleanupScreen> {
  final service = HeadUnitAppService.instance;
  final platform = HeadUnitPlatformService.instance;
  String filter = 'ALL';

  @override
  void initState() {
    super.initState();
    service.refresh();
    platform.refresh();
  }

  Future<void> _message(Future<String> action) async {
    final result = await action;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('RigOS Head Unit'),
        content: SelectableText(result),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DO IT'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('HEAD UNIT • PERFORMANCE'),
          actions: [
            IconButton(
              onPressed: service.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: platform.defaultHome,
              builder: (_, isHome, __) => Card(
                margin: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        isHome ? Icons.home_filled : Icons.home_outlined,
                      ),
                      title: Text(
                        isHome ? 'RigOS IS HOME' : 'SET RIGOS AS HOME',
                      ),
                      subtitle: const Text(
                        'Android boots directly into RigOS when HOME is assigned.',
                      ),
                      trailing: isHome
                          ? const Icon(Icons.check_circle)
                          : FilledButton(
                              onPressed: platform.requestHomeRole,
                              child: const Text('SET HOME'),
                            ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: service.rootAvailable,
                      builder: (_, root, __) => ListTile(
                        leading: Icon(root ? Icons.lock_open : Icons.lock),
                        title: Text(
                          root
                              ? 'Privileged package control available'
                              : 'No root/package privilege detected',
                        ),
                        subtitle: Text(
                          root
                              ? 'RigOS can disable and restore packages directly.'
                              : 'RigOS will fall back to Android App Info for package changes.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('DISABLE SAFE BLOAT'),
                    onPressed: () async {
                      if (!await _confirm(
                        'Disable safe bloat?',
                        'RigOS will only target packages classified SAFE TO DISABLE. '
                            'MCU/CAN/Bluetooth/FM/audio/DSP/USB/GPS/system packages are protected.',
                      )) return;
                      final results = await service.disableSafeBloat();
                      if (!mounted) return;
                      await _message(Future.value(
                        results.isEmpty
                            ? 'No safe bloat found.'
                            : results.join('\n'),
                      ));
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.home_work_outlined),
                    label: const Text('DISABLE STOCK HOME'),
                    onPressed: () async {
                      await platform.refresh();
                      if (!platform.defaultHome.value) {
                        await _message(Future.value(
                          'RigOS must be confirmed as Android HOME first.',
                        ));
                        return;
                      }
                      if (!await _confirm(
                        'Disable other HOME apps?',
                        'RigOS is already HOME. Only unprotected HOME candidates will be targeted.',
                      )) return;
                      await _message(service.disableOtherHomeApps());
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('RESTORE ALL'),
                    onPressed: () async {
                      await service.restoreAll();
                      await _message(Future.value('Restore pass complete.'));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final f in const [
                    'ALL',
                    'SAFE',
                    'KEEP',
                    'UNKNOWN',
                    'DISABLED'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: filter == f,
                        onSelected: (_) => setState(() => filter = f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<HeadUnitAppInfo>>(
                valueListenable: service.apps,
                builder: (_, apps, __) => ValueListenableBuilder<Set<String>>(
                  valueListenable: service.disabledByRigOs,
                  builder: (_, disabled, __) {
                    final shown = apps.where((app) {
                      if (filter == 'SAFE') {
                        return app.classification ==
                            HeadUnitPackageClass.safeToDisable;
                      }
                      if (filter == 'KEEP') {
                        return app.classification ==
                            HeadUnitPackageClass.vendorKeep;
                      }
                      if (filter == 'UNKNOWN') {
                        return app.classification ==
                            HeadUnitPackageClass.unknown;
                      }
                      if (filter == 'DISABLED') {
                        return disabled.contains(app.packageName);
                      }
                      return true;
                    }).toList();

                    return ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final app = shown[i];
                        final rigDisabled = disabled.contains(app.packageName);
                        final protected = app.classification ==
                            HeadUnitPackageClass.vendorKeep;
                        return ListTile(
                          leading: Icon(
                            protected
                                ? Icons.shield
                                : rigDisabled
                                    ? Icons.block
                                    : Icons.apps,
                          ),
                          title: Text(app.label),
                          subtitle: Text(
                            '${app.packageName}\n${app.classLabel}'
                            '${app.homeCandidate ? ' • HOME' : ''}'
                            '${app.system ? ' • SYSTEM' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: rigDisabled
                              ? IconButton(
                                  tooltip: 'Restore',
                                  icon: const Icon(Icons.restore),
                                  onPressed: () => _message(
                                    service.enable(app.packageName),
                                  ),
                                )
                              : protected
                                  ? const Icon(Icons.lock)
                                  : IconButton(
                                      tooltip: 'Disable',
                                      icon:
                                          const Icon(Icons.power_settings_new),
                                      onPressed: () async {
                                        if (!await _confirm(
                                          'Disable ${app.label}?',
                                          '${app.classLabel}\n\n${app.packageName}',
                                        )) return;
                                        await _message(service.disable(app));
                                      },
                                    ),
                          onTap: () => service.openDetails(app.packageName),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
}
