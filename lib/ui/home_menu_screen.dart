import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart'
    as drift; // Alias para métodos de base de datos
import '../core/database/app_database.dart';
import '../logic/tournament_provider.dart';
import '../logic/catalog_provider.dart';
import 'match_setup_screen.dart';
import 'team_management_screen.dart';

class HomeMenuScreen extends ConsumerWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtener colores del tema
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    // 2. Escuchar el estado de los torneos y la selección actual
    final tournamentsAsync = ref.watch(tournamentsListProvider);
    final selectedTournamentId = ref.watch(selectedTournamentIdProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ============================================
          // HEADER: TÍTULO Y SELECTOR DE TORNEO
          // ============================================
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila del Título y Logo
                Row(
                  children: [
                    Icon(
                      Icons.sports_basketball,
                      size: 32,
                      color: onPrimaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Basket Arbitraje",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Etiqueta "Torneo Activo"
                Text(
                  "Torneo Activo:",
                  style: TextStyle(
                    color: onPrimaryColor.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),

                // Selector (Dropdown) de Torneos
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: tournamentsAsync.when(
                    // Estado Cargando
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    // Estado Error
                    error: (err, stack) => const Text(
                      "Error cargando torneos",
                      style: TextStyle(color: Colors.white),
                    ),
                    // Estado Datos Listos
                    data: (tournaments) {
                      if (tournaments.isEmpty) {
                        return const Text(
                          "Sin torneos (Sincroniza primero)",
                          style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }

                      // Auto-selección: Si no hay torneo seleccionado, elige el primero automáticamente
                      if (selectedTournamentId == null &&
                          tournaments.isNotEmpty) {
                        Future.microtask(
                          () =>
                              ref
                                  .read(selectedTournamentIdProvider.notifier)
                                  .state = tournaments
                                  .first
                                  .id,
                        );
                      }

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: primaryColor,
                          value: selectedTournamentId,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          hint: const Text(
                            "Selecciona un Torneo",
                            style: TextStyle(color: Colors.white70),
                          ),
                          items: tournaments.map((tournament) {
                            return DropdownMenuItem<String>(
                              value: tournament.id,
                              child: Text(
                                tournament.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              ref
                                      .read(
                                        selectedTournamentIdProvider.notifier,
                                      )
                                      .state =
                                  newId;
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ============================================
          // GRID: BOTONES DEL MENÚ PRINCIPAL
          // ============================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  // 1. Jugar Partido
                  _DashboardCard(
                    title: "Jugar Partido",
                    icon: Icons.play_circle_fill,
                    color: Colors.orange,
                    // Validación: Bloquear si no hay torneo seleccionado
                    onTap: selectedTournamentId == null
                        ? () => _showNoTournamentAlert(context)
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchSetupScreen(
                                tournamentId: selectedTournamentId,
                              ),
                            ),
                          ),
                  ),

                  // 2. Gestionar Equipos
                  _DashboardCard(
                    title: "Equipos",
                    icon: Icons.groups,
                    color: Colors.blue,
                    // Validación: Bloquear si no hay torneo seleccionado
                    onTap: selectedTournamentId == null
                        ? () => _showNoTournamentAlert(context)
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamManagementScreen(
                                tournamentId: selectedTournamentId,
                              ),
                            ),
                          ),
                  ),

                  // 3. Sincronizar Datos (Descargar de la Nube)
                  _DashboardCard(
                    title: "Descargar Datos de la Nube",
                    icon: Icons.cloud_sync,
                    color: Colors.purple,
                    onTap: () => _syncData(context, ref),
                  ),

                  // 4. Configuración
                  _DashboardCard(
                    title: "Subir Datos a la Nube",
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () => _uploadPendingData(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE VALIDACIÓN ---
  void _showNoTournamentAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "⚠️ Debes seleccionar un torneo primero (o sincronizar).",
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- LÓGICA DE SINCRONIZACIÓN (Backend PHP -> Local SQLite) ---
  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    // A. Mostrar indicador de carga
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpiar previos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 15),
            Text("Descargando datos del servidor..."),
          ],
        ),
        duration: Duration(
          seconds: 25,
        ), // Duración larga (se cierra manualmente)
      ),
    );

    try {
      // B. Obtener servicios de los Providers
      final api = ref.read(apiServiceProvider);
      final db = ref.read(databaseProvider);

      // C. Petición al Backend (PHP) para traer JSON
      final catalogData = await api.fetchCatalogs();

      // D. Guardar en SQLite usando una Transacción (Atomicidad)
      await db.transaction(() async {
        // 1. Insertar Torneos
        for (var t in catalogData.tournaments) {
          await db
              .into(db.tournaments)
              .insert(
                TournamentsCompanion.insert(
                  id: drift.Value(t.id.toString()),
                  name: t.name,
                  category: drift.Value(t.category),
                  status: drift.Value(t.status ?? 'ACTIVE'),
                  isSynced: const drift.Value(true),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

        // 2. Insertar Equipos (DESCOMENTADO Y CORREGIDO)
        for (var team in catalogData.teams) {
          await db
              .into(db.teams)
              .insert(
                TeamsCompanion.insert(
                  id: drift.Value(team.id.toString()),
                  name: team.name,
                  shortName: drift.Value(team.shortName),
                  coachName: drift.Value(team.coachName),
                  isSynced: const drift.Value(true),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

        // 3. Insertar Sedes / Canchas (AGREGADO)
        for (var venue in catalogData.venues) {
          await db
              .into(db.venues)
              .insert(
                VenuesCompanion.insert(
                  id: drift.Value(venue.id.toString()),
                  name: venue.name,
                  address: drift.Value(venue.address),
                  isSynced: const drift.Value(true),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }
      });

      // 4. Insertar Relaciones Torneo-Equipo
      await db.delete(db.tournamentTeams).go();

      for (var rel in catalogData.relationships) {
        await db
            .into(db.tournamentTeams)
            .insert(
              TournamentTeamsCompanion.insert(
                // CORRECCIÓN: NO USAR drift.Value() AQUÍ
                tournamentId: rel.tournamentId.toString(),
                teamId: rel.teamId.toString(),
                isSynced: const drift.Value(true),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }

      // 5. Insertar Jugadores (CORREGIDO)
      for (var p in catalogData.players) {
        await db
            .into(db.players)
            .insert(
              PlayersCompanion.insert(
                id: drift.Value(
                  p.id.toString(),
                ), // Drift usa String en BaseTable
                name: p.name, // Coincide con la columna nueva
                teamId: p.teamId, // Entero directo
                defaultNumber: drift.Value(p.defaultNumber),
                active: const drift.Value(
                  true,
                ), // Asumimos activos si vienen de la API
                isSynced: const drift.Value(true),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }
      // E. Forzar recarga de la lista de torneos en la UI
      ref.invalidate(tournamentsListProvider);

      // F. Mensaje de Éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Datos sincronizados correctamente."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // G. Manejo de Errores (Red, Base de datos, etc.)
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error de Sincronización"),
            content: SingleChildScrollView(
              child: Text(
                "No se pudo conectar con el servidor o guardar los datos.\n\nDetalle técnico:\n$e",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
      }
    }
  }

  // --- LÓGICA DE SUBIDA (Local SQLite -> Nube PHP) ---
  Future<void> _uploadPendingData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final api = ref.read(apiServiceProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Iniciando diagnóstico y subida...")),
    );

    int uploadedMatches = 0;
    int uploadedPlayers = 0;
    int uploadedTeams = 0;

    try {
      // ---------------------------------------------------------
      // 1. SUBIR EQUIPOS (Teams)
      // ---------------------------------------------------------
      // Es importante subir equipos antes que jugadores o partidos para mantener integridad referencial
      final pendingTeams = await (db.select(
        db.teams,
      )..where((tbl) => tbl.isSynced.equals(false))).get();

for (var team in pendingTeams) {
        try {

          // A. Buscar el ID del torneo asociado localmente
           final relation = await (db.select(db.tournamentTeams)
              ..where((t) => t.teamId.equals(team.id))).getSingleOrNull();
           
           // B. Subir a la API (Ahora con tournamentId)
           final realId = await api.createTeam(
             team.name, 
             team.shortName ?? '', 
             team.coachName ?? '',
             tournamentId: relation?.tournamentId // <--- CRÍTICO
           );
           
           print("Equipo subido. ID Temporal: ${team.id} -> ID Real: $realId");

           await db.transaction(() async {
             // A. Actualizar referencias en TournamentTeams
             await (db.update(db.tournamentTeams)..where((t) => t.teamId.equals(team.id)))
                .write(TournamentTeamsCompanion(teamId: drift.Value(realId.toString())));

             // B. Actualizar referencias en Players (jugadores creados offline asociados a este equipo)
             // Nota: Players.teamId es INT. team.id (temporal) era string "-12345". Hay que parsearlo.
             final tempTeamIdInt = int.tryParse(team.id) ?? 0;
             await (db.update(db.players)..where((p) => p.teamId.equals(tempTeamIdInt))) 
                  .write(PlayersCompanion(teamId: drift.Value(realId)));

             // C. Eliminar equipo temporal e insertar el real con isSynced=true
             await (db.delete(db.teams)..where((t) => t.id.equals(team.id))).go();
             
             await db.into(db.teams).insert(
               TeamsCompanion.insert(
                 id: drift.Value(realId.toString()),
                 name: team.name,
                 shortName: drift.Value(team.shortName),
                 coachName: drift.Value(team.coachName),
                 isSynced: const drift.Value(true),
               )
             );
           });
           
           uploadedTeams++;
        } catch (e) {
           print("Error subiendo equipo ${team.name}: $e");
        }
      }

      // 2. SUBIR JUGADORES (Players)
      final pendingPlayers = await (db.select(db.players)
            ..where((tbl) => tbl.isSynced.equals(false)))
          .get();

      for (var player in pendingPlayers) {
        try {
          // El teamId ya debería ser el real si el paso 1 funcionó, o si se creó online.
          // Si el jugador se creó offline en un equipo offline, el paso 1 ya actualizó su teamId al real.
          final realPlayerId = await api.addPlayer(player.teamId, player.name, player.defaultNumber);
          
          // Reemplazar jugador temporal por real
           await db.transaction(() async {
             await (db.delete(db.players)..where((p) => p.id.equals(player.id))).go();
             
             await db.into(db.players).insert(
               PlayersCompanion.insert(
                 id: drift.Value(realPlayerId.toString()),
                 teamId: player.teamId,
                 name: player.name,
                 defaultNumber: drift.Value(player.defaultNumber),
                 isSynced: const drift.Value(true),
                 active: const drift.Value(true)
               )
             );
           });
            
          uploadedPlayers++;
        } catch (e) {
          print("Error subiendo jugador ${player.name}: $e");
        }
      }

      // ---------------------------------------------------------
      // 3. SUBIR PARTIDOS Y EVENTOS (Matches)
      // ---------------------------------------------------------
      print("--- INICIO DIAGNÓSTICO BD ---");
      final allMatches = await db.select(db.matches).get();
      print("Total Partidos en BD: ${allMatches.length}");

      for (var m in allMatches) {
        print("Partido ID: '${m.id}' (Tipo: ${m.id.runtimeType})");
        print("  - Status: ${m.status}");
        print("  - isSynced: ${m.isSynced}");
        print("  - Firmado: ${m.signatureData != null ? 'SÍ' : 'NO'}");
      }
      print("--- FIN DIAGNÓSTICO BD ---");
      // -------------------------------------------------------

      // Tu consulta original
      final pendingMatches = await (db.select(
        db.matches,
      )..where((tbl) => tbl.isSynced.equals(false))).get();

      print(
        "DEBUG: Partidos pendientes encontrados por filtro: ${pendingMatches.length}",
      );

      for (var match in pendingMatches) {
        print("DEBUG: Intentando subir partido ${match.id}");
        // 3.1. Obtener eventos con JOIN para sacar datos del jugador (número, lado, nombre)
        // Necesitamos unir: GameEvents -> MatchRosters (para numero/lado) -> Players (para nombre)
        final query = db.select(db.gameEvents).join([
          drift.leftOuterJoin(
            db.matchRosters,
            db.matchRosters.matchId.equalsExp(db.gameEvents.matchId) &
                db.matchRosters.playerId.equalsExp(db.gameEvents.playerId),
          ),
          drift.leftOuterJoin(
            db.players,
            db.players.id.equalsExp(db.gameEvents.playerId),
          ),
        ]);

        query.where(db.gameEvents.matchId.equals(match.id));

        // Ordenar por tiempo para que el log tenga sentido (opcional)
        // query.orderBy([drift.OrderingTerm.asc(db.gameEvents.createdAt)]);

        final rows = await query.get();

        // Variables para calcular el "score_after" acumulado (si tu PHP lo requiere exacto)
        int runningScoreA = 0;
        int runningScoreB = 0;

        final eventsList = rows.map((row) {
          final event = row.readTable(db.gameEvents);
          final roster = row.readTableOrNull(db.matchRosters);
          final player = row.readTableOrNull(db.players);

          if (roster == null && event.playerId != null) {
             print("ALERTA: Evento con jugador ${event.playerId} no tiene Roster asociado. JOIN falló.");
          }

          // Lógica de conversión: TYPE -> PUNTOS
          int points = 0;
          if (event.type == 'POINT_1' || event.type == 'FREE_THROW') points = 1;
          if (event.type == 'POINT_2') points = 2;
          if (event.type == 'POINT_3') points = 3;

          // Calcular score acumulado
          if (points > 0 && roster != null) {
            if (roster.teamSide == 'A') runningScoreA += points;
            if (roster.teamSide == 'B') runningScoreB += points;
          }
          final currentScore = (roster?.teamSide == 'A')
              ? runningScoreA
              : runningScoreB;

          return {
            "period": event.period,
            "team_side":
                roster?.teamSide ??
                'A', // Default 'A' si no hay roster (ej. timeout)
            "player_id": event.playerId, // Puede ser nulo (ej. timeout)
            "player_name": player?.name ?? '',
            "player_number": roster?.jerseyNumber ?? 0,
            "points_scored": points,
            "score_after": currentScore, // Tu PHP lo pide
          };
        }).toList();

        // 3.2. Construir payload completo (Coincidiendo con MatchRepository.php)
        final matchPayload = {
          "match_id": match.id,
          "tournament_id": match.tournamentId,
          "venue_id": match.venueId,
          "team_a_id": match.teamAId,
          "team_b_id": match.teamBId,
          "team_a_name": match.teamAName,
          "team_b_name": match.teamBName,
          "score_a": match.scoreA,
          "score_b": match.scoreB,
          "current_period":
              4, // Puedes guardar el periodo actual en Matches si quieres precisión
          "time_left": "00:00", // O match.timeLeft si lo guardas
          // Oficiales (Requerido por PHP)
          "main_referee": match.mainReferee,
          "aux_referee": match.auxReferee,
          "scorekeeper": match.scorekeeper,

          // Firma (Requerido por PHP)
          "signature_base64": match
              .signatureData, // match.signatureData <--- AGREGAR A TABLA (TextColumn grande)

          "status": match.status,
          "events": eventsList,
        };

        // 3.3. Enviar a la nube
        final success = await api.syncMatchData(matchPayload);

        // 3.4. Marcar como sincronizado
        if (success) {
          await (db.update(db.matches)..where((tbl) => tbl.id.equals(match.id)))
              .write(const MatchesCompanion(isSynced: drift.Value(true)));
          uploadedMatches++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sincronización completada.\nEquipos: $uploadedTeams\nJugadores: $uploadedPlayers\nPartidos: $uploadedMatches",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error durante la subida: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================
// WIDGET AUXILIAR: TARJETA DE MENÚ (DASHBOARD)
// ============================================
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.2), // Efecto visual al tocar
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05), // Fondo muy suave
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo con Icono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              // Texto
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
