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
  model.Tournament? selectedTournament;
  model.Venue? selectedVenue;
  model.Team? selectedTeamA;
  model.Team? selectedTeamB;
  
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
        backgroundColor: Colors.black.withValues(alpha: 0.5), 
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
                
                selectedTeamA = catalogData.teams.where((t) => t.id.toString() == fix.teamAId.toString()).firstOrNull;
                selectedTeamB = catalogData.teams.where((t) => t.id.toString() == fix.teamBId.toString()).firstOrNull;

                if (fix.venueId != null) {
                  selectedVenue = catalogData.venues.where((v) => v.id.toString() == fix.venueId.toString()).firstOrNull;
                }
              } catch (e) {
                debugPrint("Error auto-seleccionando: $e");
              }
            }

            final bool isLocked = widget.preSelectedFixture != null;

            // Filtrar oficiales por rol
            final mainReferees = catalogData.officials.where((o) => o.role == 'ARBITRO_PRINCIPAL').toList();
            final auxReferees = catalogData.officials.where((o) => o.role == 'ARBITRO_AUXILIAR').toList();
            final scorekeepers = catalogData.officials.where((o) => o.role == 'ANOTADOR').toList();

            // CAPA DE SEGURIDAD ABSOLUTA PARA DROPDOWNS
            if (selectedTeamA != null) {
              selectedTeamA = catalogData.teams.where((t) => t.id == selectedTeamA!.id).firstOrNull;
            }
            if (selectedTeamB != null) {
              selectedTeamB = catalogData.teams.where((t) => t.id == selectedTeamB!.id).firstOrNull;
            }
            if (selectedVenue != null) {
              selectedVenue = catalogData.venues.where((v) => v.id == selectedVenue!.id).firstOrNull;
            }
            if (selectedMainReferee != null) {
              selectedMainReferee = mainReferees.where((o) => o.id == selectedMainReferee!.id).firstOrNull;
            }
            if (selectedAuxReferee != null) {
              selectedAuxReferee = auxReferees.where((o) => o.id == selectedAuxReferee!.id).firstOrNull;
            }
            if (selectedScorekeeper != null) {
              selectedScorekeeper = scorekeepers.where((o) => o.id == selectedScorekeeper!.id).firstOrNull;
            }

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
                            _buildSectionTitle(
                              "Datos del Evento", 
                              Icons.event,
                              trailing: IconButton(
                                icon: const Icon(Icons.add_location_alt, color: Colors.greenAccent, size: 26),
                                onPressed: _showAddVenueDialog,
                                tooltip: "Agregar Cancha",
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
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

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildBottomSheetSelector<model.Venue>(
                                    label: "Cancha",
                                    icon: Icons.location_on,
                                    value: selectedVenue,
                                    items: catalogData.venues,
                                    isLocked: false,
                                    onChanged: (val) => setState(() => selectedVenue = val),
                                    displayText: (v) => v.name,
                                  ),
                                ),
                                if (selectedVenue != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showEditVenueDialog(selectedVenue!),
                                  ),
                              ],
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

                            _buildBottomSheetSelector<model.Team>(
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

                            _buildBottomSheetSelector<model.Team>(
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
                                child: Text("No hay oficiales descargados. Por favor, sincroniza los datos o crea uno nuevo.", 
                                  style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontStyle: FontStyle.italic)),
                              ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildBottomSheetSelector<model.Official>(
                                    label: "Árbitro Principal",
                                    icon: Icons.person,
                                    value: selectedMainReferee,
                                    items: mainReferees,
                                    isLocked: false,
                                    isRequired: false,
                                    onChanged: (val) => setState(() => selectedMainReferee = val),
                                    displayText: (o) => o.name,
                                  ),
                                ),
                                if (selectedMainReferee != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showEditOfficialDialog(selectedMainReferee!),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildBottomSheetSelector<model.Official>(
                                    label: "Árbitro Auxiliar",
                                    icon: Icons.person_outline,
                                    value: selectedAuxReferee,
                                    items: auxReferees,
                                    isLocked: false,
                                    isRequired: false,
                                    onChanged: (val) => setState(() => selectedAuxReferee = val),
                                    displayText: (o) => o.name,
                                  ),
                                ),
                                if (selectedAuxReferee != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showEditOfficialDialog(selectedAuxReferee!),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildBottomSheetSelector<model.Official>(
                                    label: "Anotador (Mesa)",
                                    icon: Icons.edit_note,
                                    value: selectedScorekeeper,
                                    items: scorekeepers,
                                    isLocked: false,
                                    isRequired: false,
                                    onChanged: (val) => setState(() => selectedScorekeeper = val),
                                    displayText: (o) => o.name,
                                  ),
                                ),
                                if (selectedScorekeeper != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showEditOfficialDialog(selectedScorekeeper!),
                                  ),
                              ],
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
  // WIDGETS AUXILIARES PARA EL DISEÑO GLASSMORPHISM E INTERFAZ MODERNA
  // ===========================================================================

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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

  // --- NUEVO: SELECTOR TIPO MODAL BOTTOM SHEET ---
  Widget _buildBottomSheetSelector<T>({
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
    return FormField<T>(
      initialValue: value,
      validator: (val) {
        if (isRequired && value == null) return 'Requerido';
        return null;
      },
      builder: (FormFieldState<T> state) {
        final bool hasError = state.hasError;
        
        return InkWell(
          onTap: isLocked ? null : () {
            _showSelectorSheet<T>(
              title: label,
              items: items,
              currentValue: value,
              displayText: displayText,
              enabledItem: enabledItem,
              onSelect: (selected) {
                onChanged(selected);
                state.didChange(selected);
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: isLocked ? Colors.white30 : Colors.white54),
              prefixIcon: Icon(icon, color: isLocked ? Colors.white30 : Colors.white54),
              filled: true,
              fillColor: isLocked ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: hasError ? const BorderSide(color: Colors.redAccent, width: 1.5) : BorderSide.none
              ),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent, width: 2)),
              errorText: state.errorText,
            ),
            isEmpty: value == null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null ? displayText(value) : '',
                    style: TextStyle(
                      color: value != null 
                          ? (isLocked ? Colors.white54 : Colors.white) 
                          : Colors.white30,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: isLocked ? Colors.transparent : Colors.white70),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NUEVO: BOTTOM SHEET RENDERER ---
  void _showSelectorSheet<T>({
    required String title,
    required List<T> items,
    required T? currentValue,
    required String Function(T) displayText,
    required Function(T) onSelect,
    bool Function(T)? enabledItem,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2432).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        final isEnabled = enabledItem == null ? true : enabledItem(item);
                        final isSelected = item == currentValue;

                        return ListTile(
                          enabled: isEnabled,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          tileColor: isSelected ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.transparent,
                          title: Text(
                            displayText(item),
                            style: TextStyle(
                              color: isEnabled 
                                  ? (isSelected ? Colors.orangeAccent : Colors.white) 
                                  : Colors.white30,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.orangeAccent) 
                              : (isEnabled ? null : const Icon(Icons.block, color: Colors.white30, size: 18)),
                          onTap: isEnabled ? () {
                            onSelect(item);
                            Navigator.pop(ctx);
                          } : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // ===========================================================================
  // NAVEGACIÓN Y DIÁLOGOS
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
          mainReferee: ref1Name, 
          auxReferee: ref2Name,
          scorekeeper: scorekName,
          tournamentName: tournamentName,
          categoryName: selectedTournament?.category ?? 'LIBRE',
          venueName: selectedVenue!.name,
        ),
      ),
    );
  }

  // ===========================================================================
  // DIÁLOGOS DE SEDE (VENUE)
  // ===========================================================================
  
  void _showAddVenueDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_location_alt, color: Colors.orange),
            SizedBox(width: 10),
            Text("Nueva Sede", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  labelText: "Nombre de Cancha",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.stadium),
                ),
                validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: "Dirección (Opcional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.map),
                ),
                maxLines: 2,
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
                
                String venueId;
                bool isSyncedStatus = false;

                try {
                  final realIdInt = await api.createVenue(nameCtrl.text, addressCtrl.text);
                  venueId = realIdInt.toString();
                  isSyncedStatus = true; 
                } catch (e) {
                  venueId = "-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
                  isSyncedStatus = false;
                }

                await database.into(database.venues).insert(
                  db.VenuesCompanion.insert(
                    id: drift.Value(venueId),
                    name: nameCtrl.text,
                    address: drift.Value(addressCtrl.text),
                    isSynced: drift.Value(isSyncedStatus), 
                  ),
                  mode: drift.InsertMode.insertOrReplace,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ref.invalidate(tournamentDataByIdProvider(widget.tournamentId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSyncedStatus ? "Sede guardada en la nube." : "Sede guardada offline."),
                      backgroundColor: isSyncedStatus ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditVenueDialog(model.Venue venue) {
    final nameCtrl = TextEditingController(text: venue.name);
    final addressCtrl = TextEditingController(text: venue.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_location_alt, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text("Editar Sede", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  labelText: "Nombre de Cancha/Sede",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.stadium),
                ),
                validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: "Dirección (Opcional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.map),
                ),
                maxLines: 2,
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
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final database = ref.read(databaseProvider);
                final api = ref.read(apiServiceProvider);
                
                bool isSyncedStatus = false;
                int? numericId = int.tryParse(venue.id.toString());
                
                if (numericId != null && numericId > 0) {
                  try {
                    isSyncedStatus = await api.updateVenue(
                      id: venue.id.toString(),
                      name: nameCtrl.text,
                      address: addressCtrl.text
                    );
                  } catch (e) {
                    isSyncedStatus = false;
                  }
                }

                final updateStatement = database.update(database.venues)
                  ..where((v) => v.id.equals(venue.id.toString()));
                  
                await updateStatement.write(
                  db.VenuesCompanion(
                    name: drift.Value(nameCtrl.text),
                    address: drift.Value(addressCtrl.text),
                    isSynced: drift.Value(isSyncedStatus), 
                  ),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ref.invalidate(tournamentDataByIdProvider(widget.tournamentId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSyncedStatus ? "Sede actualizada en la nube." : "Actualizada offline."),
                      backgroundColor: isSyncedStatus ? Colors.blue.shade700 : Colors.orange.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text("Actualizar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIÁLOGOS DE OFICIALES
  // ===========================================================================

  void _showAddOfficialDialog() {
    final nameCtrl = TextEditingController();
    String selectedRole = 'ARBITRO_PRINCIPAL'; 
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
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

                    try {
                      final realIdInt = await api.createOfficial(nameCtrl.text, selectedRole);
                      officialId = realIdInt.toString();
                      isSyncedStatus = true; 
                    } catch (e) {
                      officialId = "-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
                      isSyncedStatus = false;
                      debugPrint("Guardado offline: $e");
                    }

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
                      ref.invalidate(tournamentDataByIdProvider(widget.tournamentId));
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

  void _showEditOfficialDialog(model.Official official) {
    final nameCtrl = TextEditingController(text: official.name);
    String selectedRole = official.role; 
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text("Editar Oficial", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final database = ref.read(databaseProvider);
                    final api = ref.read(apiServiceProvider);
                    
                    bool isSyncedStatus = false;
                    int? numericId = int.tryParse(official.id.toString());
                    
                    if (numericId != null && numericId > 0) {
                      try {
                        final success = await api.updateOfficial(
                          id: official.id.toString(),
                          name: nameCtrl.text,
                          role: selectedRole
                        );
                        isSyncedStatus = success; 
                      } catch (e) {
                        isSyncedStatus = false;
                        debugPrint("Actualizado offline: $e");
                      }
                    } else {
                      // Es un oficial creado offline (ID temporal)
                      isSyncedStatus = false;
                    }

                    final updateStatement = database.update(database.officials)
                      ..where((o) => o.id.equals(official.id.toString()));
                      
                    await updateStatement.write(
                      db.OfficialsCompanion(
                        name: drift.Value(nameCtrl.text),
                        role: drift.Value(selectedRole),
                        isSynced: drift.Value(isSyncedStatus), 
                      ),
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ref.invalidate(tournamentDataByIdProvider(widget.tournamentId));
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(isSyncedStatus ? Icons.cloud_done : Icons.save_alt, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(isSyncedStatus 
                                  ? "Oficial actualizado y sincronizado." 
                                  : "Actualizado offline. Se sincronizará luego."
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: isSyncedStatus ? Colors.blue.shade700 : Colors.orange.shade700,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Actualizar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }
}