// lib/ui/screens/team_management_screen.dart
// ignore_for_file: deprecated_member_use

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
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent, 

      appBar: AppBar(
        title: const Text(
          "GESTIÓN DE EQUIPOS",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.6), 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTeamDialog(context, ref),
        label: const Text(
          "Nuevo Equipo",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // APLICAMOS EL FONDO REUTILIZABLE
      body: AppBackground(
        opacity: 0.8, 
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
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  "Error: $err",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
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
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Aún no hay equipos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Registra el primer equipo\nusando el botón inferior.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              );
            }

            // --- DISEÑO RESPONSIVO (LayoutBuilder) ---
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Si el ancho es mayor a 600px (Tablets/Web), usa Grid
                  if (constraints.maxWidth > 600) {
                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 100,
                        left: 20,
                        right: 20,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5, 
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
                      top: 20,
                      bottom: 100,
                      left: 16,
                      right: 16,
                    ), 
                    physics: const BouncingScrollPhysics(),
                    itemCount: data.teams.length,
                    itemBuilder: (context, index) {
                      final team = data.teams[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _TeamCard(team: team),
                      );
                    },
                  );
                },
              ),
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
        backgroundColor: const Color(0xFF1E2432),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text(
              "Registrar Equipo",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModernTextField(nameCtrl, "Nombre del Equipo", Icons.groups),
            const SizedBox(height: 16),
            _buildModernTextField(shortCtrl, "Abreviatura (Ej: LAL)", Icons.short_text),
            const SizedBox(height: 16),
            _buildModernTextField(coachCtrl, "Nombre del Entrenador", Icons.sports),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text(
              "Guardar",
              style: TextStyle(fontWeight: FontWeight.bold),
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
                final tempId = (-DateTime.now().millisecondsSinceEpoch).toString();

                await db.transaction(() async {
                  await db
                      .into(db.teams)
                      .insert(
                        TeamsCompanion.insert(
                          id: drift.Value(tempId),
                          name: nameCtrl.text,
                          shortName: drift.Value(shortCtrl.text),
                          coachName: drift.Value(coachCtrl.text),
                          isSynced: const drift.Value(false), 
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
          ),
        ],
      ),
    );
  }

  // --- Helper para inputs del diálogo ---
  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent)),
      ),
    );
  }
}

// =====================================================================
// TARJETA DE EQUIPO MODERNA Y PROFESIONAL
// =====================================================================
class _TeamCard extends StatelessWidget {
  final dynamic team;
  const _TeamCard({required this.team});

  // --- HELPER PARA RESOLVER LA RUTA DEL LOGO (Más robusto) ---
  String _resolveLogoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Limpiamos los "../" o "./" que PHP suele guardar en BD
    String cleanPath = path.replaceAll('../', '').replaceAll('./', '');
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    return 'https://basket.techsolutions.management/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    bool isLocal = false;
    try {
      final idInt = int.parse(team.id.toString());
      if (idInt < 0) isLocal = true;
    } catch (_) {
      isLocal = true;
    }

    // Extracción segura del logoUrl
    String? logoPath;
    try {
      logoPath = team.logoUrl;
    } catch (_) {
      logoPath = null;
    }

    final String resolvedUrl = _resolveLogoUrl(logoPath);
    final String initial = team.name.isNotEmpty ? team.name.substring(0, 1).toUpperCase() : '?';
    
    // Extracción segura de shortName
    String shortName = '';
    try {
      shortName = team.shortName?.isNotEmpty == true ? team.shortName : '';
    } catch (_) {
      shortName = '';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
        child: Material(
          color: Colors.transparent, 
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
              );
            },
            splashColor: Colors.orange.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.02)]
                ),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- LOGO DEL EQUIPO O INICIAL ---
                  Container(
                    width: 70, 
                    height: 70,
                    decoration: BoxDecoration(
                      color: isLocal ? Colors.orange.withOpacity(0.1) : Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLocal ? Colors.orangeAccent.withOpacity(0.5) : Colors.white38, 
                        width: 2
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: ClipOval(
                      child: resolvedUrl.isNotEmpty
                          ? Image.network(
                              resolvedUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildInitials(initial, isLocal),
                            )
                          : _buildInitials(initial, isLocal),
                    ),
                  ),
                  const SizedBox(width: 18),

                  // --- INFORMACIÓN DEL EQUIPO ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.white,
                                  letterSpacing: 0.5
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Etiqueta (Pill) para Abreviatura y Coach
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (shortName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withOpacity(0.2), 
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5))
                                ),
                                child: Text(
                                  shortName, 
                                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                                ),
                              ),
                            
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sports, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    team.coachName?.isNotEmpty == true ? team.coachName : 'Sin entrenador',
                                    style: TextStyle(
                                      fontSize: 13, 
                                      color: Colors.white.withOpacity(0.7), 
                                      fontWeight: FontWeight.w500
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // --- INDICADOR DE ESTADO (Nube o Flecha) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26, 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10)
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLocal ? Icons.cloud_off : Icons.cloud_done,
                          color: isLocal ? Colors.orangeAccent : Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(height: 6),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget de apoyo por si no hay imagen
  Widget _buildInitials(String initial, bool isLocal) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: isLocal ? Colors.orangeAccent : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 28, // Tamaño grande
        ),
      ),
    );
  }
}