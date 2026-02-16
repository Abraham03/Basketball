import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; // Alias para Drift

// Importamos la BD con alias para evitar conflictos
import '../core/database/app_database.dart' as db;
import '../core/di/dependency_injection.dart';

// Importamos los modelos de catálogo con alias
import '../core/models/catalog_models.dart' as catalog;

import 'match_control_screen.dart';
class StartersSelectionScreen extends ConsumerStatefulWidget {
  final String matchId;
  final catalog.Team teamA;
  final catalog.Team teamB;
  final List<catalog.Player> rosterA;
  final List<catalog.Player> rosterB;
  

  final int tournamentId;
  final int venueId;
  // Nota: teamAId y teamBId los sacamos de los objetos teamA y teamB
  
  // Datos extra para visualización
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;
  final String tournamentName;
  final String venueName;

  const StartersSelectionScreen({
    super.key,
    required this.matchId,
    required this.teamA,
    required this.teamB,
    required this.rosterA,
    required this.rosterB,
    // Recibimos los IDs
    required this.tournamentId,
    required this.venueId,
    
    required this.mainReferee,
    required this.auxReferee,
    required this.scorekeeper,
    required this.tournamentName,
    required this.venueName,
  });

  @override
  ConsumerState<StartersSelectionScreen> createState() => _StartersSelectionScreenState();
  }

class _StartersSelectionScreenState extends ConsumerState<StartersSelectionScreen> {
  // Los 5 jugadores seleccionados
  final Set<int> _startersA = {};
  final Set<int> _startersB = {};

