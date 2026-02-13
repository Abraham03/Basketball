import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// Modelos de negocio
import '../core/models/catalog_models.dart';

// Base de datos (con alias)
import '../core/database/app_database.dart' as db_app;

// Inyección de dependencias (con alias para evitar conflicto de nombres)
import '../core/di/dependency_injection.dart' as di;

class TeamDetailScreen extends ConsumerWidget {
  final Team team;
  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Convertir ID del equipo a entero de forma segura
    final teamIdInt = int.tryParse(team.id.toString()) ?? 0;
    
    // Escuchar cambios en tiempo real de la base de datos local
    final playersAsync = ref.watch(teamPlayersStreamProvider(teamIdInt));
    final isTeamLocal = teamIdInt < 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "Plantilla de Jugadores", 
              style: TextStyle(fontSize: 12, color: Colors.grey[200])
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (isTeamLocal)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Tooltip(
                message: "Equipo local (no sincronizado)",
                child: Icon(Icons.cloud_off, color: Colors.orangeAccent),
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlayerDialog(context, ref, teamIdInt),
        label: const Text("Nuevo Jugador"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              Text("Error: $err"),
            ],
          ),
        ),
        data: (players) {
          if (players.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_handball, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No hay jugadores registrados.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text("Agrega jugadores usando el botón inferior."),
                ],
              ),
            );
          }

          // --- DISEÑO RESPONSIVO ---
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Modo Tablet/Web (Grid)
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 90, // Altura fija de la tarjeta
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: players.length,
                  itemBuilder: (context, index) => _PlayerCard(player: players[index]),
                );
              }

              // Modo Móvil (Lista)
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _PlayerCard(player: players[index]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref, int teamIdInt) {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Registrar Jugador"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre Completo",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberCtrl,
              decoration: const InputDecoration(
                labelText: "Número (#)",
                prefixIcon: Icon(Icons.format_list_numbered),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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

              // Usar alias 'di' para evitar conflictos
              final db = ref.read(di.databaseProvider);
              final api = ref.read(di.apiServiceProvider);
              final playerNum = int.tryParse(numberCtrl.text) ?? 0;

              try {
                // 1. INTENTO ONLINE
                final newId = await api.addPlayer(
                  teamIdInt, // Usar el ID entero ya parseado
                  nameCtrl.text,
                  playerNum,
                );

                // 2. ÉXITO (ONLINE)
                await db.into(db.players).insert(
                  db_app.PlayersCompanion.insert(
                    id: drift.Value(newId.toString()), 
                    teamId: teamIdInt,
                    name: nameCtrl.text,
                    defaultNumber: drift.Value(playerNum),
                    active: const drift.Value(true),
                    isSynced: const drift.Value(true),
                  ),
                  mode: drift.InsertMode.insertOrReplace
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Jugador agregado"), backgroundColor: Colors.green)
                );

              } catch (e) {
                // 3. FALLO (OFFLINE)
                
                final tempId = (-DateTime.now().millisecondsSinceEpoch).toString();

                await db.into(db.players).insert(
                  db_app.PlayersCompanion.insert(
                    id: drift.Value(tempId),
                    teamId: teamIdInt,
                    name: nameCtrl.text,
                    defaultNumber: drift.Value(playerNum),
                    active: const drift.Value(true),
                    isSynced: const drift.Value(false), // Pendiente
                  )
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sin conexión. Guardado localmente."), backgroundColor: Colors.orange)
                );
              }
              // El StreamProvider actualizará la lista automáticamente
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TARJETA DE JUGADOR ---
class _PlayerCard extends StatelessWidget {
  final db_app.Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    // Determinar si es local
    final isLocal = (int.tryParse(player.id) ?? 0) < 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            // Número de camiseta
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Center(
                child: Text(
                  "#${player.defaultNumber}",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Nombre y Estado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isLocal)
                    const Text(
                      "Pendiente de subir",
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                ],
              ),
            ),

            // Icono de estado
            if (isLocal)
              const Tooltip(
                message: "Guardado en dispositivo",
                child: Icon(Icons.cloud_off, color: Colors.orange),
              )
            else
              const Tooltip(
                message: "Sincronizado",
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}

// --- PROVIDER DEL STREAM ---
// Debe estar al final del archivo o en un archivo común
final teamPlayersStreamProvider = StreamProvider.family<List<db_app.Player>, int>((ref, teamId) {
  final db = ref.watch(di.databaseProvider); // Usamos el alias 'di'
  return (db.select(db.players)..where((p) => p.teamId.equals(teamId))).watch();
});