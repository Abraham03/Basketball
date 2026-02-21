// lib/ui/screens/team_management_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// Imports de tu proyecto
import '../logic/catalog_provider.dart';
import '../core/database/app_database.dart';
import 'team_detail_screen.dart';

// ALIAS IMPORTANTE PARA EVITAR CONFLICTOS
import '../core/di/dependency_injection.dart' as di;

// Importamos el fondo reutilizable
import '../ui/widgets/app_background.dart';

class TeamManagementScreen extends ConsumerWidget {
  final String tournamentId;
  const TeamManagementScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el provider filtrado por torneo
    final catalogAsync = ref.watch(tournamentDataByIdProvider(tournamentId));

    return Scaffold(
      extendBodyBehindAppBar: true, // IMPORTANTE PARA EL EFECTO CRISTAL
      backgroundColor: Colors.transparent, // DEJAR VER EL FONDO

      appBar: AppBar(
        title: const Text(
          "Gestión de Equipos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.4), // Appbar Cristalino
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeamDialog(context, ref),
        label: const Text(
          "Nuevo Equipo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),

      // APLICAMOS EL FONDO REUTILIZABLE
      body: AppBackground(
        opacity: 0.5, // Sombra para resaltar las tarjetas
        child: catalogAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  "Error: $err",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          data: (data) {
            if (data.teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_3,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No hay equipos en este torneo.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Agrega un equipo con el botón inferior.",
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              );
            }

            // --- DISEÑO RESPONSIVO (LayoutBuilder) ---
            return LayoutBuilder(
              builder: (context, constraints) {
                // Si el ancho es mayor a 600px (Tablets/Web), usa Grid
                if (constraints.maxWidth > 600) {
                  return GridView.builder(
                    padding: const EdgeInsets.only(
                      top: 100,
                      bottom: 100,
                      left: 16,
                      right: 16,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5, // Tarjetas más anchas que altas
                    ),
                    itemCount: data.teams.length,
                    itemBuilder: (context, index) {
                      final team = data.teams[index];
                      return _TeamCard(team: team);
                    },
                  );
                }

                // Si es Móvil, usa ListView
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 100,
                    bottom: 100,
                    left: 16,
                    right: 16,
                  ), // Padding por el AppBar y FAB
                  physics: const BouncingScrollPhysics(),
                  itemCount: data.teams.length,
                  itemBuilder: (context, index) {
                    final team = data.teams[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _TeamCard(team: team),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- Lógica del Diálogo de Agregar Equipo ---
  void _showAddTeamDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();
    final coachCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "🛡️ Registrar Equipo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Nombre del Equipo",
                prefixIcon: const Icon(Icons.shield),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shortCtrl,
              decoration: InputDecoration(
                labelText: "Abreviatura (Ej: CHI)",
                prefixIcon: const Icon(Icons.short_text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coachCtrl,
              decoration: InputDecoration(
                labelText: "Nombre del Entrenador",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);

              // USAMOS EL ALIAS 'di' PARA EVITAR CONFLICTOS
              final db = ref.read(di.databaseProvider);
              final api = ref.read(di.apiServiceProvider);

              try {
                // 1. INTENTO DE SUBIDA INMEDIATA
                final newTeamId = await api.createTeam(
                  nameCtrl.text,
                  shortCtrl.text,
                  coachCtrl.text,
                  tournamentId: tournamentId,
                );

                // 2. ÉXITO (ONLINE)
                await db.transaction(() async {
                  await db
                      .into(db.teams)
                      .insert(
                        TeamsCompanion.insert(
                          id: drift.Value(newTeamId.toString()),
                          name: nameCtrl.text,
                          shortName: drift.Value(shortCtrl.text),
                          coachName: drift.Value(coachCtrl.text),
                          isSynced: const drift.Value(true),
                        ),
                        mode: drift.InsertMode.insertOrReplace,
                      );

                  await db
                      .into(db.tournamentTeams)
                      .insert(
                        TournamentTeamsCompanion.insert(
                          tournamentId: tournamentId,
                          teamId: newTeamId.toString(),
                          isSynced: const drift.Value(true),
                        ),
                        mode: drift.InsertMode.insertOrReplace,
                      );
                });

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Equipo creado y sincronizado"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Generar ID temporal local negativo
                final tempId = (-DateTime.now().millisecondsSinceEpoch)
                    .toString();

                await db.transaction(() async {
                  await db
                      .into(db.teams)
                      .insert(
                        TeamsCompanion.insert(
                          id: drift.Value(tempId),
                          name: nameCtrl.text,
                          shortName: drift.Value(shortCtrl.text),
                          coachName: drift.Value(coachCtrl.text),
                          isSynced: const drift.Value(false), // Pendiente
                        ),
                      );
                  await db
                      .into(db.tournamentTeams)
                      .insert(
                        TournamentTeamsCompanion.insert(
                          tournamentId: tournamentId,
                          teamId: tempId,
                          isSynced: const drift.Value(false),
                        ),
                      );
                });

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("💾 Sin conexión. Guardado localmente."),
                    backgroundColor: Colors.orange,
                  ),
                );
              }

              // Recargar UI
              ref.invalidate(tournamentDataByIdProvider(tournamentId));
            },
            child: const Text(
              "Guardar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TARJETA DE EQUIPO (CON GLASSMORPHISM) ---
class _TeamCard extends StatelessWidget {
  final dynamic team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    // Lógica para detectar si es local (ID negativo o no numérico)
    bool isLocal = false;
    try {
      final idInt = int.parse(team.id.toString());
      if (idInt < 0) isLocal = true;
    } catch (_) {
      isLocal = true;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto cristal
        child: Material(
          color: Colors.white.withOpacity(0.1), // Fondo semitransparente oscuro
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
              );
            },
            splashColor: Colors.orange.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar con iniciales
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: isLocal
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLocal ? Colors.orangeAccent : Colors.white54,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        team.shortName.isNotEmpty
                            ? team.shortName
                            : team.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: isLocal ? Colors.orangeAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Letra clara
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.sports,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Coach: ${team.coachName.isNotEmpty ? team.coachName : 'Sin asignar'}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Indicador de Estado (Nube o Flecha)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLocal)
                        const Tooltip(
                          message: "Pendiente de subir",
                          child: Icon(
                            Icons.cloud_off,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                        )
                      else
                        const Tooltip(
                          message: "Sincronizado",
                          child: Icon(
                            Icons.cloud_done,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
