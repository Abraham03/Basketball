import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
// Importamos las tablas y DAOs
import 'tables/app_tables.dart';
import 'daos/matches_dao.dart';

part 'app_database.g.dart'; // Archivo generado automáticamente

@DriftDatabase(
  tables: [Matches, Players, MatchRosters, GameEvents],
  daos: [MatchesDao], // Registramos el DAO
)
class AppDatabase extends _$AppDatabase {
  // Singleton pattern (Opcional, pero recomendado en apps simples)
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Migraciones: Aquí manejarás cambios futuros de esquema
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Ejemplo: si en la v2 agregas una columna
      // if (from < 2) await m.addColumn(matches, matches.newColumn);
    },
  );
}

// Función para abrir la conexión nativa
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 1. Obtener la carpeta de documentos de la app
    final dbFolder = await getApplicationDocumentsDirectory();
    
    // 2. Crear la referencia al archivo
    final file = File(p.join(dbFolder.path, 'basketball_league.sqlite'));

    // createInBackground a veces da problemas en release si no se configura bien el ProGuard
    return NativeDatabase(file, logStatements: true); 
  });
}
