import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/catalog_provider.dart';
import 'team_detail_screen.dart';
import 'package:drift/drift.dart' as drift;
import '../core/database/app_database.dart';
import '../logic/tournament_provider.dart';

class TeamManagementScreen extends ConsumerWidget {
  final String tournamentId;
  const TeamManagementScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // provider filtrado por torneo
    final catalogAsync = ref.watch(tournamentDataByIdProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Equipos")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (data) {
          if (data.teams.isEmpty) {
            return const Center(child: Text("No hay equipos registrados."));
          }
          return ListView.builder(
            itemCount: data.teams.length,
            itemBuilder: (context, index) {
              final team = data.teams[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      team.shortName.isNotEmpty ? team.shortName : team.name[0],
                    ),
                  ),
                  title: Text(team.name),
                  subtitle: Text("Coach: ${team.coachName}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navegar al detalle para ver jugadores
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamDetailScreen(team: team),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final shortCtrl = TextEditingController();
    final coachCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nuevo Equipo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre Equipo"),
            ),
            TextField(
              controller: shortCtrl,
              decoration: const InputDecoration(
                labelText: "Abreviatura (Ej: CHI)",
              ),
            ),
            TextField(
              controller: coachCtrl,
              decoration: const InputDecoration(labelText: "Entrenador"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);

              final db = ref.read(databaseProvider);
              final api = ref.read(apiServiceProvider);

              try {
                // 1. INTENTO DE SUBIDA INMEDIATA
                final newTeamId = await api.createTeam(
                  nameCtrl.text,
                  shortCtrl.text,
                  coachCtrl.text,
                  tournamentId: tournamentId,
                );

                // 2. SI HAY ÉXITO: GUARDAR EN LOCAL COMO SINCRONIZADO (isSynced = true)
                await db.transaction(() async {
                  await db
                      .into(db.teams)
                      .insert(
                        TeamsCompanion.insert(
                          id: drift.Value(newTeamId.toString()),
                          name: nameCtrl.text,
                          shortName: drift.Value(shortCtrl.text),
                          coachName: drift.Value(coachCtrl.text),
                          isSynced: const drift.Value(true,
                          ), // YA ESTÁ EN LA NUBE
                        ),
                        mode: drift.InsertMode.insertOrReplace,
                      );
                  // ... insertar relación torneo ...
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
                    content: Text("Equipo creado y sincronizado"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // 3. SI FALLA (OFFLINE): GUARDAR EN LOCAL COMO PENDIENTE (isSynced = false)
                print("Modo Offline activado para Equipo: $e");

                // Generar ID temporal local
                final tempId = (-DateTime.now().millisecondsSinceEpoch).toString();

                await db.transaction(() async {
                  await db
                      .into(db.teams)
                      .insert(
                        TeamsCompanion.insert(
                          id: drift.Value(tempId), // ID TEMPORAL
                          name: nameCtrl.text,
                          shortName: drift.Value(shortCtrl.text),
                          coachName: drift.Value(coachCtrl.text),
                          isSynced: const drift.Value(
                            false,
                          ), // PENDIENTE DE SUBIR
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
                    content: Text("Sin conexión. Equipo guardado localmente."),
                    backgroundColor: Colors.orange,
                  ),
                );
              }

              // Recargar UI
              ref.invalidate(tournamentDataByIdProvider(tournamentId));
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