  // Los capitanes
  int? _captainAId;
  int? _captainBId;
  bool _isCreating = false; // Para evitar doble clic

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Elegir 5 Titulares"),
          bottom: TabBar(
            tabs: [
              Tab(text: widget.teamA.name),
              Tab(text: widget.teamB.name),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSelectionList(widget.rosterA, _startersA, Colors.orange, true),
            _buildSelectionList(widget.rosterB, _startersB, Colors.blue, false),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Equipo A: ${_startersA.length}/5", 
                    style: TextStyle(color: _startersA.length == 5 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    if (_captainAId == null) 
                        const Text("Falta Capitán", style: TextStyle(color: Colors.red, fontSize: 12))
                      else
                        const Text("Capitán OK", style: TextStyle(color: Colors.green, fontSize: 12)),
                  Text("Equipo B: ${_startersB.length}/5",
                    style: TextStyle(color: _startersB.length == 5 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    if (_captainBId == null) 
                        const Text("Falta Capitán", style: TextStyle(color: Colors.red, fontSize: 12))
                      else
                        const Text("Capitán OK", style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (_canProceed() && !_isCreating) ? _startGame : null,
                  child: _isCreating 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("COMENZAR PARTIDO", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSelectionList(List<catalog.Player> roster, Set<int> selectedIds, Color color, bool isTeamA) {
    return ListView.builder(
      itemCount: roster.length,
      itemBuilder: (context, index) {
        final player = roster[index];
        final isSelected = selectedIds.contains(player.id);
        final isFull = selectedIds.length >= 5;
        
        // Verificar si es el capitán actual
        final isCaptain = isTeamA ? _captainAId == player.id : _captainBId == player.id;

        return CheckboxListTile(
          title: Row(
            children: [
              Expanded(child: Text(player.name)),
              if (isCaptain)
                const Chip(
                  label: Text("C", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.amber,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
            ],
          ),
          subtitle: Text("Camiseta #${player.defaultNumber}"),
          value: isSelected,
          activeColor: color,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                if (!isFull) selectedIds.add(player.id);
              } else {
                selectedIds.remove(player.id);
                // Si quitas al jugador, ya no puede ser capitán
                if (isCaptain) {
                  if (isTeamA) {
                    _captainAId = null;
                  } else {
                    _captainBId = null;
                  }
                }
              }
            });
          },
          secondary: IconButton(
            icon: Icon(
              isCaptain ? Icons.star : Icons.star_border,
              color: isCaptain ? Colors.amber : Colors.grey,
            ),
            tooltip: "Marcar como Capitán",
            onPressed: isSelected ? () {
              setState(() {
                if (isTeamA) {
                  _captainAId = player.id;
                } else {
                  _captainBId = player.id;
                }
              });
            } : null, // Solo habilitado si el jugador está seleccionado
          ),
        );
      },
    );
  }

  bool _canProceed() {
    return _startersA.length == 5 && _startersB.length == 5 && _captainAId != null && _captainBId != null;
  }

  Future <void> _startGame() async {
    setState(() => _isCreating = true);

    try {
      final dao = ref.read(matchesDaoProvider);

      // 1. Crear objeto Match
      final newMatch = db.MatchesCompanion.insert(
        id: drift.Value(widget.matchId.toString()),
        tournamentId: drift.Value(widget.tournamentId.toString()),
        venueId: drift.Value(widget.venueId.toString()),
        teamAName: widget.teamA.name,
        teamBName: widget.teamB.name,
        teamAId: drift.Value(widget.teamA.id),
        teamBId: drift.Value(widget.teamB.id),
        mainReferee: drift.Value(widget.mainReferee),
        auxReferee: drift.Value(widget.auxReferee),
        scorekeeper: drift.Value(widget.scorekeeper),
        status: const drift.Value('IN_PROGRESS'),
        isSynced: const drift.Value(false),
        scoreA: const drift.Value(0),
        scoreB: const drift.Value(0),
      );

      // 2. Insertar en BD Local
      await dao.createMatch(newMatch);

      // 3. (Opcional) Guardar Rosters en BD local
      // Esto ayuda si quieres persistir qué jugadores estuvieron en el partido
       await _saveRostersToDb(dao); 

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al iniciar: $e"), backgroundColor: Colors.red),
        );
      }
      setState(() => _isCreating = false);
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MatchControlScreen(
          matchId: widget.matchId,
          teamAName: widget.teamA.name,
          teamBName: widget.teamB.name,
          
          // --- AQUÍ PASAMOS LOS NUEVOS DATOS AL JUEGO ---
          tournamentId: widget.tournamentId,
          venueId: widget.venueId,
          teamAId: widget.teamA.id, // Obtenemos el ID del objeto Team
          teamBId: widget.teamB.id, // Obtenemos el ID del objeto Team
          
          mainReferee: widget.mainReferee,
          auxReferee: widget.auxReferee,
          scorekeeper: widget.scorekeeper,
          tournamentName: widget.tournamentName,
          venueName: widget.venueName,
          
          fullRosterA: widget.rosterA,
          fullRosterB: widget.rosterB,
          startersAIds: _startersA,
          startersBIds: _startersB,

          coachA: widget.teamA.coachName,
          coachB: widget.teamB.coachName,
          captainAId: _captainAId,
          captainBId: _captainBId,
        ),
      ),
    );
  }

Future<void> _saveRostersToDb(dynamic dao) async {
    List<db.MatchRostersCompanion> rosterEntries = [];

    // Procesar Equipo A
    for (var player in widget.rosterA) {
      rosterEntries.add(db.MatchRostersCompanion.insert(
        matchId: widget.matchId,
        playerId: player.id.toString(),
        teamSide: 'A',
        jerseyNumber: player.defaultNumber,
        // Guardar si es capitán
        isCaptain: drift.Value(player.id == _captainAId), 
        isSynced: const drift.Value(false),
      ));
    }

    // Procesar Equipo B
    for (var player in widget.rosterB) {
      rosterEntries.add(db.MatchRostersCompanion.insert(
        matchId: widget.matchId,
        playerId: player.id.toString(),
        teamSide: 'B',
        jerseyNumber: player.defaultNumber,
        // Guardar si es capitán
        isCaptain: drift.Value(player.id == _captainBId),
        isSynced: const drift.Value(false),
      ));
    }

    await dao.addRosterToMatch(widget.matchId, rosterEntries);
  }
}