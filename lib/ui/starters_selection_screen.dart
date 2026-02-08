import 'package:flutter/material.dart';
import '../core/models/catalog_models.dart';
import 'match_control_screen.dart';

class StartersSelectionScreen extends StatefulWidget {
  final String matchId;
  final Team teamA;
  final Team teamB;
  final List<Player> rosterA;
  final List<Player> rosterB;
  
  // --- NUEVOS CAMPOS NECESARIOS ---
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
  State<StartersSelectionScreen> createState() => _StartersSelectionScreenState();
}

class _StartersSelectionScreenState extends State<StartersSelectionScreen> {
  final Set<int> _startersA = {};
  final Set<int> _startersB = {};

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
            _buildSelectionList(widget.rosterA, _startersA, Colors.orange),
            _buildSelectionList(widget.rosterB, _startersB, Colors.blue),
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
                  Text("Equipo B: ${_startersB.length}/5",
                    style: TextStyle(color: _startersB.length == 5 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
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
                  onPressed: _canProceed() ? _startGame : null,
                  child: const Text("COMENZAR PARTIDO", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionList(List<Player> roster, Set<int> selectedIds, Color color) {
    return ListView.builder(
      itemCount: roster.length,
      itemBuilder: (context, index) {
        final player = roster[index];
        final isSelected = selectedIds.contains(player.id);
        final isFull = selectedIds.length >= 5;

        return CheckboxListTile(
          title: Text(player.name),
          subtitle: Text("Camiseta #${player.defaultNumber}"),
          value: isSelected,
          activeColor: color,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                if (!isFull) selectedIds.add(player.id);
              } else {
                selectedIds.remove(player.id);
              }
            });
          },
          secondary: CircleAvatar(
            backgroundColor: isSelected ? color : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            child: Text("${player.defaultNumber}"),
          ),
        );
      },
    );
  }

  bool _canProceed() {
    return _startersA.length == 5 && _startersB.length == 5;
  }

  void _startGame() {
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
        ),
      ),
    );
  }
}