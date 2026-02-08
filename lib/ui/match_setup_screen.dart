import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/catalog_models.dart';
import '../logic/catalog_provider.dart';
// Importamos la pantalla de selección de titulares
import 'starters_selection_screen.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

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
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Configurar Partido")),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (catalogData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Datos del Evento"),
                  
                  // 1. TORNEO
                  DropdownButtonFormField<Tournament>(
                    decoration: const InputDecoration(labelText: "Torneo", border: OutlineInputBorder()),
                    initialValue: selectedTournament,
                    items: catalogData.tournaments.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.name));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedTournament = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. CANCHA / SEDE
                  DropdownButtonFormField<Venue>(
                    decoration: const InputDecoration(labelText: "Cancha / Sede", border: OutlineInputBorder()),
                    initialValue: selectedVenue,
                    items: catalogData.venues.map((v) {
                      return DropdownMenuItem(value: v, child: Text(v.name));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedVenue = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Equipos"),
                  
                  // 3. EQUIPO A
                  DropdownButtonFormField<Team>(
                    decoration: const InputDecoration(labelText: "Equipo Local (A)", border: OutlineInputBorder()),
                    initialValue: selectedTeamA,
                    items: catalogData.teams.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        enabled: t != selectedTeamB, 
                        child: Text(t.name), 
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedTeamA = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. EQUIPO B
                  DropdownButtonFormField<Team>(
                    decoration: const InputDecoration(labelText: "Equipo Visitante (B)", border: OutlineInputBorder()),
                    initialValue: selectedTeamB,
                    items: catalogData.teams.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        enabled: t != selectedTeamA,
                        child: Text(t.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedTeamB = val),
                    validator: (val) => val == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Oficiales"),
                  
                  TextFormField(
                    controller: _referee1Controller,
                    decoration: const InputDecoration(labelText: "Árbitro Principal", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _referee2Controller,
                    decoration: const InputDecoration(labelText: "Árbitro Auxiliar", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _scorekeeperController,
                    decoration: const InputDecoration(labelText: "Anotador", border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 30),

                  // BOTÓN CONTINUAR
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _goToStarterSelection(catalogData);
                        }
                      },
                      child: const Text("CONTINUAR A ROSTERS", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  void _goToStarterSelection(CatalogData data) {
    // 1. Generar ID del partido
    final matchId = DateTime.now().millisecondsSinceEpoch.toString();

    // 2. Filtrar las listas de jugadores para los equipos seleccionados
    final rosterA = data.players.where((p) => p.teamId == selectedTeamA!.id).toList();
    final rosterB = data.players.where((p) => p.teamId == selectedTeamB!.id).toList();

    // 3. Navegar a la pantalla de Selección de Titulares pasando TODOS los datos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartersSelectionScreen(
          matchId: matchId,
          teamA: selectedTeamA!,
          teamB: selectedTeamB!,
          rosterA: rosterA,
          rosterB: rosterB,
          tournamentId: selectedTournament!.id,
          venueId: selectedVenue!.id,
          mainReferee: _referee1Controller.text,
          auxReferee: _referee2Controller.text,
          scorekeeper: _scorekeeperController.text,
          tournamentName: selectedTournament!.name,
          venueName: selectedVenue!.name,
        ),
      ),
    );
  }
}