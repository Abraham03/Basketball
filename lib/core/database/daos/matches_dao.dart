import 'package:drift/drift.dart';
import 'package:myapp/core/database/app_database.dart'; // Importa tu DB
import 'package:myapp/core/database/tables/app_tables.dart';

part 'matches_dao.g.dart'; // Drift generará esto

@DriftAccessor(tables: [Matches, MatchRosters, GameEvents])
class MatchesDao extends DatabaseAccessor<AppDatabase> with _$MatchesDaoMixin {
  MatchesDao(super.db);

  // Crear un partido
  Future<void> createMatch(MatchesCompanion match) async {
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
    String? fixtureId,
    int teamAId,
    int teamBId,
    String mainRef,
    String auxRef,
    String scorek,
  ) async {
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

    // Vinculamos localmente el partido con el calendario para que 
    // cuando regrese el internet, el proceso de Sync sepa a qué fixture pertenece.
    if (fixtureId != null) {
      await (db.update(db.fixtures)..where((f) => f.id.equals(fixtureId))).write(
        FixturesCompanion(
          matchId: Value(matchId),
          status: const Value('IN_PROGRESS'), // Opcional: marcarlo en curso localmente
        ),
      );
    }
  

  }

  // Agrega también el campo para la firma
  Future<int> saveSignature(String matchId, String signatureBase64) async {
    // Convertimos a String explícitamente por seguridad
    final idStr = matchId.toString();
      final rowAffected = await (update(matches)..where((t) => t.id.equals(idStr))).write(
      MatchesCompanion(
        signatureData: Value(signatureBase64),
        isSynced: const Value(false),
      ),
    );

    return rowAffected;
  }

  // Marcar un partido como SINCRONIZADO
  Future<void> markAsSynced(String matchId) async {
    await (update(matches)..where((t) => t.id.equals(matchId))).write(
      const MatchesCompanion(
        isSynced: Value(true),
      ),
    );
  }

  // Registra cada punto o falta como un evento individual
  Future<void> insertEvent(GameEventsCompanion event) async {
    await into(gameEvents).insert(event);
  }

  // Ejemplo de Transacción (Atomicidad)
  // Útil cuando registras un equipo completo: o se guardan todos o ninguno.
  Future<void> addRosterToMatch(
    String matchId,
    List<MatchRostersCompanion> roster,
  ) async {
    return transaction(() async {
      for (var player in roster) {
        await into(matchRosters).insert(player);
      }
    });
  }

  /// Guarda localmente un jugador creado a mitad de un partido de forma atómica.
  /// Se inserta en el catálogo general de jugadores y se vincula al roster del partido actual.
  Future<void> saveMidGamePlayerLocally({
    required String matchId,
    required int playerId, // ID real que nos devuelve la API
    required int teamId,
    required String name,
    required int number,
    required String teamSide,
  }) async {
    try {
      // Transacción atómica: Todo o nada.
      await transaction(() async {
        
        // 1. Insertar o actualizar en el catálogo global de Jugadores (Players)
        await db.into(db.players).insert(
          PlayersCompanion.insert(
            // Sobrescribimos el UUID del BaseTable explícitamente con el ID de la nube
            id: Value(playerId.toString()), 
            teamId: teamId,
            name: name,
            defaultNumber: Value(number),
            isSynced: const Value(true), // Viene de la nube, no necesita sincronizarse
          ),
          mode: InsertMode.insertOrReplace, // Si ya existía por caché, lo actualiza
        );

        // 2. Vincular el jugador al partido actual (MatchRosters)
        await into(matchRosters).insert(
          MatchRostersCompanion.insert(
            // No pasamos 'id' aquí. El clientDefault del BaseTable generará el UUID automáticamente.
            matchId: matchId,
            playerId: playerId.toString(), // Llave foránea hacia Players
            teamSide: teamSide,            // 'A' o 'B'
            jerseyNumber: number,
            isCaptain: const Value(false), // No puede ser capitán por llegar tarde
          ),
          mode: InsertMode.insertOrIgnore, // Previene error si el usuario presiona el botón 2 veces rápido
        );
        
      });
    } catch (e) {
      // Captura y propaga a la capa superior (Controller -> UI)
      throw Exception('Error al persistir el jugador localmente en BD: $e');
    }
  }

}
