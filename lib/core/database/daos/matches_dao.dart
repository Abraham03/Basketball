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

  /// Guarda localmente un jugador creado a mitad de un partido.
  /// Soporta modo Online (ID real, isSynced: true) y Offline (ID negativo, isSynced: false).
  Future<void> saveMidGamePlayerLocally({
    required String matchId,
    required int playerId, // ID real o ID negativo temporal
    required int teamId,
    required String name,
    required int number,
    required String teamSide,
    bool isSynced = true, // <--- NUEVO: Por defecto true, pero en offline pasaremos false
  }) async {
    try {
      await transaction(() async {
        // 1. Insertar en el catálogo global de Jugadores (Players)
        await db.into(db.players).insert(
          PlayersCompanion.insert(
            id: Value(playerId.toString()), 
            teamId: teamId,
            name: name,
            defaultNumber: Value(number),
            isSynced: Value(isSynced), // <--- Dependerá de si hubo red o no
          ),
          mode: InsertMode.insertOrReplace,
        );

        // 2. Vincular el jugador al partido actual (MatchRosters)
        await into(matchRosters).insert(
          MatchRostersCompanion.insert(
            matchId: matchId,
            playerId: playerId.toString(),
            teamSide: teamSide,
            jerseyNumber: number,
            isCaptain: const Value(false),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      });
    } catch (e) {
      throw Exception('Error al persistir el jugador localmente en BD: $e');
    }
  }

  // =========================================================================
  // --- RECONCILIACIÓN OFFLINE-FIRST ---
  // =========================================================================

  /// Intercambia el ID temporal (negativo) por el ID real de la nube.
  /// Utiliza la estrategia Insertar -> Revincular -> Eliminar para evitar 
  /// violaciones de llaves foráneas (Foreign Key Constraints) en SQLite.
  Future<void> replaceTempPlayerId(String oldTempId, String newRealId) async {
    try {
      await transaction(() async {
        // 1. Obtener los datos completos del jugador temporal
        final oldPlayer = await (db.select(db.players)..where((p) => p.id.equals(oldTempId))).getSingleOrNull();
        
        if (oldPlayer != null) {
          // 2. Insertar el "clon" del jugador, pero usando el ID real y marcado como sincronizado
          await db.into(db.players).insert(
            PlayersCompanion.insert(
              id: Value(newRealId),
              teamId: oldPlayer.teamId,
              name: oldPlayer.name,
              defaultNumber: Value(oldPlayer.defaultNumber),
              active: Value(oldPlayer.active),
              isSynced: const Value(true), // El nuevo ID siempre viene de la nube, ya está sincronizado
            ),
            mode: InsertMode.insertOrReplace,
          );
        }

        // 3. Revincular (Actualizar) todas las tablas hijas para que apunten al ID real
        await (update(matchRosters)..where((t) => t.playerId.equals(oldTempId))).write(
          MatchRostersCompanion(playerId: Value(newRealId)),
        );
        
        await (update(gameEvents)..where((t) => t.playerId.equals(oldTempId))).write(
          GameEventsCompanion(playerId: Value(newRealId)),
        );

        // 4. Eliminar el jugador temporal original (ya no tiene hijos dependientes)
        if (oldPlayer != null) {
          await (db.delete(db.players)..where((p) => p.id.equals(oldTempId))).go();
        }
      });
    } catch (e) {
      throw Exception('Error reconciliando IDs del jugador: $e');
    }
  }

  // =========================================================================
  // --- SINCRONIZACIÓN MAESTRA OFFLINE-FIRST ---
  // =========================================================================

  /// Se ejecuta ANTES de sincronizar los partidos atrasados.
  /// Busca todos los jugadores con ID negativo y los sube a la nube.
  Future<void> syncOfflinePlayersBeforeMatches(dynamic api) async {
    // Buscamos jugadores que tengan isSynced en false
    final offlinePlayers = await (select(db.players)..where((p) => p.isSynced.equals(false))).get();

    for (var p in offlinePlayers) {
      final int oldId = int.tryParse(p.id) ?? 0;
      
      // Confirmamos que es un ID temporal generado por nosotros (Negativo)
      if (oldId < 0) { 
        try {
          // 1. Subimos a la nube
          final int realId = await api.addPlayer(p.teamId, p.name, p.defaultNumber);
          
          // 2. Usamos el método de Reconciliación para corregir la BD local
          await replaceTempPlayerId(p.id, realId.toString());
          
        } catch (e) {
          // Ignoramos el error para que el bucle siga intentando con otros jugadores
          // Si este falla, el partido que depende de él también fallará la subida,
          // pero el usuario podrá intentarlo de nuevo más tarde.
          print("Fallo al sincronizar jugador offline: ${p.name}");
        }
      }
    }
  }

}
