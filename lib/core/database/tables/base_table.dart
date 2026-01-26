import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Mixin para estandarizar IDs y Auditoría.
/// Cumple con Single Responsibility: Solo define la estructura base.
mixin BaseTable on Table {
  // UUID generado automáticamente si no se provee uno
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  // Auditoría
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Sincronización (Critical for Offline-First)
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
