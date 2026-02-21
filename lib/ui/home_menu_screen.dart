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
    String finalId = "";

    try {
      // 1. Intentar subir a la Nube (Online)
      // Como ApiService ahora devuelve Future<String>, esto ya no dará error "void"
      finalId = await api.createTournament(name, category);
      
      // Guardar también en Drift para que exista localmente de inmediato
      await db.into(db.tournaments).insert(
        TournamentsCompanion.insert(
          id: drift.Value(finalId),
          name: name,
          category: drift.Value(category),
          status: const drift.Value('ACTIVE'),
          isSynced: const drift.Value(true),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("☁️ Torneo creado en la nube correctamente"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // 2. Si falla (Offline), guardar Localmente con un UUID
      finalId = const Uuid().v4(); 
      
      await db.into(db.tournaments).insert(
        TournamentsCompanion.insert(
          id: drift.Value(finalId),
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
      // 1. Actualizamos el Provider del Torneo Activo para que apunte al nuevo
      ref.read(selectedTournamentIdProvider.notifier).state = finalId;
      
      // 2. Invalidamos la lista para que el Dropdown se redibuje con el nuevo torneo
      ref.invalidate(tournamentsListProvider);
      
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo
      }
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
      // Botón Flotante
      floatingActionButton: _isAdminMode ? FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Torneo"),
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
      ) : null,
      
      body: Stack(
        children: [
          // 1. IMAGEN DE FONDO
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo1.jpg', // <--- Asegúrate que exista en tu carpeta y pubspec.yaml
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. CAPA DE OSCURECIMIENTO (Para legibilidad)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 3. CONTENIDO PRINCIPAL
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth > 600;
              final int crossAxisCount = isWideScreen ? 4 : 2;
              final double contentWidth = isWideScreen ? 800 : double.infinity;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      // HEADER: TÍTULO Y SELECTOR
                      Container(
                        padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.85), // Un poco de transparencia
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
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
                                  Icon(Icons.sports_basketball, size: 32, color: onPrimaryColor),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Basket Arbitraje",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onPrimaryColor),
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
                              style: TextStyle(color: onPrimaryColor.withOpacity(0.8), fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            tournamentsAsync.when(
                              loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              error: (err, stack) => const Text("Error cargando torneos", style: TextStyle(color: Colors.white)),
                              data: (tournaments) {
                                if (tournaments.isEmpty) {
                                  return const Text("Sin torneos (Crea uno nuevo +)", style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic));
                                }
                                if (selectedTournamentId == null && tournaments.isNotEmpty) {
                                  Future.microtask(() => ref.read(selectedTournamentIdProvider.notifier).state = tournaments.first.id);
                                }
                                final selectedName = tournaments.firstWhere((t) => t.id == selectedTournamentId, orElse: () => tournaments.first).name;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _showTournamentPicker(context, tournaments, ref, selectedTournamentId),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(selectedName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          const Icon(Icons.arrow_drop_down, color: Colors.white),
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

                      // GRID DE TARJETAS
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: isWideScreen ? 1.3 : 1.0,
                            children: [
                              _DashboardCard(
                                title: "Jugar Partido",
                                icon: Icons.play_circle_fill,
                                color: Colors.orange,
                                onTap: selectedTournamentId == null
                                    ? () => _showNoTournamentAlert(context)
                                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchSetupScreen(tournamentId: selectedTournamentId))),
                              ),
                              if (_isAdminMode) ...[
                                _DashboardCard(
                                  title: "Equipos",
                                  icon: Icons.groups,
                                  color: Colors.blue,
                                  onTap: selectedTournamentId == null
                                      ? () => _showNoTournamentAlert(context)
                                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamManagementScreen(tournamentId: selectedTournamentId))),
                                ),
                                _DashboardCard(
                                    title: "Calendario",
                                    icon: Icons.calendar_month,
                                    color: Colors.teal,
                                    onTap: selectedTournamentId == null
                                        ? () => _showNoTournamentAlert(context)
                                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => FixtureListScreen(tournamentId: selectedTournamentId))),
                                ),
                                _DashboardCard(
                                  title: "Descargar",
                                  icon: Icons.cloud_sync,
                                  color: Colors.purple,
                                  onTap: () => _syncData(context, ref),
                                ),
                                _DashboardCard(
                                  title: "Subir a Nube",
                                  icon: Icons.upload_file,
                                  color: Colors.blueGrey,
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
        ],
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

    // Obtenemos el ID del torneo que el usuario tiene seleccionado actualmente
    final selectedTournamentId = ref.read(selectedTournamentIdProvider);
    final String syncId = selectedTournamentId ?? "0"; // Si es nulo, mandamos 0
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
      final catalogData = await api.fetchCatalogs(syncId);

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

// --- LÓGICA DE SUBIDA (CORREGIDA) ---
  Future<void> _uploadPendingData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final api = ref.read(apiServiceProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Iniciando subida de datos a la nube...")),
    );

    int uploadedTournaments = 0;
    int uploadedTeams = 0;
    int uploadedPlayers = 0;
    int uploadedMatches = 0;

    try {
      // ============================================
      // 1. SUBIR TORNEOS PENDIENTES
      // ============================================
      final pendingTournaments = await (db.select(db.tournaments)..where((tbl) => tbl.isSynced.equals(false))).get();

      for (var tourn in pendingTournaments) {
        try {
          // Subimos el torneo a PHP y recibimos el ID real de MySQL (ej. "15")
          final realIdString = await api.createTournament(tourn.name, tourn.category ?? 'Libre');
          final String oldUuid = tourn.id;

          await db.transaction(() async {
            // A. Borramos el torneo con el UUID viejo
            await (db.delete(db.tournaments)..where((t) => t.id.equals(oldUuid))).go();
            
            // B. Insertamos el torneo con el ID real
            await db.into(db.tournaments).insert(
              TournamentsCompanion.insert(
                id: drift.Value(realIdString),
                name: tourn.name,
                category: drift.Value(tourn.category),
                status: const drift.Value('ACTIVE'),
                isSynced: const drift.Value(true),
              ),
            );

            // C. CRÍTICO: Actualizar la referencia en los Equipos (Tabla pivote)
            await (db.update(db.tournamentTeams)..where((t) => t.tournamentId.equals(oldUuid)))
                .write(TournamentTeamsCompanion(tournamentId: drift.Value(realIdString)));

            // D. CRÍTICO: Actualizar la referencia en los Partidos/Fixtures
            await (db.update(db.fixtures)..where((f) => f.tournamentId.equals(oldUuid)))
                .write(FixturesCompanion(tournamentId: drift.Value(realIdString)));
                
            await (db.update(db.matches)..where((m) => m.tournamentId.equals(oldUuid)))
                .write(MatchesCompanion(tournamentId: drift.Value(realIdString)));
          });
          
          uploadedTournaments++;
        } catch (e) {
          debugPrint("Error subiendo torneo: $e");
        }
      }

      // ============================================
      // 2. SUBIR EQUIPOS PENDIENTES
      // ============================================
      final pendingTeams = await (db.select(db.teams)..where((tbl) => tbl.isSynced.equals(false))).get();

      for (var team in pendingTeams) {
        try {
          // Buscamos a qué torneo (ya con ID real) pertenece este equipo
          final relation = await (db.select(db.tournamentTeams)..where((t) => t.teamId.equals(team.id))).getSingleOrNull();

          // Subimos el equipo a PHP y recibimos el ID real de MySQL (ej. 50)
          final realIdInt = await api.createTeam(
            team.name,
            team.shortName ?? '',
            team.coachName ?? '',
            tournamentId: relation?.tournamentId, // Ahora esto es un número válido, no un UUID
          );
          
          final String oldTeamId = team.id;
          final String newTeamIdString = realIdInt.toString();

          await db.transaction(() async {
            // A. Actualizar la tabla pivote
            await (db.update(db.tournamentTeams)..where((t) => t.teamId.equals(oldTeamId)))
                .write(TournamentTeamsCompanion(teamId: drift.Value(newTeamIdString)));

            // B. Actualizar Jugadores que pertenecían a este equipo
            final tempTeamIdInt = int.tryParse(oldTeamId) ?? 0;
            await (db.update(db.players)..where((p) => p.teamId.equals(tempTeamIdInt)))
                .write(PlayersCompanion(teamId: drift.Value(realIdInt)));

            // C. Reemplazar el equipo en la tabla local
            await (db.delete(db.teams)..where((t) => t.id.equals(oldTeamId))).go();
            await db.into(db.teams).insert(
              TeamsCompanion.insert(
                id: drift.Value(newTeamIdString),
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

      // ============================================
      // 3. SUBIR JUGADORES PENDIENTES
      // ============================================
      final pendingPlayers = await (db.select(db.players)..where((tbl) => tbl.isSynced.equals(false))).get();

      for (var player in pendingPlayers) {
        try {
          // El player.teamId ahora ya es un ID real porque lo actualizamos en el paso 2
          final realPlayerId = await api.addPlayer(
            player.teamId,
            player.name,
            player.defaultNumber,
          );

          await db.transaction(() async {
            await (db.delete(db.players)..where((p) => p.id.equals(player.id))).go();
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

      // ============================================
      // 4. SUBIR PARTIDOS (MATCHES) PENDIENTES
      // ============================================
      final pendingMatches = await (db.select(db.matches)..where((tbl) => tbl.isSynced.equals(false))).get();

      for (var match in pendingMatches) {
        final query = db.select(db.gameEvents).join([
          drift.leftOuterJoin(
            db.matchRosters,
            db.matchRosters.matchId.equalsExp(db.gameEvents.matchId) & db.matchRosters.playerId.equalsExp(db.gameEvents.playerId),
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
          final currentScore = (roster?.teamSide == 'A') ? runningScoreA : runningScoreB;

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
          "tournament_id": match.tournamentId, // Ya es un ID real gracias al paso 1
          "venue_id": match.venueId,
          "team_a_id": match.teamAId, // Asumimos que los seleccionaste de la nube o fueron convertidos
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

        final successId = await api.syncMatchDataMultipart(
          matchData: matchPayload, 
          pdfBytes: null 
        );

        if (successId != -1) {
          await (db.update(db.matches)..where((tbl) => tbl.id.equals(match.id)))
              .write(const MatchesCompanion(isSynced: drift.Value(true)));
          uploadedMatches++;
        }
      }

      if (context.mounted) {
        ref.invalidate(tournamentsListProvider); // Refrescar UI global
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "☁️ Sincronización exitosa.\nTorneos: $uploadedTournaments | Equipos: $uploadedTeams | Jugadores: $uploadedPlayers | Partidos: $uploadedMatches",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error durante la subida: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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