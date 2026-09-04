import 'package:flutter/foundation.dart';

import '../models/rustler_entity.dart';

class EntityService {
  EntityService._();

  static final EntityService instance = EntityService._();

  final ValueNotifier<Map<String, RustlerEntity>> entities =
      ValueNotifier<Map<String, RustlerEntity>>(<String, RustlerEntity>{});

  void upsert(RustlerEntity entity) {
    final Map<String, RustlerEntity> updated =
        Map<String, RustlerEntity>.from(entities.value);
    updated[entity.id] = entity;
    entities.value = updated;
  }

  void remove(String entityId) {
    if (!entities.value.containsKey(entityId)) {
      return;
    }

    final Map<String, RustlerEntity> updated =
        Map<String, RustlerEntity>.from(entities.value);
    updated.remove(entityId);
    entities.value = updated;
  }

  void clearSource(String source) {
    final Map<String, RustlerEntity> updated =
        Map<String, RustlerEntity>.from(entities.value)
          ..removeWhere((_, entity) => entity.source == source);
    entities.value = updated;
  }

  RustlerEntity? getEntity(String entityId) => entities.value[entityId];

  List<RustlerEntity> bySource(String source) {
    return entities.value.values
        .where((entity) => entity.source == source)
        .toList(growable: false);
  }

  List<RustlerEntity> byType(RustlerEntityType type) {
    return entities.value.values
        .where((entity) => entity.type == type)
        .toList(growable: false);
  }

  void setSourceAvailability(String source, bool available) {
    final Map<String, RustlerEntity> updated =
        Map<String, RustlerEntity>.from(entities.value);

    for (final MapEntry<String, RustlerEntity> entry
        in entities.value.entries) {
      if (entry.value.source == source) {
        updated[entry.key] = entry.value.copyWith(
          available: available,
          updatedAt: DateTime.now(),
        );
      }
    }

    entities.value = updated;
  }
}
