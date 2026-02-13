import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/catalog_models.dart';
import '../logic/catalog_provider.dart';
import '../logic/tournament_provider.dart';
import 'starters_selection_screen.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const MatchSetupScreen({super.key, required this.tournamentId});

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
    // 1. Provider de datos del partido (Equipos filtrados)
  final catalogAsync = ref.watch(tournamentDataByIdProvider(widget.tournamentId));
    // 2. Provider de lista de torneos (Para buscar el nombre)
  final tournamentsListAsync = ref.watch(tournamentsListProvider);
  // 3. Lógica para obtener el nombre
    String currentTournamentName = "Cargando...";


   tournamentsListAsync.when(
      data: (list) {
        try {
          // Buscamos el torneo que coincida con el ID recibido
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Torneo Seleccionado:", 
                          style: TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                        Text(
                          currentTournamentName, // <--- Usamos la variable calculada arriba
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
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
                    height: 65,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _goToStarterSelection(catalogData,currentTournamentName);
                        }
                      },
                      child: const Text("Seleccionar Jugadores", style: TextStyle(fontSize: 20)),
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

  void _goToStarterSelection(CatalogData data, String tournamentName) {
    // Validación extra por seguridad
    if (selectedTeamA == null || selectedTeamB == null || selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona todos los campos")),
      );
      return;
    }
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