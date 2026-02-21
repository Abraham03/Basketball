// lib/ui/screens/starters_selection_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; 

import '../core/database/app_database.dart' as db;
import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart' as catalog;
import 'match_control_screen.dart';

// --- IMPORTAMOS EL FONDO REUTILIZABLE ---
import '../ui/widgets/app_background.dart';

class StartersSelectionScreen extends ConsumerStatefulWidget {
  final String matchId;
  final catalog.Team teamA;
  final catalog.Team teamB;
  final List<catalog.Player> rosterA;
  final List<catalog.Player> rosterB;
  
  final int tournamentId;
  final int venueId;
  
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
  final Set<int> _startersA = {};
  final Set<int> _startersB = {};
  int? _captainAId;
  int? _captainBId;
  bool _isCreating = false; 

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true, 
        backgroundColor: Colors.transparent, 
        
        appBar: AppBar(
          title: const Text("Elegir 5 Titulares", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.orangeAccent,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: widget.teamA.name.toUpperCase()),
              Tab(text: widget.teamB.name.toUpperCase()),
            ],
          ),
        ),
        
        body: AppBackground(
          opacity: 0.6,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSelectionList(widget.rosterA, _startersA, Colors.orangeAccent, true),
                      _buildSelectionList(widget.rosterB, _startersB, Colors.lightBlueAccent, false),
                    ],
                  ),
                ),
                _buildBottomControlPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: LISTA DE JUGADORES (GLASSMORPHISM) ---
  Widget _buildSelectionList(List<catalog.Player> roster, Set<int> selectedIds, Color themeColor, bool isTeamA) {
    if (roster.isEmpty) {
      return Center(
        child: Text("No hay jugadores registrados en este equipo.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: roster.length,
      itemBuilder: (context, index) {
        final player = roster[index];
        final isSelected = selectedIds.contains(player.id);
        final isFull = selectedIds.length >= 5;
        final isCaptain = isTeamA ? _captainAId == player.id : _captainBId == player.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: isSelected ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedIds.remove(player.id);
                        if (isCaptain) {
                          if (isTeamA) _captainAId = null;
                          else _captainBId = null;
                        }
                      } else {
                        if (!isFull) selectedIds.add(player.id);
                        else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ya has seleccionado 5 titulares"), duration: Duration(seconds: 1)));
                      }
                    });
                  },
                  splashColor: themeColor.withOpacity(0.3),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? themeColor : Colors.white24, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // CHECKBOX CUSTOM
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? themeColor : Colors.white54,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        
                        // INFO JUGADOR
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      player.name, 
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70, 
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16
                                      ),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCaptain)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("CAPITÁN", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                                    )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("Camiseta #${player.defaultNumber}", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ),

                        // BOTÓN CAPITÁN
                        if (isSelected)
                          IconButton(
                            icon: Icon(isCaptain ? Icons.star : Icons.star_border, color: isCaptain ? Colors.amber : Colors.white30, size: 30),
                            tooltip: "Hacer Capitán",
                            onPressed: () {
                              setState(() {
                                if (isTeamA) _captainAId = player.id;
                                else _captainBId = player.id;
                              });
                            },
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET: PANEL INFERIOR (RESUMEN Y BOTÓN) ---
  Widget _buildBottomControlPanel() {
    bool canProceed = _canProceed();
    bool teamAOk = _startersA.length == 5 && _captainAId != null;
    bool teamBOk = _startersB.length == 5 && _captainBId != null;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: const Border(top: BorderSide(color: Colors.white24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTeamStatusColumn(widget.teamA.shortName.isNotEmpty ? widget.teamA.shortName : "Local", _startersA.length, _captainAId != null, teamAOk),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildTeamStatusColumn(widget.teamB.shortName.isNotEmpty ? widget.teamB.shortName : "Visitante", _startersB.length, _captainBId != null, teamBOk),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    disabledBackgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: canProceed ? 5 : 0,
                  ),
                  icon: _isCreating 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.sports_basketball),
                  label: Text(
                    _isCreating ? "INICIANDO..." : "COMENZAR PARTIDO", 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                  ),
                  onPressed: (canProceed && !_isCreating) ? _startGame : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamStatusColumn(String name, int selectedCount, bool hasCaptain, bool isReady) {
    return Column(
      children: [
        Text(name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(selectedCount == 5 ? Icons.check_circle : Icons.warning_amber, color: selectedCount == 5 ? Colors.greenAccent : Colors.orangeAccent, size: 16),
            const SizedBox(width: 4),
            Text("$selectedCount/5", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          hasCaptain ? "Capitán OK" : "Falta Capitán", 
          style: TextStyle(color: hasCaptain ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }

  bool _canProceed() {
    return _startersA.length == 5 && _startersB.length == 5 && _captainAId != null && _captainBId != null;
  }

  Future <void> _startGame() async {
    setState(() => _isCreating = true);
    final matchDate = DateTime.now();
    try {
      final dao = ref.read(matchesDaoProvider);

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
        matchDate: drift.Value(matchDate),
      );

      await dao.createMatch(newMatch);
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
          tournamentId: widget.tournamentId,
          venueId: widget.venueId,
          teamAId: widget.teamA.id, 
          teamBId: widget.teamB.id, 
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
          matchDate: matchDate,
        ),
      ),
    );
  }

  Future<void> _saveRostersToDb(dynamic dao) async {
    List<db.MatchRostersCompanion> rosterEntries = [];

    for (var player in widget.rosterA) {
      rosterEntries.add(db.MatchRostersCompanion.insert(
        matchId: widget.matchId,
        playerId: player.id.toString(),
        teamSide: 'A',
        jerseyNumber: player.defaultNumber,
        isCaptain: drift.Value(player.id == _captainAId), 
        isSynced: const drift.Value(false),
      ));
    }

    for (var player in widget.rosterB) {
      rosterEntries.add(db.MatchRostersCompanion.insert(
        matchId: widget.matchId,
        playerId: player.id.toString(),
        teamSide: 'B',
        jerseyNumber: player.defaultNumber,
        isCaptain: drift.Value(player.id == _captainBId),
        isSynced: const drift.Value(false),
      ));
    }

    await dao.addRosterToMatch(widget.matchId, rosterEntries);
  }
}