import 'package:drift/drift.dart';
import 'package:myapp/core/database/app_database.dart'; // Importa tu DB
import 'package:myapp/core/database/tables/app_tables.dart';

part 'matches_dao.g.dart'; // Drift generará esto

@DriftAccessor(tables: [Matches, MatchRosters])
class MatchesDao extends DatabaseAccessor<AppDatabase> with _$MatchesDaoMixin {
  MatchesDao(AppDatabase db) : super(db);

  // Crear un partido
  Future<void> createMatch(MatchesCompanion match) async {
    try {
      await into(matches).insert(match);
    } catch (e) {
      // Aquí manejas la excepción específica de BD y la lanzas como una de tu dominio
      throw Exception('Error al crear partido: $e'); 
    }
  }

  // Obtener partidos pendientes (Stream para UI reactiva)
  Stream<List<Match>> watchPendingMatches() {
    return (select(matches)
          ..where((tbl) => tbl.status.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate)]))
        .watch();
  }

  // Ejemplo de Transacción (Atomicidad)
  // Útil cuando registras un equipo completo: o se guardan todos o ninguno.
  Future<void> addRosterToMatch(String matchId, List<MatchRostersCompanion> roster) async {
    return transaction(() async {
      for (var player in roster) {
        await into(matchRosters).insert(player);
      }
    });
  }
}