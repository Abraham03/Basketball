// lib/ui/screens/match_setup_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart' as db;
import '../core/models/catalog_models.dart';
import '../logic/catalog_provider.dart';
import '../logic/tournament_provider.dart';
import 'starters_selection_screen.dart';

// IMPORTAMOS EL FONDO REUTILIZABLE
import '../ui/widgets/app_background.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final db.Fixture? preSelectedFixture; 

  const MatchSetupScreen({
    super.key,
    required this.tournamentId,
    this.preSelectedFixture,
  });

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  // Variables para guardar la selección del usuario
  Tournament? selectedTournament;
  Venue? selectedVenue;
  Team? selectedTeamA;
  Team? selectedTeamB;

  final TextEditingController _referee1Controller = TextEditingController();
  final TextEditingController _referee2Controller = TextEditingController();
  final TextEditingController _scorekeeperController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(tournamentDataByIdProvider(widget.tournamentId));
    final tournamentsListAsync = ref.watch(tournamentsListProvider);
    
    String currentTournamentName = "Cargando...";

    tournamentsListAsync.when(
      data: (list) {
        try {
          final t = list.firstWhere((element) => element.id == widget.tournamentId);
          currentTournamentName = t.name;
        } catch (_) {
          currentTournamentName = "Torneo Desconocido";
        }
      },
      loading: () => currentTournamentName = "...",
      error: (_, __) => currentTournamentName = "Error",
    );

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent, // Asegura que se vea el fondo
      
      appBar: AppBar(
        title: const Text("Configurar Partido", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.5), 
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      body: AppBackground(
        opacity: 0.6, // Un poco más oscuro para facilitar la lectura del formulario
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
          error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
          data: (catalogData) {
            
            // LÓGICA DE AUTO-SELECCIÓN DESDE FIXTURE
            if (widget.preSelectedFixture != null && selectedTeamA == null) {
              try {
                final fix = widget.preSelectedFixture!;
                
                selectedTeamA = catalogData.teams.cast<Team?>().firstWhere(
                  (t) => t!.id.toString() == fix.teamAId, orElse: () => null
                );
                
                selectedTeamB = catalogData.teams.cast<Team?>().firstWhere(
                  (t) => t!.id.toString() == fix.teamBId, orElse: () => null
                );

                if (fix.venueId != null) {
                  selectedVenue = catalogData.venues.cast<Venue?>().firstWhere(
                    (v) => v!.id.toString() == fix.venueId, orElse: () => null
                  );
                }
              } catch (e) {
                debugPrint("Error auto-seleccionando: $e");
              }
            }
            
            final bool isLocked = widget.preSelectedFixture != null;

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // --- TARJETA DE TORNEO Y SEDE ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Datos del Evento", Icons.event),
                            const SizedBox(height: 16),
                            
                            // 1. TORNEO (Solo lectura)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("TORNEO SELECCIONADO", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentTournamentName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. CANCHA / SEDE
                            _buildDropdown<Venue>(
                              label: "Cancha / Sede",
                              icon: Icons.location_on,
                              value: selectedVenue,
                              items: catalogData.venues,
                              isLocked: false, // Siempre permitimos cambiar la cancha por si hay cambios de última hora
                              onChanged: (val) => setState(() => selectedVenue = val),
                              displayText: (v) => v.name,
                            ),
                          ],
                        )
                      ),
                      const SizedBox(height: 20),

                      // --- TARJETA DE EQUIPOS ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Equipos a Enfrentarse", Icons.sports_basketball),
                            const SizedBox(height: 20),

                            // 3. EQUIPO A
                            _buildDropdown<Team>(
                              label: "Equipo Local (A)",
                              icon: Icons.shield,
                              value: selectedTeamA,
                              items: catalogData.teams,
                              isLocked: isLocked,
                              enabledItem: (t) => t != selectedTeamB,
                              onChanged: (val) => setState(() => selectedTeamA = val),
                              displayText: (t) => t.name,
                            ),
                            
                            // DIVISOR VS
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24)
                                  ),
                                  child: const Text("VS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),

                            // 4. EQUIPO B
                            _buildDropdown<Team>(
                              label: "Equipo Visitante (B)",
                              icon: Icons.shield_outlined,
                              value: selectedTeamB,
                              items: catalogData.teams,
                              isLocked: isLocked,
                              enabledItem: (t) => t != selectedTeamA,
                              onChanged: (val) => setState(() => selectedTeamB = val),
                              displayText: (t) => t.name,
                            ),
                          ],
                        )
                      ),
                      const SizedBox(height: 20),

                      // --- TARJETA DE OFICIALES ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Oficiales del Partido", Icons.sports),
                            const SizedBox(height: 16),
                            _buildTextField("Árbitro Principal", Icons.person, _referee1Controller),
                            const SizedBox(height: 16),
                            _buildTextField("Árbitro Auxiliar", Icons.person_outline, _referee2Controller),
                            const SizedBox(height: 16),
                            _buildTextField("Anotador (Mesa)", Icons.edit_note, _scorekeeperController),
                          ],
                        )
                      ),
                      const SizedBox(height: 30),

                      // --- BOTÓN CONTINUAR ---
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 28),
                          label: const Text("Seleccionar Jugadores", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _goToStarterSelection(catalogData, currentTournamentName);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 40), // Margen inferior extra
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES PARA EL DISEÑO GLASSMORPHISM
  // ===========================================================================

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent, width: 2)),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required bool isLocked,
    required Function(T?) onChanged,
    required String Function(T) displayText,
    bool Function(T)? enabledItem,
  }) {
    return IgnorePointer(
      ignoring: isLocked,
      child: DropdownButtonFormField<T>(
        value: value,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        dropdownColor: const Color(0xFF1A1F2B), // Color oscuro para que el menú no sea transparente
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isLocked ? Colors.white30 : Colors.white54),
          prefixIcon: Icon(icon, color: isLocked ? Colors.white30 : Colors.white54),
          filled: true,
          fillColor: isLocked ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent, width: 2)),
        ),
        icon: Icon(Icons.arrow_drop_down, color: isLocked ? Colors.transparent : Colors.white70),
        items: items.map((T item) {
          final isEnabled = enabledItem == null ? true : enabledItem(item);
          return DropdownMenuItem<T>(
            value: item,
            enabled: isEnabled,
            child: Text(
              displayText(item), 
              style: TextStyle(color: isEnabled ? Colors.white : Colors.white30)
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Requerido' : null,
      ),
    );
  }

  // ===========================================================================
  // NAVEGACIÓN
  // ===========================================================================

  void _goToStarterSelection(CatalogData data, String tournamentName) {
    if (selectedTeamA == null || selectedTeamB == null || selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona todos los campos", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    // CORRECCIÓN CRÍTICA DE ID
    // Si preSelectedFixture tiene un matchId (es decir, ya se había creado el match en la BD), lo usamos.
    // Si no, generamos un UUID o usamos un timestamp negativo para indicar que es un ID local temporal.
    String matchIdToUse;
    if (widget.preSelectedFixture != null && widget.preSelectedFixture!.matchId != null && widget.preSelectedFixture!.matchId!.isNotEmpty) {
       matchIdToUse = widget.preSelectedFixture!.matchId!;
    } else {
       // Usamos negativo para indicar a PHP que es nuevo si se llega a sincronizar
       matchIdToUse = (DateTime.now().millisecondsSinceEpoch).toString();
    }

    final rosterA = data.players.where((p) => p.teamId == selectedTeamA!.id).toList();
    final rosterB = data.players.where((p) => p.teamId == selectedTeamB!.id).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartersSelectionScreen(
          matchId: matchIdToUse, // PASAMOS EL ID CORREGIDO
          fixtureId: widget.preSelectedFixture?.id, // PASAMOS EL ID DEL FIXTURE PARA ACTUALIZAR SU ESTADO LUEGO
          teamA: selectedTeamA!,
          teamB: selectedTeamB!,
          rosterA: rosterA,
          rosterB: rosterB,
          tournamentId: int.parse(widget.tournamentId),
          venueId: selectedVenue!.id,
          mainReferee: _referee1Controller.text,
          auxReferee: _referee2Controller.text,
          scorekeeper: _scorekeeperController.text,
          tournamentName: tournamentName,
          venueName: selectedVenue!.name,
        ),
      ),
    );
  }
}