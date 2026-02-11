import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; // Alias para métodos de base de datos
import '../core/database/app_database.dart';
import '../logic/tournament_provider.dart';
import '../logic/catalog_provider.dart';
import 'match_setup_screen.dart';
import 'team_management_screen.dart';

class HomeMenuScreen extends ConsumerWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtener colores del tema
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    // 2. Escuchar el estado de los torneos y la selección actual
    final tournamentsAsync = ref.watch(tournamentsListProvider);
    final selectedTournamentId = ref.watch(selectedTournamentIdProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ============================================
          // HEADER: TÍTULO Y SELECTOR DE TORNEO
          // ============================================
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila del Título y Logo
                Row(
                  children: [
                    Icon(Icons.sports_basketball, size: 32, color: onPrimaryColor),
                    const SizedBox(width: 10),
                    Text(
                      "Basket Arbitraje",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Etiqueta "Torneo Activo"
                Text(
                  "Torneo Activo:",
                  style: TextStyle(color: onPrimaryColor.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 5),

                // Selector (Dropdown) de Torneos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: tournamentsAsync.when(
                    // Estado Cargando
                    loading: () => const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    ),
                    // Estado Error
                    error: (err, stack) => const Text(
                      "Error cargando torneos", 
                      style: TextStyle(color: Colors.white)
                    ),
                    // Estado Datos Listos
                    data: (tournaments) {
                      if (tournaments.isEmpty) {
                        return const Text(
                          "Sin torneos (Sincroniza primero)", 
                          style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)
                        );
                      }
                      
                      // Auto-selección: Si no hay torneo seleccionado, elige el primero automáticamente
                      if (selectedTournamentId == null && tournaments.isNotEmpty) {
                        Future.microtask(() => 
                          ref.read(selectedTournamentIdProvider.notifier).state = tournaments.first.id
                        );
                      }

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: primaryColor,
                          value: selectedTournamentId,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                          hint: const Text(
                            "Selecciona un Torneo", 
                            style: TextStyle(color: Colors.white70)
                          ),
                          items: tournaments.map((tournament) {
                            return DropdownMenuItem<String>(
                              value: tournament.id,
                              child: Text(
                                tournament.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              ref.read(selectedTournamentIdProvider.notifier).state = newId;
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ============================================
          // GRID: BOTONES DEL MENÚ PRINCIPAL
          // ============================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  // 1. Jugar Partido
                  _DashboardCard(
                    title: "Jugar Partido",
                    icon: Icons.play_circle_fill,
                    color: Colors.orange,
                    // Validación: Bloquear si no hay torneo seleccionado
                    onTap: selectedTournamentId == null 
                      ? () => _showNoTournamentAlert(context)
                      : () => Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => MatchSetupScreen(tournamentId: selectedTournamentId)
                          )
                          ),
                  ),
                  
                  // 2. Gestionar Equipos
                  _DashboardCard(
                    title: "Equipos",
                    icon: Icons.groups,
                    color: Colors.blue,
                    // Validación: Bloquear si no hay torneo seleccionado
                    onTap: selectedTournamentId == null 
                      ? () => _showNoTournamentAlert(context)
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementScreen())),
                  ),

                  // 3. Sincronizar Datos (Descargar de la Nube)
                  _DashboardCard(
                    title: "Sincronizar",
                    icon: Icons.cloud_sync,
                    color: Colors.purple,
                    onTap: () => _syncData(context, ref),
                  ),

                  // 4. Configuración
                  _DashboardCard(
                    title: "Configuración",
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Próximamente: Ajustes de la App")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE VALIDACIÓN ---
  void _showNoTournamentAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Debes seleccionar un torneo primero (o sincronizar)."),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- LÓGICA DE SINCRONIZACIÓN (Backend PHP -> Local SQLite) ---
  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    // A. Mostrar indicador de carga
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpiar previos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          SizedBox(width: 15),
          Text("Descargando datos del servidor..."),
        ]),
        duration: Duration(seconds: 25), // Duración larga (se cierra manualmente)
      ),
    );

    try {
      // B. Obtener servicios de los Providers
      final api = ref.read(apiServiceProvider);
      final db = ref.read(databaseProvider);

      // C. Petición al Backend (PHP) para traer JSON
      final catalogData = await api.fetchCatalogs();

      // D. Guardar en SQLite usando una Transacción (Atomicidad)
      await db.transaction(() async {
        
// 1. Insertar Torneos
        for (var t in catalogData.tournaments) {
          await db.into(db.tournaments).insert(
            TournamentsCompanion.insert(
              id: drift.Value(t.id.toString()),
              name: t.name,
              category: drift.Value(t.category),
              status: drift.Value(t.status ?? 'ACTIVE'),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }

        // 2. Insertar Equipos (DESCOMENTADO Y CORREGIDO)
        for (var team in catalogData.teams) {
          await db.into(db.teams).insert(
             TeamsCompanion.insert(
               id: drift.Value(team.id.toString()),
               name: team.name,
               shortName: drift.Value(team.shortName),
               coachName: drift.Value(team.coachName),
             ),
             mode: drift.InsertMode.insertOrReplace,
          );
        }

        // 3. Insertar Sedes / Canchas (AGREGADO)
        for (var venue in catalogData.venues) {
          await db.into(db.venues).insert(
             VenuesCompanion.insert(
               id: drift.Value(venue.id.toString()),
               name: venue.name,
               address: drift.Value(venue.address),
             ),
             mode: drift.InsertMode.insertOrReplace,
          );
        }
      });


// 4. Insertar Relaciones Torneo-Equipo
        await db.delete(db.tournamentTeams).go(); 
        
        for (var rel in catalogData.relationships) {
          await db.into(db.tournamentTeams).insert(
             TournamentTeamsCompanion.insert(
               // CORRECCIÓN: NO USAR drift.Value() AQUÍ
               tournamentId: rel.tournamentId.toString(), 
               teamId: rel.teamId.toString(),
             ),
             mode: drift.InsertMode.insertOrReplace,
          );
        }


        // 5. Insertar Jugadores (CORREGIDO)
        for (var p in catalogData.players) {
          await db.into(db.players).insert(
             PlayersCompanion.insert(
               id: drift.Value(p.id.toString()), // Drift usa String en BaseTable
               name: p.name, // Coincide con la columna nueva
               teamId: p.teamId, // Entero directo
               defaultNumber: drift.Value(p.defaultNumber),
               active: drift.Value(true), // Asumimos activos si vienen de la API
             ),
             mode: drift.InsertMode.insertOrReplace,
          );
        }
      // E. Forzar recarga de la lista de torneos en la UI
      ref.invalidate(tournamentsListProvider);

      // F. Mensaje de Éxito
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

      // G. Manejo de Errores (Red, Base de datos, etc.)
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error de Sincronización"),
            content: SingleChildScrollView(
              child: Text("No se pudo conectar con el servidor o guardar los datos.\n\nDetalle técnico:\n$e"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
            ],
          ),
        );
      }
    }
  }
}

// ============================================
// WIDGET AUXILIAR: TARJETA DE MENÚ (DASHBOARD)
// ============================================
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
        splashColor: color.withValues(alpha: 0.2), // Efecto visual al tocar
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05), // Fondo muy suave
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo con Icono
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              // Texto
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