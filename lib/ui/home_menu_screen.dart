import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart'; // Asegúrate de tener uuid en pubspec.yaml

import '../core/database/app_database.dart';
import '../logic/tournament_provider.dart';
import '../logic/catalog_provider.dart';
import 'fixture_list_screen.dart';
import 'match_setup_screen.dart';
import 'team_management_screen.dart';

class HomeMenuScreen extends ConsumerStatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  ConsumerState<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends ConsumerState<HomeMenuScreen> {
  bool _isAdminMode = false;
  int _tapCount = 0;

  void _toggleAdminMode() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _isAdminMode = !_isAdminMode;
        _tapCount = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAdminMode ? "🔓 Modo Admin ACTIVADO" : "🔒 Modo Admin DESACTIVADO"),
            duration: const Duration(seconds: 1),
            backgroundColor: _isAdminMode ? Colors.green : Colors.grey,
          ),
        );
      }
    });
  }

  // --- LÓGICA PARA CREAR TORNEO ---
  Future<void> _createNewTournament(String name, String category) async {
    final api = ref.read(apiServiceProvider);
    final db = ref.read(databaseProvider);

    try {
      // 1. Intentar subir a la Nube
      await api.createTournament(name, category);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("☁️ Torneo creado en la nube correctamente"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // 2. Si falla (Offline), guardar Localmente
      // Generamos un ID temporal (UUID) para uso local
      final tempId = const Uuid().v4(); 
      
      await db.into(db.tournaments).insert(
        TournamentsCompanion.insert(
          id: drift.Value(tempId),
          name: name,
          category: drift.Value(category),
          status: const drift.Value('ACTIVE'),
          isSynced: const drift.Value(false), // Marcado para subir luego
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("💾 Sin conexión: Torneo guardado localmente."), 
            backgroundColor: Colors.orange
          ),
        );
      }
    } finally {
      // Recargar la lista de torneos
      ref.invalidate(tournamentsListProvider);
      Navigator.pop(context); // Cerrar diálogo
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Torneo"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre del Torneo", hintText: "Ej: Liga Municipal 2026"),
                validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: "Categoría", hintText: "Ej: Libre Varonil"),
                validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _createNewTournament(nameCtrl.text, catCtrl.text);
              }
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    final tournamentsAsync = ref.watch(tournamentsListProvider);
    final selectedTournamentId = ref.watch(selectedTournamentIdProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // --- BOTÓN FLOTANTE NUEVO ---
      floatingActionButton: _isAdminMode ? FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Torneo"),
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
      ) : null, // Solo visible en modo admin
      
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen = constraints.maxWidth > 600;
          final int crossAxisCount = isWideScreen ? 4 : 2;
          final double contentWidth = isWideScreen ? 800 : double.infinity;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
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
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _toggleAdminMode,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
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
                              if (_isAdminMode) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.lock_open, size: 16, color: Colors.greenAccent),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "Torneo Activo:",
                          style: TextStyle(
                            color: onPrimaryColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // SELECTOR DE TORNEO
                        tournamentsAsync.when(
                          loading: () => const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          error: (err, stack) => const Text(
                            "Error cargando torneos",
                            style: TextStyle(color: Colors.white),
                          ),
                          data: (tournaments) {
                            if (tournaments.isEmpty) {
                              return const Text(
                                "Sin torneos (Crea uno nuevo +)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            }

                            if (selectedTournamentId == null && tournaments.isNotEmpty) {
                              Future.microtask(
                                () => ref
                                    .read(selectedTournamentIdProvider.notifier)
                                    .state = tournaments.first.id,
                              );
                            }

                            final selectedName = tournaments
                                .firstWhere(
                                  (t) => t.id == selectedTournamentId,
                                  orElse: () => tournaments.first,
                                )
                                .name;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showTournamentPicker(
                                  context,
                                  tournaments,
                                  ref,
                                  selectedTournamentId,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ============================================
                  // GRID RESPONSIVO
                  // ============================================
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: isWideScreen ? 1.3 : 1.0,
                        children: [
                          // 1. Jugar Partido (SIEMPRE VISIBLE)
                          _DashboardCard(
                            title: "Jugar Partido",
                            icon: Icons.play_circle_fill,
                            color: Colors.orange,
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

                          if (_isAdminMode) ...[
                            // 2. Gestionar Equipos
                            _DashboardCard(
                              title: "Equipos",
                              icon: Icons.groups,
                              color: Colors.blue,
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

                            _DashboardCard(
                                title: "Calendario",
                                icon: Icons.calendar_month,
                                color: Colors.teal,
                                onTap: selectedTournamentId == null
                                    ? () => _showNoTournamentAlert(context)
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FixtureListScreen(
                                              tournamentId: selectedTournamentId,
                                            ),
                                          ),
                                        ),
                              ),

                            // 3. Sincronizar (Descargar)
                            _DashboardCard(
                              title: "Descargar de Nube",
                              icon: Icons.cloud_sync,
                              color: Colors.purple,
                              onTap: () => _syncData(context, ref),
                            ),

                            // 4. Subir Datos
                            _DashboardCard(
                              title: "Subir a Nube",
                              icon: Icons.upload_file,
                              color: Colors.grey,
                              onTap: () => _uploadPendingData(context, ref),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTournamentPicker(
    BuildContext context,
    List<dynamic> tournaments,
    WidgetRef ref,
    String? currentId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Selecciona un Torneo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: tournaments.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final t = tournaments[index];
                      final isSelected = t.id == currentId;
                      return ListTile(
                        leading: Icon(
                          Icons.emoji_events,
                          color: isSelected ? Colors.orange : Colors.grey,
                        ),
                        title: Text(
                          t.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.orange : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.orange)
                            : null,
                        onTap: () {
                          ref
                              .read(selectedTournamentIdProvider.notifier)
                              .state = t.id;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  // --- LÓGICA DE SINCRONIZACIÓN (MANTENIDA IGUAL) ---
  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        duration: Duration(seconds: 25),
      ),
    );

    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(databaseProvider);
      final catalogData = await api.fetchCatalogs();

      await db.transaction(() async {
        for (var t in catalogData.tournaments) {
          await db.into(db.tournaments).insert(
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

        // NUEVO: Descargar Fixtures para los torneos activos
      for (var t in catalogData.tournaments) {
        try {
          final fixtureData = await api.fetchFixture(t.id.toString());
          if (fixtureData.isNotEmpty && fixtureData['rounds'] != null) {
            
            // Borramos los fixtures anteriores de este torneo
            await (db.delete(db.fixtures)..where((f) => f.tournamentId.equals(t.id.toString()))).go();

            final roundsMap = fixtureData['rounds'] as Map<String, dynamic>;
            
            await db.transaction(() async {
              for (var entry in roundsMap.entries) {
                final roundName = entry.key;
                final matches = entry.value as List;
                
                for (var m in matches) {
                  DateTime? scheduledDate;
                  if (m['scheduled_datetime'] != null && m['scheduled_datetime'].toString().isNotEmpty) {
                    scheduledDate = DateTime.tryParse(m['scheduled_datetime']);
                  }

                  await db.into(db.fixtures).insert(
                    FixturesCompanion.insert(
                      id: m['id'].toString(), // ID real de MYSQL
                      tournamentId: t.id.toString(),
                      roundName: roundName,
                      teamAId: m['team_a_id'].toString(),
                      teamBId: m['team_b_id'].toString(),
                      teamAName: m['team_a'] ?? 'Equipo A',
                      teamBName: m['team_b'] ?? 'Equipo B',
                      logoA: drift.Value(m['logo_a']),
                      logoB: drift.Value(m['logo_b']),
                      venueId: drift.Value(m['venue_id']?.toString()),
                      venueName: drift.Value(m['venue_name']),
                      scheduledDatetime: drift.Value(scheduledDate),
                      status: drift.Value(m['status'] ?? 'SCHEDULED'),
                    ),
                    mode: drift.InsertMode.insertOrReplace
                  );
                }
              }
            });
          }
        } catch (e) {
          debugPrint("Error al descargar fixture del torneo ${t.id}: $e");
        }
      }

        for (var team in catalogData.teams) {
          await db.into(db.teams).insert(
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

        for (var venue in catalogData.venues) {
          await db.into(db.venues).insert(
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

      await db.delete(db.tournamentTeams).go();
      for (var rel in catalogData.relationships) {
        await db.into(db.tournamentTeams).insert(
              TournamentTeamsCompanion.insert(
                tournamentId: rel.tournamentId.toString(),
                teamId: rel.teamId.toString(),
                isSynced: const drift.Value(true),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }

      for (var p in catalogData.players) {
        await db.into(db.players).insert(
              PlayersCompanion.insert(
                id: drift.Value(p.id.toString()),
                name: p.name,
                teamId: p.teamId,
                defaultNumber: drift.Value(p.defaultNumber),
                active: const drift.Value(true),
                isSynced: const drift.Value(true),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }
      
      ref.invalidate(tournamentsListProvider);

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error de Sincronización"),
            content: SingleChildScrollView(
              child: Text("No se pudo conectar... \n\n$e"),
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

  // --- LÓGICA DE SUBIDA (MANTENIDA IGUAL) ---
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
      // 1. SUBIR EQUIPOS
      final pendingTeams = await (db.select(db.teams)
            ..where((tbl) => tbl.isSynced.equals(false)))
          .get();

      for (var team in pendingTeams) {
        try {
          final relation = await (db.select(db.tournamentTeams)
                ..where((t) => t.teamId.equals(team.id)))
              .getSingleOrNull();

          final realId = await api.createTeam(
            team.name,
            team.shortName ?? '',
            team.coachName ?? '',
            tournamentId: relation?.tournamentId,
          );

          await db.transaction(() async {
            await (db.update(db.tournamentTeams)
                  ..where((t) => t.teamId.equals(team.id)))
                .write(
              TournamentTeamsCompanion(teamId: drift.Value(realId.toString())),
            );

            final tempTeamIdInt = int.tryParse(team.id) ?? 0;
            await (db.update(db.players)
                  ..where((p) => p.teamId.equals(tempTeamIdInt)))
                .write(PlayersCompanion(teamId: drift.Value(realId)));

            await (db.delete(db.teams)
                  ..where((t) => t.id.equals(team.id)))
                .go();

            await db.into(db.teams).insert(
                  TeamsCompanion.insert(
                    id: drift.Value(realId.toString()),
                    name: team.name,
                    shortName: drift.Value(team.shortName),
                    coachName: drift.Value(team.coachName),
                    isSynced: const drift.Value(true),
                  ),
                );
          });

          uploadedTeams++;
        } catch (e) {
          throw Exception('Error al subir equipo: $e');
        }
      }

      // 2. SUBIR JUGADORES
      final pendingPlayers = await (db.select(db.players)
            ..where((tbl) => tbl.isSynced.equals(false)))
          .get();

      for (var player in pendingPlayers) {
        try {
          final realPlayerId = await api.addPlayer(
            player.teamId,
            player.name,
            player.defaultNumber,
          );

          await db.transaction(() async {
            await (db.delete(db.players)
                  ..where((p) => p.id.equals(player.id)))
                .go();

            await db.into(db.players).insert(
                  PlayersCompanion.insert(
                    id: drift.Value(realPlayerId.toString()),
                    teamId: player.teamId,
                    name: player.name,
                    defaultNumber: drift.Value(player.defaultNumber),
                    isSynced: const drift.Value(true),
                    active: const drift.Value(true),
                  ),
                );
          });

          uploadedPlayers++;
        } catch (e) {
          throw Exception('Error al subir jugador: $e');
        }
      }

      // 3. SUBIR PARTIDOS
      final pendingMatches = await (db.select(db.matches)
            ..where((tbl) => tbl.isSynced.equals(false)))
          .get();

      for (var match in pendingMatches) {
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
        final rows = await query.get();

        int runningScoreA = 0;
        int runningScoreB = 0;

        final eventsList = rows.map((row) {
          final event = row.readTable(db.gameEvents);
          final roster = row.readTableOrNull(db.matchRosters);
          final player = row.readTableOrNull(db.players);

          int points = 0;
          if (event.type == 'POINT_1' || event.type == 'FREE_THROW') points = 1;
          if (event.type == 'POINT_2') points = 2;
          if (event.type == 'POINT_3') points = 3;

          if (points > 0 && roster != null) {
            if (roster.teamSide == 'A') runningScoreA += points;
            if (roster.teamSide == 'B') runningScoreB += points;
          }
          final currentScore =
              (roster?.teamSide == 'A') ? runningScoreA : runningScoreB;

          return {
            "period": event.period,
            "team_side": roster?.teamSide ?? 'A',
            "player_id": event.playerId,
            "player_name": player?.name ?? '',
            "player_number": roster?.jerseyNumber ?? 0,
            "points_scored": points,
            "score_after": currentScore,
          };
        }).toList();

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
          "current_period": 4,
          "time_left": "00:00",
          "main_referee": match.mainReferee,
          "aux_referee": match.auxReferee,
          "scorekeeper": match.scorekeeper,
          "signature_base64": match.signatureData,
          "status": match.status,
          "events": eventsList,
        };

        final success = await api.syncMatchData(matchPayload);

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

// Widget auxiliar para las tarjetas (MANTENIDO IGUAL)
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
        splashColor: color.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
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