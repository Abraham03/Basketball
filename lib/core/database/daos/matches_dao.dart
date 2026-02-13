import 'package:drift/drift.dart';
import 'package:myapp/core/database/app_database.dart'; // Importa tu DB
import 'package:myapp/core/database/tables/app_tables.dart';

part 'matches_dao.g.dart'; // Drift generará esto

@DriftAccessor(tables: [Matches, MatchRosters, GameEvents])
class MatchesDao extends DatabaseAccessor<AppDatabase> with _$MatchesDaoMixin {
  MatchesDao(super.db);

  // Crear un partido
  Future<void> createMatch(MatchesCompanion match) async {
    print("DEBUG: createMatch: Creando partido");
    try {
      await into(matches).insert(match);
    } catch (e) {
      // Aquí manejas la excepción específica de BD y la lanzas como una de tu dominio
      throw Exception('Error al crear partido: $e');
    }
  }



  // --- ACTUALIZACIÓN (NUEVO) ---
  // Guardar el estado actual del partido (Persistencia Real)
  Future<void> updateMatchStatus(
    String matchId,
    int scoreA,
    int scoreB,
    String clockTime,
    String status,
  ) async {
    print("DEBUG: UpdateMatchStatus: Actualizando estatus match $matchId a NO SINCRONIZADO");
    await (update(matches)..where((t) => t.id.equals(matchId))).write(
      MatchesCompanion(
        scoreA: Value(scoreA),
        scoreB: Value(scoreB),
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  // Método para guardar metadatos del partido (Árbitros, IDs, etc.)
  Future<void> updateMatchMetadata(
    String matchId,
    int teamAId,
    int teamBId,
    String mainRef,
    String auxRef,
    String scorek,
  ) async {
    print("DEBUG: updateMatchMedatada: Actualizando metadatos match $matchId a NO SINCRONIZADO");
    await (update(matches)..where((t) => t.id.equals(matchId))).write(
      MatchesCompanion(
        teamAId: Value(teamAId),
        teamBId: Value(teamBId),
        mainReferee: Value(mainRef),
        auxReferee: Value(auxRef),
        scorekeeper: Value(scorek),
        isSynced: const Value(false),
      ),
    );
  }

  // Agrega también el campo para la firma
  Future<int> saveSignature(String matchId, String signatureBase64) async {
    print("DEBUG: saveSignature: Guardando firma match $matchId a NO SINCRONIZADO");
    // Convertimos a String explícitamente por seguridad
    final idStr = matchId.toString();
      final rowAffected = await (update(matches)..where((t) => t.id.equals(idStr))).write(
      MatchesCompanion(
        signatureData: Value(signatureBase64),
        isSynced: const Value(false),
      ),
    );

    print("DEBUG: saveSignature: Row affected: $rowAffected");
    return rowAffected;
  }

  // Marcar un partido como SINCRONIZADO
  Future<void> markAsSynced(String matchId) async {
    print("DEBUG: markAsSynced: Marcando partido $matchId como SINCRONIZADO");
    await (update(matches)..where((t) => t.id.equals(matchId))).write(
      const MatchesCompanion(
        isSynced: Value(true),
      ),
    );
  }

  // Registra cada punto o falta como un evento individual
  Future<void> insertEvent(GameEventsCompanion event) async {
    print("DEBUG: insertEvent: Agregando evento a match ${event.matchId}");
    await into(gameEvents).insert(event);
  }

  // Ejemplo de Transacción (Atomicidad)
  // Útil cuando registras un equipo completo: o se guardan todos o ninguno.
  Future<void> addRosterToMatch(
    String matchId,
    List<MatchRostersCompanion> roster,
  ) async {
    print("DEBUG: addRosterToMatch: Agregando equipo $matchId");
    return transaction(() async {
      for (var player in roster) {
        await into(matchRosters).insert(player);
      }
    });
  }
}
