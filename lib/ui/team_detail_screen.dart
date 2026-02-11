import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importamos tu modelo de negocio normalmente
import '../core/models/catalog_models.dart'; 
import '../logic/catalog_provider.dart';
import '../logic/tournament_provider.dart';
// Importamos la base de datos con un ALIAS para evitar conflicto de nombres
import '../core/database/app_database.dart' as db_app; 
import 'package:drift/drift.dart' as drift;

class TeamDetailScreen extends ConsumerWidget {
  final Team team;
  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Plantilla: ${team.name}")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlayerDialog(context, ref),
        label: const Text("Agregar Jugador"),
        icon: const Icon(Icons.person_add),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text("Error al cargar")),
        data: (data) {
          // Filtramos solo los jugadores de ESTE equipo
          final players = data.players.where((p) => p.teamId == team.id).toList();

          if (players.isEmpty) {
            return const Center(child: Text("Este equipo no tiene jugadores aún."));
          }

          return ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Text("#${player.defaultNumber}"),
                ),
                title: Text(player.name),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nuevo Jugador"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(
              controller: numberCtrl, 
              decoration: const InputDecoration(labelText: "Número (#)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);

              try {
                final newId = await ref.read(apiServiceProvider).addPlayer(
                  team.id,
                  nameCtrl.text,
                  int.tryParse(numberCtrl.text) ?? 0,
                );
                // Refrescar para ver el nuevo jugador
                final db = ref.read(databaseProvider);

                await db.into(db.players).insert(
                  db_app.PlayersCompanion.insert(
                    id: drift.Value(newId.toString()), // ID que viene de la API
                    teamId: team.id,
                    name: nameCtrl.text,
                    defaultNumber: drift.Value(int.tryParse(numberCtrl.text) ?? 0),
                    active: const drift.Value(true),
                  ),
                  mode: drift.InsertMode.insertOrReplace
                );

                // 3. Forzar refresco visual (Importante si usas catalogProvider normal)
                ref.invalidate(catalogProvider);

                if(!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Jugador agregado"), backgroundColor: Colors.green)
                );
              } catch (e) {

                if(!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                );
                
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }
}