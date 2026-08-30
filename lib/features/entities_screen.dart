import 'package:flutter/material.dart';

import '../models/rustler_entity.dart';
import '../services/entity_service.dart';

class EntitiesScreen extends StatelessWidget {
  const EntitiesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final EntityService service = EntityService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entities',
        ),
      ),
      body: ValueListenableBuilder<Map<String, RustlerEntity>>(
        valueListenable: service.entities,
        builder: (
          context,
          entities,
          child,
        ) {
          if (entities.isEmpty) {
            return const Center(
              child: Text(
                'No entities available',
              ),
            );
          }

          final List<RustlerEntity> list = entities.values.toList()
            ..sort(
              (
                a,
                b,
              ) =>
                  a.name.compareTo(
                b.name,
              ),
            );

          return ListView.builder(
            padding: const EdgeInsets.all(
              12,
            ),
            itemCount: list.length,
            itemBuilder: (
              context,
              index,
            ) {
              final RustlerEntity entity = list[index];

              return Card(
                child: ListTile(
                  leading: Icon(
                    _icon(
                      entity.type,
                    ),
                  ),
                  title: Text(
                    entity.name,
                  ),
                  subtitle: Text(
                    '${entity.source}\n'
                    '${entity.id}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _value(
                          entity,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        entity.available ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 11,
                          color: entity.available ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _value(
    RustlerEntity entity,
  ) {
    if (!entity.available) {
      return '---';
    }

    final String value = entity.value.toString();

    if (entity.unit == null || entity.unit!.isEmpty) {
      return value;
    }

    return '$value ${entity.unit}';
  }

  static IconData _icon(
    RustlerEntityType type,
  ) {
    switch (type) {
      case RustlerEntityType.sensor:
        return Icons.sensors;

      case RustlerEntityType.binarySensor:
        return Icons.circle_outlined;

      case RustlerEntityType.switchEntity:
        return Icons.toggle_on;

      case RustlerEntityType.number:
        return Icons.numbers;

      case RustlerEntityType.climate:
        return Icons.thermostat;

      case RustlerEntityType.battery:
        return Icons.battery_5_bar;

      case RustlerEntityType.gps:
        return Icons.gps_fixed;

      case RustlerEntityType.media:
        return Icons.music_note;
    }
  }
}
