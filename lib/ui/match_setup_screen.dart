// lib/ui/screens/match_setup_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart' as db;
import '../core/models/catalog_models.dart' as model;
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
  model.Tournament? selectedTournament;
  model.Venue? selectedVenue;
  model.Team? selectedTeamA;
  model.Team? selectedTeamB;
  
  // Variables para los oficiales seleccionados
  model.Official? selectedMainReferee;
  model.Official? selectedAuxReferee;
  model.Official? selectedScorekeeper;

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
      backgroundColor: Colors.transparent,
      
      appBar: AppBar(
        title: const Text("Configurar Partido", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.5), 
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      body: AppBackground(
        opacity: 0.6,
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
          error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
          data: (catalogData) {
            
            // LÓGICA DE AUTO-SELECCIÓN DESDE FIXTURE
            if (widget.preSelectedFixture != null && selectedTeamA == null) {
              try {
                final fix = widget.preSelectedFixture!;
                
                // Se eliminaron los .cast<db.Team?>() que causaban errores de tipo.
                // Usamos where().isNotEmpty de forma segura.
                final matchA = catalogData.teams.where((t) => t.id.toString() == fix.teamAId.toString());
                if (matchA.isNotEmpty) selectedTeamA = matchA.first;

                final matchB = catalogData.teams.where((t) => t.id.toString() == fix.teamBId.toString());
                if (matchB.isNotEmpty) selectedTeamB = matchB.first;

                if (fix.venueId != null) {
                  final matchV = catalogData.venues.where((v) => v.id.toString() == fix.venueId.toString());
                  if (matchV.isNotEmpty) selectedVenue = matchV.first;
                }
              } catch (e) {
                debugPrint("Error auto-seleccionando: $e");
              }
            }
            
            final bool isLocked = widget.preSelectedFixture != null;

            // Filtrar oficiales por rol para los dropdowns
            final mainReferees = catalogData.officials.where((o) => o.role == 'ARBITRO_PRINCIPAL').toList();
            final auxReferees = catalogData.officials.where((o) => o.role == 'ARBITRO_AUXILIAR').toList();
            final scorekeepers = catalogData.officials.where((o) => o.role == 'ANOTADOR').toList();

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

                            _buildDropdown<model.Venue>(
                              label: "Cancha / Sede",
                              icon: Icons.location_on,
                              value: selectedVenue,
                              items: catalogData.venues,
                              isLocked: false,
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

                            _buildDropdown<model.Team>(
                              label: "Equipo Local (A)",
                              icon: Icons.shield,
                              value: selectedTeamA,
                              items: catalogData.teams,
                              isLocked: isLocked,
                              enabledItem: (t) => t != selectedTeamB,
                              onChanged: (val) => setState(() => selectedTeamA = val),
                              displayText: (t) => t.name,
                            ),
                            
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

                            _buildDropdown<model.Team>(
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

                      // --- TARJETA DE OFICIALES CON DROPDOWNS ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              "Oficiales del Partido", 
                              Icons.sports,
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 28),
                                onPressed: _showAddOfficialDialog,
                                tooltip: "Agregar nuevo oficial",
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (mainReferees.isEmpty && auxReferees.isEmpty && scorekeepers.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text("No hay oficiales descargados. Por favor, sincroniza los datos en el menú principal.", 
                                  style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontStyle: FontStyle.italic)),
                              ),

                            _buildDropdown<model.Official>(
                              label: "Árbitro Principal",
                              icon: Icons.person,
                              value: selectedMainReferee,
                              items: mainReferees,
                              isLocked: false,
                              isRequired: false,
                              onChanged: (val) => setState(() => selectedMainReferee = val),
                              displayText: (o) => o.name,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdown<model.Official>(
                              label: "Árbitro Auxiliar",
                              icon: Icons.person_outline,
                              value: selectedAuxReferee,
                              items: auxReferees,
                              isLocked: false,
                              isRequired: false,
                              onChanged: (val) => setState(() => selectedAuxReferee = val),
                              displayText: (o) => o.name,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDropdown<model.Official>(
                              label: "Anotador (Mesa)",
                              icon: Icons.edit_note,
                              value: selectedScorekeeper,
                              items: scorekeepers,
                              isLocked: false,
                              isRequired: false,
                              onChanged: (val) => setState(() => selectedScorekeeper = val),
                              displayText: (o) => o.name,
                            ),
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
                      const SizedBox(height: 40), 
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

  Widget _buildSectionTitle(String title, IconData icon, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
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
    bool isRequired = true,
  }) {
    return IgnorePointer(
      ignoring: isLocked,
      child: DropdownButtonFormField<T>(
        value: value,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        dropdownColor: const Color(0xFF1A1F2B), 
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
        validator: (val) {
          // Lógica condicional: Si es requerido y está vacío, marca error.
          if (isRequired && val == null) {
            return 'Requerido';
          }
          return null;
        },
      ),
    );
  }

  // ===========================================================================
  // NAVEGACIÓN
  // ===========================================================================



  void _goToStarterSelection(model.CatalogData data, String tournamentName) {
    if (selectedTeamA == null || selectedTeamB == null || selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona todos los campos obligatorios", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    String matchIdToUse;
    if (widget.preSelectedFixture != null && widget.preSelectedFixture!.matchId != null && widget.preSelectedFixture!.matchId!.isNotEmpty) {
       matchIdToUse = widget.preSelectedFixture!.matchId!;
    } else {
       matchIdToUse = (DateTime.now().millisecondsSinceEpoch).toString();
    }

    final rosterA = data.players.where((p) => p.teamId == selectedTeamA!.id).toList();
    final rosterB = data.players.where((p) => p.teamId == selectedTeamB!.id).toList();

    // Extraemos los nombres de los objetos seleccionados. Si son null, pasamos vacío.
    final String ref1Name = selectedMainReferee?.name ?? '';
    final String ref2Name = selectedAuxReferee?.name ?? '';
    final String scorekName = selectedScorekeeper?.name ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartersSelectionScreen(
          matchId: matchIdToUse, 
          fixtureId: widget.preSelectedFixture?.id,
          teamA: selectedTeamA!,
          teamB: selectedTeamB!,
          rosterA: rosterA,
          rosterB: rosterB,
          tournamentId: int.parse(widget.tournamentId),
          venueId: selectedVenue!.id,
          mainReferee: ref1Name, // Mandamos el nombre extraído
          auxReferee: ref2Name,
          scorekeeper: scorekName,
          tournamentName: tournamentName,
          venueName: selectedVenue!.name,
        ),
      ),
    );
  }

  void _showAddOfficialDialog() {
    final nameCtrl = TextEditingController();
    String selectedRole = 'ARBITRO_PRINCIPAL'; // Rol por defecto
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder para actualizar el Dropdown interno
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1, color: Colors.orange),
                SizedBox(width: 10),
                Text("Nuevo Oficial", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Nombre Completo",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Puesto / Rol",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ARBITRO_PRINCIPAL', child: Text('Árbitro Principal')),
                      DropdownMenuItem(value: 'ARBITRO_AUXILIAR', child: Text('Árbitro Auxiliar')),
                      DropdownMenuItem(value: 'ANOTADOR', child: Text('Anotador (Mesa)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final database = ref.read(databaseProvider);
                    final api = ref.read(apiServiceProvider);
                    
                    String officialId;
                    bool isSyncedStatus = false;

                    // 1. Intentar subirlo a la nube primero
                    try {
                      final realIdInt = await api.createOfficial(nameCtrl.text, selectedRole);
                      officialId = realIdInt.toString();
                      isSyncedStatus = true; // Se subió con éxito
                    } catch (e) {
                      // 2. Si falla (no hay internet), generamos ID temporal negativo
                      officialId = "-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
                      isSyncedStatus = false;
                      debugPrint("Guardado offline: $e");
                    }

                    // 3. Guardar en base de datos local (con ID real o temporal)
                    await database.into(database.officials).insert(
                      db.OfficialsCompanion.insert(
                        id: officialId, 
                        name: nameCtrl.text,
                        role: drift.Value(selectedRole),
                        active: const drift.Value(true),
                        isSynced: drift.Value(isSyncedStatus), 
                      ),
                      mode: drift.InsertMode.insertOrReplace,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      // Refrescamos la UI para que aparezca en el Dropdown
                      ref.invalidate(tournamentDataByIdProvider(widget.tournamentId));
                      
                      // Mostrar mensaje de éxito dependiendo de si subió a la nube o no
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(isSyncedStatus ? Icons.cloud_done : Icons.save_alt, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(isSyncedStatus 
                                  ? "Oficial guardado y sincronizado." 
                                  : "Guardado offline. Recuerda sincronizar luego."
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: isSyncedStatus ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Guardar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }
}