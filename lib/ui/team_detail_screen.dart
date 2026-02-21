// lib/ui/screens/team_detail_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

// Modelos de negocio
import '../core/models/catalog_models.dart';

// Base de datos (con alias)
import '../core/database/app_database.dart' as db_app;

// Inyección de dependencias (con alias para evitar conflicto de nombres)
import '../core/di/dependency_injection.dart' as di;

// Importaciones de diseño
import '../ui/widgets/app_background.dart';


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
      extendBodyBehindAppBar: true, // IMPORTANTE PARA EL FONDO
      backgroundColor: Colors.transparent, // DEJAR VER EL FONDO
      
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4), // Cristalino
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          children: [
            Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "Plantilla de Jugadores",
              style: TextStyle(fontSize: 12, color: Colors.white70),
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
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlayerDialog(context, ref, teamIdInt),
        label: const Text("Nuevo Jugador"),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      // APLICAMOS EL APP BACKGROUND AQUÍ
      body: AppBackground(
        opacity: 0.5, // Un poco más oscuro para que resalten las tarjetas
        child: SafeArea(
          child: playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  Text("Error: $err", style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            data: (players) {
              if (players.isEmpty) {
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
                          Icons.sports_handball,
                          size: 60,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No hay jugadores registrados.",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Agrega jugadores usando el botón inferior.",
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
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
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return _buildDismissiblePlayer(
                          context,
                          ref,
                          player,
                          teamIdInt,
                        );
                      },
                    );
                  }

                  // Modo Móvil (Lista)
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildDismissiblePlayer(
                          context,
                          ref,
                          player,
                          teamIdInt,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDismissiblePlayer(
    BuildContext context,
    WidgetRef ref,
    db_app.Player player,
    int teamIdInt,
  ) {
    return Dismissible(
      key: Key(player.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("¿Eliminar jugador?"),
            content: Text("¿Estás seguro de eliminar a ${player.name}?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("No", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Sí, eliminar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final db = ref.read(di.databaseProvider);

        // 1. Borrar local
        await (db.delete(
          db.players,
        )..where((t) => t.id.equals(player.id))).go();

        // 2. Intentar borrar en nube (si es un ID real, es decir, mayor a 0)
        final playerIdInt = int.tryParse(player.id) ?? 0;
        if (playerIdInt > 0) {
          // Opcional: Implementa api.deletePlayer(player.id) en ApiService si tienes ese endpoint en PHP
        }
      },
      child: GestureDetector(
        onTap: () =>
            _showPlayerDialog(context, ref, teamIdInt, playerToEdit: player),
        child: _PlayerCard(player: player),
      ),
    );
  }

  void _showPlayerDialog(
    BuildContext context,
    WidgetRef ref,
    int teamIdInt, {
    db_app.Player? playerToEdit,
  }) {
    final isEditing = playerToEdit != null;
    final nameCtrl = TextEditingController(text: playerToEdit?.name ?? "");
    final numberCtrl = TextEditingController(
      text: playerToEdit?.defaultNumber.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? "✏️ Editar Jugador" : "👤 Registrar Jugador",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Nombre Completo",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: numberCtrl,
              decoration: InputDecoration(
                labelText: "Número (#)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.format_list_numbered),
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
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              // 1. VALIDACIÓN BÁSICA
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ El nombre es obligatorio")),
                );
                return;
              }

              final db = ref.read(di.databaseProvider);
              final api = ref.read(di.apiServiceProvider);
              final playerNum = int.tryParse(numberCtrl.text) ?? 0;

              // 2. VALIDACIÓN DE DUPLICADOS EN EL MISMO EQUIPO
              final currentPlayers =
                  ref.read(teamPlayersStreamProvider(teamIdInt)).value ?? [];

              final isDuplicate = currentPlayers.any(
                (p) => p.defaultNumber == playerNum && p.id != playerToEdit?.id,
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "⚠️ El número #$playerNum ya está ocupado en este equipo.",
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return; // IMPORTANTE: No cerramos el diálogo
              }

              try {
                if (isEditing) {
                  // --- LÓGICA DE EDICIÓN ---
                  final isRealId = (int.tryParse(playerToEdit.id) ?? 0) > 0;
                  bool syncSuccess = false;

                  if (isRealId) {
                    // MODIFICADO: AHORA ENVIAMOS EL teamIdInt TAMBIÉN
                    syncSuccess = await api.updatePlayer(
                      playerToEdit.id,
                      teamIdInt, 
                      nameCtrl.text,
                      playerNum,
                    );
                  }

                  await (db.update(
                    db.players,
                  )..where((t) => t.id.equals(playerToEdit.id))).write(
                    db_app.PlayersCompanion(
                      name: drift.Value(nameCtrl.text),
                      defaultNumber: drift.Value(playerNum),
                      isSynced: drift.Value(syncSuccess),
                    ),
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          syncSuccess
                              ? "✅ Jugador actualizado en la nube"
                              : "💾 Editado localmente (Pendiente de subir)",
                        ),
                        backgroundColor: syncSuccess ? Colors.green : Colors.orange,
                      ),
                    );
                  }
                } else {
                  // --- LÓGICA DE CREACIÓN ---
                  try {
                    // INTENTO ONLINE
                    final newId = await api.addPlayer(
                      teamIdInt,
                      nameCtrl.text,
                      playerNum,
                    );

                    await db
                        .into(db.players)
                        .insert(
                          db_app.PlayersCompanion.insert(
                            id: drift.Value(newId.toString()),
                            teamId: teamIdInt,
                            name: nameCtrl.text,
                            defaultNumber: drift.Value(playerNum),
                            active: const drift.Value(true),
                            isSynced: const drift.Value(true),
                          ),
                          mode: drift.InsertMode.insertOrReplace,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Jugador agregado"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // FALLO ONLINE (GUARDAR OFFLINE)
                    final tempId = (-DateTime.now().millisecondsSinceEpoch)
                        .toString();

                    await db
                        .into(db.players)
                        .insert(
                          db_app.PlayersCompanion.insert(
                            id: drift.Value(tempId),
                            teamId: teamIdInt,
                            name: nameCtrl.text,
                            defaultNumber: drift.Value(playerNum),
                            active: const drift.Value(true),
                            isSynced: const drift.Value(false), // Pendiente
                          ),
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("💾 Sin conexión. Guardado localmente."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }

                // 3. ÉXITO TOTAL: Cerramos el diálogo
                if (context.mounted) {
                  Navigator.pop(ctx);
                }
              } catch (e) {
                // Si hay un error crítico
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEditing ? "Actualizar" : "Guardar"),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TARJETA DE JUGADOR (Con Glassmorphism) ---
class _PlayerCard extends StatelessWidget {
  final db_app.Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    // Determinar si es local
    final isLocal = (int.tryParse(player.id) ?? 0) < 0 || !player.isSynced;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto cristal
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Fondo semitransparente
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Número de camiseta
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(
                    "#${player.defaultNumber}",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // Letra blanca para el fondo oscuro
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isLocal)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Pendiente de subir",
                          style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
                        ),
                      ),
                  ],
                ),
              ),

              // Icono de estado
              if (isLocal)
                const Tooltip(
                  message: "Guardado en dispositivo",
                  child: Icon(Icons.cloud_off, color: Colors.orangeAccent),
                )
              else
                const Tooltip(
                  message: "Sincronizado",
                  child: Icon(Icons.cloud_done, color: Colors.greenAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PROVIDER DEL STREAM ---
final teamPlayersStreamProvider =
    StreamProvider.family<List<db_app.Player>, int>((ref, teamId) {
      final db = ref.watch(di.databaseProvider);
      return (db.select(
        db.players,
      )..where((p) => p.teamId.equals(teamId))).watch();
    });