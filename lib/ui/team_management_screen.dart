import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// Imports de tu proyecto
import '../logic/catalog_provider.dart';
import '../core/database/app_database.dart';
import 'team_detail_screen.dart';

// ALIAS IMPORTANTE PARA EVITAR CONFLICTOS
import '../core/di/dependency_injection.dart' as di;

class TeamManagementScreen extends ConsumerWidget {
  final String tournamentId;
  const TeamManagementScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el provider filtrado por torneo
    final catalogAsync = ref.watch(tournamentDataByIdProvider(tournamentId));

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo suave
      appBar: AppBar(
        title: const Text("Gestión de Equipos"),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeamDialog(context, ref),
        label: const Text("Nuevo Equipo"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              Text("Error: $err"),
            ],
          ),
        ),
        data: (data) {
          if (data.teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_3, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    "No hay equipos en este torneo.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                  padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(12),
                itemCount: data.teams.length,
                itemBuilder: (context, index) {
                  final team = data.teams[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _TeamCard(team: team),
                  );
                },
              );
            },
          );
        },
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
        title: const Text("Registrar Equipo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del Equipo",
                prefixIcon: Icon(Icons.shield),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: shortCtrl,
              decoration: const InputDecoration(
                labelText: "Abreviatura (Ej: CHI)",
                prefixIcon: Icon(Icons.short_text),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coachCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del Entrenador",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
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
                  await db.into(db.teams).insert(
                    TeamsCompanion.insert(
                      id: drift.Value(newTeamId.toString()),
                      name: nameCtrl.text,
                      shortName: drift.Value(shortCtrl.text),
                      coachName: drift.Value(coachCtrl.text),
                      isSynced: const drift.Value(true),
                    ),
                    mode: drift.InsertMode.insertOrReplace,
                  );

                  await db.into(db.tournamentTeams).insert(
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
                // Generar ID temporal local negativo
                final tempId = (-DateTime.now().millisecondsSinceEpoch).toString();

                await db.transaction(() async {
                  await db.into(db.teams).insert(
                    TeamsCompanion.insert(
                      id: drift.Value(tempId),
                      name: nameCtrl.text,
                      shortName: drift.Value(shortCtrl.text),
                      coachName: drift.Value(coachCtrl.text),
                      isSynced: const drift.Value(false), // Pendiente
                    ),
                  );
                  await db.into(db.tournamentTeams).insert(
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
                    content: Text("Sin conexión. Guardado localmente."),
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

// --- WIDGET TARJETA DE EQUIPO PROFESIONAL ---
class _TeamCard extends StatelessWidget {
  final dynamic team; // Usa el tipo 'Team' correcto de tu modelo si puedes importarlo
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    // Lógica para detectar si es local (ID negativo o no numérico)
    bool isLocal = false;
    try {
      final idInt = int.parse(team.id.toString());
      if (idInt < 0) isLocal = true;
    } catch (_) {
      isLocal = true; // Si es UUID o string raro, asumimos local
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDetailScreen(team: team),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar con iniciales
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isLocal ? Colors.orange.shade100 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    team.shortName.isNotEmpty ? team.shortName : team.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: isLocal ? Colors.orange.shade800 : Colors.blue.shade800,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.sports, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Coach: ${team.coachName.isNotEmpty ? team.coachName : 'Sin asignar'}",
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicador de Estado (Nube)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLocal)
                    const Tooltip(
                      message: "Pendiente de subir",
                      child: Icon(Icons.cloud_off, color: Colors.orange),
                    )
                  else
                    const Tooltip(
                      message: "Sincronizado",
                      child: Icon(Icons.check_circle, color: Colors.green),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}