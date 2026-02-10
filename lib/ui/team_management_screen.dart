import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/catalog_provider.dart';
import 'team_detail_screen.dart'; // La crearemos en el siguiente paso

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el catálogo. Si cambia (ej: agregamos equipo), se actualiza sola.
    final catalogAsync = ref.watch(catalogProvider);

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
                    child: Text(team.shortName.isNotEmpty ? team.shortName : team.name[0]),
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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre Equipo")),
            TextField(controller: shortCtrl, decoration: const InputDecoration(labelText: "Abreviatura (Ej: CHI)")),
            TextField(controller: coachCtrl, decoration: const InputDecoration(labelText: "Entrenador")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx); // Cerrar diálogo
              
              try {
                // 1. Llamar a la API
                await ref.read(apiServiceProvider).createTeam(
                  nameCtrl.text, 
                  shortCtrl.text, 
                  coachCtrl.text,
                );
                // 2. Refrescar la lista de equipos
                ref.invalidate(catalogProvider);

                // Verificar si el contexto sigue vivo
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Equipo creado con éxito"))
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}