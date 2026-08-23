import 'package:flutter/foundation.dart';

import '../models/rustler_entity.dart';

class EntityService {
  EntityService._();

  static final EntityService instance =
      EntityService._();

  final ValueNotifier<Map<String, RustlerEntity>>
      entities =
      ValueNotifier<Map<String, RustlerEntity>>({});

  void upsert(RustlerEntity entity) {
    final updated =
        Map<String, RustlerEntity>.from(
      entities.value,
    );

    updated[entity.id] = entity;

    entities.value = updated;
  }

  RustlerEntity? get(String id) {
    return entities.value[id];
  }

  void remove(String id) {
    final updated =
        Map<String, RustlerEntity>.from(
      entities.value);

    updated.remove(id);

    entities.value = updated;
  }

  void clear() {
    entities.value = {};
  }
}