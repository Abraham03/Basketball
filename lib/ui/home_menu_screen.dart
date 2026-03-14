// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../core/database/app_database.dart';
import '../logic/tournament_provider.dart';
import '../logic/catalog_provider.dart';
import 'client_scoreboard_screen.dart';
import 'fixture_list_screen.dart';
import '../ui/match_setup_screen.dart';
import 'team_management_screen.dart';

import '../ui/widgets/glass_dashboard_card.dart';
import '../ui/widgets/app_background.dart';

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
            content: Row(
              children: [
                Icon(
                  _isAdminMode ? Icons.lock_open : Icons.lock,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  _isAdminMode
                      ? "Modo Administrador: ACTIVADO"
                      : "Modo Administrador: DESACTIVADO",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _isAdminMode
                ? Colors.green.shade800
                : Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });
  }

  Future<void> _createNewTournament(String name, String category) async {
    final api = ref.read(apiServiceProvider);
    final db = ref.read(databaseProvider);
    String finalId = "";

    try {
      finalId = await api.createTournament(name, category);
      await db
          .into(db.tournaments)
          .insert(
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("Torneo creado y sincronizado con la nube.")),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      finalId = const Uuid().v4();
      await db
          .into(db.tournaments)
          .insert(
            TournamentsCompanion.insert(
              id: drift.Value(finalId),
              name: name,
              category: drift.Value(category),
              status: const drift.Value('ACTIVE'),
              isSynced: const drift.Value(false),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.save_alt, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("Torneo guardado localmente (Sin conexión).")),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      ref.read(selectedTournamentIdProvider.notifier).state = finalId;
      ref.invalidate(tournamentsListProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "🏆 Nuevo Torneo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Nombre del Torneo",
                  hintText: "Ej: Liga Municipal 2026",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.emoji_events),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Este campo es requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: catCtrl,
                decoration: InputDecoration(
                  labelText: "Categoría",
                  hintText: "Ej: Libre Varonil",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Este campo es requerido" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _createNewTournament(nameCtrl.text, catCtrl.text);
              }
            },
            child: const Text(
              "Crear Torneo",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentsListProvider);
    final selectedTournamentId = ref.watch(selectedTournamentIdProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: _isAdminMode
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text("Nuevo Torneo"),
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            )
          : null,
      body: AppBackground(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWideScreen = constraints.maxWidth > 600;
                final int crossAxisCount = isWideScreen ? 4 : 2;
                final double contentWidth = isWideScreen
                    ? 800
                    : double.infinity;

                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _toggleAdminMode,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  color: Colors.transparent,
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.sports_basketball,
                                          size: 28,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      const Text(
                                        "Basket Pro",
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      if (_isAdminMode) ...[
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.admin_panel_settings,
                                          size: 20,
                                          color: Colors.orangeAccent,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Torneo Activo:",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),

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
                                  style: TextStyle(color: Colors.redAccent),
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
                                  if (selectedTournamentId == null &&
                                      tournaments.isNotEmpty) {
                                    Future.microtask(
                                      () =>
                                          ref
                                                  .read(
                                                    selectedTournamentIdProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              tournaments.first.id,
                                    );
                                  }
                                  final selectedName = tournaments
                                      .firstWhere(
                                        (t) => t.id == selectedTournamentId,
                                        orElse: () => tournaments.first,
                                      )
                                      .name;

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Material(
                                        color: Colors.white.withOpacity(0.15),
                                        child: InkWell(
                                          onTap: () => _showTournamentPicker(
                                            context,
                                            tournaments,
                                            ref,
                                            selectedTournamentId,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isWideScreen ? 1.3 : 1.05,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                GlassDashboardCard(
                                    title: "Calendario",
                                    icon: Icons.calendar_month,
                                    color: Colors.tealAccent,
                                    onTap: selectedTournamentId == null
                                        ? () => _showNoTournamentAlert(context)
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FixtureListScreen(
                                                tournamentId:
                                                    selectedTournamentId,
                                              ),
                                            ),
                                          ),
                                  ),
                                GlassDashboardCard(
                                  title: "Jugar Partido",
                                  icon: Icons.sports_basketball,
                                  color: Colors.orange,
                                  onTap: selectedTournamentId == null
                                      ? () => _showNoTournamentAlert(context)
                                      : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MatchSetupScreen(
                                              tournamentId:
                                                  selectedTournamentId,
                                            ),
                                          ),
                                        ),
                                ),
                                if (_isAdminMode) ...[
                                  GlassDashboardCard(
                                    title: "Pantalla Tablero",
                                    icon: Icons.tv,
                                    color: Colors.deepPurpleAccent,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ClientScoreboardScreen(),
                                      ),
                                    ),
                                  ),
                                  GlassDashboardCard(
                                    title: "Equipos",
                                    icon: Icons.groups,
                                    color: Colors.blueAccent,
                                    onTap: selectedTournamentId == null
                                        ? () => _showNoTournamentAlert(context)
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  TeamManagementScreen(
                                                    tournamentId:
                                                        selectedTournamentId,
                                                  ),
                                            ),
                                          ),
                                  ),
                                  GlassDashboardCard(
                                    title: "Descargar Datos",
                                    icon: Icons.cloud_download,
                                    color: Colors.purpleAccent,
                                    onTap: () => _syncData(context, ref),
                                  ),
                                  GlassDashboardCard(
                                    title: "Subir a Nube",
                                    icon: Icons.cloud_upload,
                                    color: Colors.greenAccent,
                                    onTap: () =>
                                        _uploadPendingData(context, ref),
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
            Positioned(
              bottom: 20,
              left: 20,
              child: GestureDetector(
                onTap: _toggleAdminMode,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
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
                                  .state =
                              t.id;
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Por favor, selecciona un torneo en la parte superior para continuar.",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    final selectedTournamentId = ref.read(selectedTournamentIdProvider);
    final String syncId = selectedTournamentId ?? "0";
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
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
            Text("Sincronizando datos... por favor espera.", style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 25),
      ),
    );

    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(databaseProvider);

      final catalogData = await api.fetchCatalogs(syncId);

      await db.transaction(() async {
        // --- LIMPIEZA ABSOLUTA DE FANTASMAS ---
        await db.delete(db.tournaments).go();
        await db.delete(db.teams).go();
        await db.delete(db.players).go();
        await db.delete(db.tournamentTeams).go();
        await db.delete(db.venues).go();
        await db.delete(db.fixtures).go();

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

        for (var m in catalogData.fixturesRaw) {
          DateTime? scheduledDate;
          if (m['scheduled_datetime'] != null &&
              m['scheduled_datetime'].toString().isNotEmpty) {
            scheduledDate = DateTime.tryParse(
              m['scheduled_datetime'].toString(),
            );
          }
          int? sA;
          int? sB;
          if (m['score_a'] != null) sA = int.tryParse(m['score_a'].toString());
          if (m['score_b'] != null) sB = int.tryParse(m['score_b'].toString());

          await db
              .into(db.fixtures)
              .insert(
                FixturesCompanion.insert(
                  id: m['id'].toString(),
                  tournamentId: m['tournament_id'].toString(),
                  roundName: m['round_name'] ?? 'Jornada',
                  teamAId: m['team_a_id'].toString(),
                  teamBId: m['team_b_id'].toString(),
                  teamAName: m['team_a'] ?? 'Equipo A',
                  teamBName: m['team_b'] ?? 'Equipo B',
                  logoA: drift.Value(m['logo_a']),
                  logoB: drift.Value(m['logo_b']),
                  venueId: drift.Value(m['venue_id']?.toString()),
                  venueName: drift.Value(m['venue_name']),
                  scheduledDatetime: drift.Value(scheduledDate),
                  matchId: drift.Value(m['match_id']?.toString()),
                  scoreA: drift.Value(sA),
                  scoreB: drift.Value(sB),
                  status: drift.Value(m['status'] ?? 'SCHEDULED'),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

        for (var team in catalogData.teams) {
          await db
              .into(db.teams)
              .insert(
                TeamsCompanion.insert(
                  id: drift.Value(team.id.toString()),
                  name: team.name,
                  shortName: drift.Value(team.shortName),
                  coachName: drift.Value(team.coachName),
                  logoUrl: drift.Value(team.logoUrl),
                  isSynced: const drift.Value(true),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

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

        for (var rel in catalogData.relationships) {
          await db
              .into(db.tournamentTeams)
              .insert(
                TournamentTeamsCompanion.insert(
                  tournamentId: rel.tournamentId.toString(),
                  teamId: rel.teamId.toString(),
                  isSynced: const drift.Value(true),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

        for (var p in catalogData.players) {
          await db
              .into(db.players)
              .insert(
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
      });

      ref.invalidate(tournamentsListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("Datos descargados y actualizados con éxito.", style: TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // --- MEJORA: DIÁLOGO DE ERROR PROFESIONAL ---
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("Sin conexión al servidor", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                  ),
                ),
              ],
            ),
            content: const Text(
              "No pudimos descargar los datos de la nube en este momento.\n\nPor favor, verifica tu conexión a internet o inténtalo más tarde. Tus datos locales están seguros y puedes seguir operando sin conexión.",
              style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Entendido", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _uploadPendingData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final api = ref.read(apiServiceProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 15),
            Text("Subiendo datos a la nube...", style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    int uploadedTournaments = 0;
    int uploadedTeams = 0;
    int uploadedPlayers = 0;
    int uploadedMatches = 0;
    int uploadedFixtures = 0;

    // Subir torneos
    try {
      final pendingTournaments = await (db.select(
        db.tournaments,
      )..where((tbl) => tbl.isSynced.equals(false))).get();
      for (var tourn in pendingTournaments) {
        try {
          final realIdString = await api.createTournament(
            tourn.name,
            tourn.category ?? 'Libre',
          );
          final String oldUuid = tourn.id;
          await db.transaction(() async {
            await db
                .into(db.tournaments)
                .insert(
                  TournamentsCompanion.insert(
                    id: drift.Value(realIdString),
                    name: tourn.name,
                    category: drift.Value(tourn.category),
                    status: const drift.Value('ACTIVE'),
                    isSynced: const drift.Value(true),
                  ),
                );
            await (db.update(
              db.tournamentTeams,
            )..where((t) => t.tournamentId.equals(oldUuid))).write(
              TournamentTeamsCompanion(tournamentId: drift.Value(realIdString)),
            );
            await (db.update(
              db.fixtures,
            )..where((f) => f.tournamentId.equals(oldUuid))).write(
              FixturesCompanion(tournamentId: drift.Value(realIdString)),
            );
            await (db.update(
              db.matches,
            )..where((m) => m.tournamentId.equals(oldUuid))).write(
              MatchesCompanion(tournamentId: drift.Value(realIdString)),
            );
            await (db.delete(
              db.tournaments,
            )..where((t) => t.id.equals(oldUuid))).go();
          });
          uploadedTournaments++;
        } catch (e) {
          debugPrint("Error subiendo torneo: $e");
        }
      }

      // Subir equipos
      final pendingTeams = await (db.select(
        db.teams,
      )..where((tbl) => tbl.isSynced.equals(false))).get();
      for (var team in pendingTeams) {
        try {
          final relation = await (db.select(
            db.tournamentTeams,
          )..where((t) => t.teamId.equals(team.id))).getSingleOrNull();
          final realIdInt = await api.createTeam(
            team.name,
            team.shortName ?? '',
            team.coachName ?? '',
            tournamentId: relation?.tournamentId,
          );
          final String oldTeamId = team.id;
          final String newTeamIdString = realIdInt.toString();

          await db.transaction(() async {
            await db
                .into(db.teams)
                .insert(
                  TeamsCompanion.insert(
                    id: drift.Value(newTeamIdString),
                    name: team.name,
                    shortName: drift.Value(team.shortName),
                    coachName: drift.Value(team.coachName),
                    isSynced: const drift.Value(true),
                  ),
                );
            await (db.update(
              db.tournamentTeams,
            )..where((t) => t.teamId.equals(oldTeamId))).write(
              TournamentTeamsCompanion(teamId: drift.Value(newTeamIdString)),
            );

            // Actualizar Fixtures Locales para que apunten al nuevo ID real del equipo
            await (db.update(db.fixtures)..where((f) => f.teamAId.equals(oldTeamId)))
                .write(FixturesCompanion(teamAId: drift.Value(newTeamIdString)));
            await (db.update(db.fixtures)..where((f) => f.teamBId.equals(oldTeamId)))
                .write(FixturesCompanion(teamBId: drift.Value(newTeamIdString)));

            final tempTeamIdInt = int.tryParse(oldTeamId) ?? 0;
            await (db.update(db.players)
                  ..where((p) => p.teamId.equals(tempTeamIdInt)))
                .write(PlayersCompanion(teamId: drift.Value(realIdInt)));
            await (db.delete(
              db.teams,
            )..where((t) => t.id.equals(oldTeamId))).go();
          });
          uploadedTeams++;
        } catch (e) {
          debugPrint("Error al subir equipo: $e");
        }
      }

      // Subir jugadores
      final pendingPlayers = await (db.select(
        db.players,
      )..where((tbl) => tbl.isSynced.equals(false))).get();
      for (var player in pendingPlayers) {
        try {
          final isExistingPlayer = (int.tryParse(player.id) ?? 0) > 0;
          if (isExistingPlayer) {
            final success = await api.updatePlayer(
              player.id,
              player.teamId,
              player.name,
              player.defaultNumber,
            );
            if (success) {
              await (db.update(db.players)
                    ..where((p) => p.id.equals(player.id)))
                  .write(const PlayersCompanion(isSynced: drift.Value(true)));
              uploadedPlayers++;
            }
          } else {
            final realPlayerId = await api.addPlayer(
              player.teamId,
              player.name,
              player.defaultNumber,
            );
            await db.transaction(() async {
              await db
                  .into(db.players)
                  .insert(
                    PlayersCompanion.insert(
                      id: drift.Value(realPlayerId.toString()),
                      teamId: player.teamId,
                      name: player.name,
                      defaultNumber: drift.Value(player.defaultNumber),
                      isSynced: const drift.Value(true),
                      active: const drift.Value(true),
                    ),
                  );
              await (db.update(
                db.gameEvents,
              )..where((e) => e.playerId.equals(player.id))).write(
                GameEventsCompanion(
                  playerId: drift.Value(realPlayerId.toString()),
                ),
              );
              await (db.delete(
                db.players,
              )..where((p) => p.id.equals(player.id))).go();
            });
            uploadedPlayers++;
          }
        } catch (e) {
          debugPrint("Error al subir jugador: $e");
        }
      }


      // --- 4. SUBIR FIXTURES PENDIENTES (INTELIGENTE) ---
      final pendingFixtures = await (db.select(
        db.fixtures,
      )..where((tbl) => tbl.isSynced.equals(false))).get();
      
      for (var fixture in pendingFixtures) {
        try {
          // Extraemos el número de jornada
          int roundOrder = 1;
          final matchRoundStr = RegExp(r'\d+').firstMatch(fixture.roundName);
          if (matchRoundStr != null) {
            roundOrder = int.parse(matchRoundStr.group(0)!);
          }

          // LÓGICA INTELIGENTE: ¿Es nuevo (UUID) o es editado (ID numérico)?
          int? numericId = int.tryParse(fixture.id);

          bool success = false;

          if (numericId != null) {
            // ES UN PARTIDO EXISTENTE QUE FUE EDITADO: Llamamos a UPDATE
            success = await api.updateFixtureTeams(
              fixtureId: numericId,
              newTeamAId: int.tryParse(fixture.teamAId) ?? 0,
              newTeamBId: int.tryParse(fixture.teamBId) ?? 0,
            );
          } else {
            // ES UN PARTIDO NUEVO CREADO OFFLINE: Llamamos a ADD
            success = await api.addManualFixture(
              tournamentId: fixture.tournamentId,
              roundOrder: roundOrder,
              teamAId: int.tryParse(fixture.teamAId) ?? 0,
              teamBId: int.tryParse(fixture.teamBId) ?? 0,
            );
          }

          if (success) {
            // Si subió bien, borramos la copia desincronizada local.
            // El `_syncData` final descargará la versión oficial.
            await (db.delete(db.fixtures)..where((f) => f.id.equals(fixture.id))).go();
            uploadedFixtures++;
          }
        } catch (e) {
          debugPrint("Error al subir fixture: $e");
        }
      }
      

      // SUBIR PARTIDOS PENDIENTES
      final pendingMatches = await (db.select(
        db.matches,
      )..where((tbl) => tbl.isSynced.equals(false))).get();
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
          String rawType = event.type;
          String teamSide = roster?.teamSide ?? 'A';
          if (rawType.endsWith('_A')) {
            teamSide = 'A';
            rawType = rawType.replaceAll('_A', '');
          } else if (rawType.endsWith('_B')) {
            teamSide = 'B';
            rawType = rawType.replaceAll('_B', '');
          }
          int points = 0;
          if (rawType == 'POINT_1' || rawType == 'FREE_THROW') points = 1;
          if (rawType == 'POINT_2') points = 2;
          if (rawType == 'POINT_3') points = 3;
          bool isTeamA = teamSide == 'A';
          if (points > 0) {
            if (isTeamA) {
              runningScoreA += points;
            } else {
              runningScoreB += points;
            }
          }
          final currentScore = isTeamA ? runningScoreA : runningScoreB;
          Map<String, dynamic> eventPayload = {
            "period": event.period,
            "team_side": teamSide,
            "player_name": player?.name ?? '',
            "player_number": roster?.jerseyNumber ?? 0,
            "points_scored": points,
            "score_after": currentScore,
            "type": rawType,
          };
          if (event.playerId != null &&
              event.playerId!.isNotEmpty &&
              event.playerId != '-1') {
            eventPayload["player_id"] = int.tryParse(event.playerId!);
          } else {
            eventPayload["player_id"] = null;
          }
          return eventPayload;
        }).toList();

        Uint8List? savedPdfBytes;
        if (match.matchReportPath != null &&
            match.matchReportPath!.isNotEmpty) {
          try {
            final file = File(match.matchReportPath!);
            if (await file.exists()) savedPdfBytes = await file.readAsBytes();
          } catch (e) {
            debugPrint("No se pudo leer el PDF local: $e");
          }
        }

        // 1. Justo antes de construir matchPayload, busca los rosters en la DB local
        final rosterRows = await (db.select(db.matchRosters)..where((r) => r.matchId.equals(match.id))).get();

        // 2. Mapea esos datos a una lista de JSON, calculando el campo "played"
        final rostersList = rosterRows.map((r) {
          final pIdInt = int.tryParse(r.playerId) ?? 0;
          
          // Como no tenemos el "state" de RAM aquí, verificamos si el jugador 
          // generó al menos 1 evento (punto o falta) en el partido guardado.
          bool hasPlayed = eventsList.any((event) => event["player_id"] == pIdInt);

          return {
            "player_id": pIdInt,
            "team_side": r.teamSide,
            "jersey_number": r.jerseyNumber,
            "is_captain": r.isCaptain ? 1 : 0,
            "played": hasPlayed ? 1 : 0 // <--- NUEVO CAMPO
          };
        }).toList();

        final fixtureRow = await (db.select(
          db.fixtures,
        )..where((f) => f.matchId.equals(match.id))).getSingleOrNull();
        final matchPayload = {
          "match_id": match.id,
          "fixture_id": fixtureRow?.id,
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
          "rosters": rostersList,
        };
        final success = await api.syncMatchDataMultipart(
          matchData: matchPayload,
          pdfBytes: savedPdfBytes,
        );
        if (success) {
          await (db.update(db.matches)..where((tbl) => tbl.id.equals(match.id)))
              .write(const MatchesCompanion(isSynced: drift.Value(true)));
          uploadedMatches++;
        }
      }

      // 6. Refrescar el estado de la UI y traer los datos más limpios de la BD
      if (uploadedFixtures > 0 || uploadedMatches > 0) {
        // ignore: use_build_context_synchronously
        await _syncData(context, ref); // Descargar la versión oficial de MySQL
      } else {
        ref.invalidate(tournamentsListProvider);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "☁️ Sincronización exitosa.\nSubidos: $uploadedTournaments Torneos, $uploadedTeams Equipos, $uploadedMatches Partidos, $uploadedPlayers Jugadores, $uploadedFixtures Calendarios.",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // --- MEJORA PROFESIONAL: Diálogo en vez de texto plano ---
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync_problem, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("Problema al Subir", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                  ),
                ),
              ],
            ),
            content: const Text(
              "Tuvimos un inconveniente al intentar respaldar tus datos en la nube.\n\nPor favor, revisa tu conexión a internet e inténtalo nuevamente. No te preocupes, toda tu información sigue guardada localmente de forma segura.",
              style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Entendido", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }
}
