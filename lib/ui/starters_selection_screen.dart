// lib/ui/screens/starters_selection_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../core/database/app_database.dart' as db;
import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart' as catalog;
import 'match_control_screen.dart';
import '../ui/widgets/app_background.dart';
import '../../logic/starters_persistence_provider.dart';

class StartersSelectionScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String? fixtureId;
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
  final String categoryName;
  final String tournamentLogoUrl;
  final String refereeLogoUrl;
  final String venueName;

  const StartersSelectionScreen({
    super.key,
    required this.matchId,
    this.fixtureId,
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
    required this.categoryName,
    required this.tournamentLogoUrl,
    required this.refereeLogoUrl,
    required this.venueName,
  });

  @override
  ConsumerState<StartersSelectionScreen> createState() =>
      _StartersSelectionScreenState();
}

class _StartersSelectionScreenState
    extends ConsumerState<StartersSelectionScreen> {
  
  late Set<int> _startersA;
  late Set<int> _startersB;
  int? _captainAId;
  int? _captainBId;
  
  bool _isCreating = false;
  late List<catalog.Player> _orderedRosterA;
  late List<catalog.Player> _orderedRosterB;

  @override
  void initState() {
    super.initState();
    _orderedRosterA = List.from(widget.rosterA);
    _orderedRosterB = List.from(widget.rosterB);
    _orderedRosterA.sort((a, b) => b.defaultNumber.compareTo(a.defaultNumber));
    _orderedRosterB.sort((a, b) => b.defaultNumber.compareTo(a.defaultNumber));

    final currentStarters = ref.read(selectedStartersProvider(widget.matchId));
    final currentCaptains = ref.read(selectedCaptainsProvider(widget.matchId));

    // Clonamos para que las variables locales no muten el provider sin pasar por _syncWithProvider
    _startersA = Set<int>.from(currentStarters['A'] ?? {});
    _startersB = Set<int>.from(currentStarters['B'] ?? {});
    _captainAId = currentCaptains['A'];
    _captainBId = currentCaptains['B'];
  }

  // CRITICO: Creamos objetos nuevos para que Riverpod detecte el cambio de estado
  void _syncWithProvider() {
    // Forzamos la creación de nuevos objetos de mapa y sets (nuevas referencias)
    ref.read(selectedStartersProvider(widget.matchId).notifier).state = {
      'A': Set<int>.from(_startersA),
      'B': Set<int>.from(_startersB),
    };
    
    ref.read(selectedCaptainsProvider(widget.matchId).notifier).state = {
      'A': _captainAId,
      'B': _captainBId,
    };
  }

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
                      _buildSelectionList(_orderedRosterA, _startersA, Colors.orangeAccent, true),
                      _buildSelectionList(_orderedRosterB, _startersB, Colors.lightBlueAccent, false),
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

  Widget _buildSelectionList(List<catalog.Player> roster, Set<int> selectedIds, Color themeColor, bool isTeamA) {
    if (roster.isEmpty) return const Center(child: Text("No hay jugadores", style: TextStyle(color: Colors.white54)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roster.length,
      itemBuilder: (context, index) {
        final player = roster[index];
        final isSelected = selectedIds.contains(player.id);
        final isCaptain = isTeamA ? _captainAId == player.id : _captainBId == player.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: isSelected ? themeColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedIds.remove(player.id);
                      if (isCaptain) {
                        if (isTeamA) {
                          _captainAId = null;
                        } else {
                          _captainBId = null;
                        }
                      }
                    } else if (selectedIds.length < 5) {
                      selectedIds.add(player.id);
                    }
                  });
                  _syncWithProvider(); // Guardar cambio en Riverpod
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: isSelected ? themeColor : Colors.white24, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? themeColor : Colors.white54),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            Text("Camiseta #${player.defaultNumber}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isSelected) IconButton(
                        icon: Icon(isCaptain ? Icons.star : Icons.star_border, color: isCaptain ? Colors.amber : Colors.white30),
                        onPressed: () {
                          setState(() { 
                            if (isTeamA) {
                              _captainAId = player.id;
                            } else {
                              _captainBId = player.id;
                            } 
                          });
                          _syncWithProvider(); // Guardar cambio de capitán
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControlPanel() {
    bool canProceed = _startersA.length == 5 && _startersB.length == 5 && _captainAId != null && _captainBId != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), border: const Border(top: BorderSide(color: Colors.white24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamStatusColumn(widget.teamA.shortName, _startersA.length, _captainAId != null),
              _buildTeamStatusColumn(widget.teamB.shortName, _startersB.length, _captainBId != null),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              icon: _isCreating ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.sports_basketball),
              label: Text(_isCreating ? "INICIANDO..." : "COMENZAR PARTIDO"),
              onPressed: (canProceed && !_isCreating) ? _startGame : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatusColumn(String name, int count, bool cap) {
    return Column(children: [
      Text(name.isEmpty ? "Equipo" : name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      Text("$count/5", style: TextStyle(color: count == 5 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      Text(cap ? "Capitán OK" : "Falta Capitán", style: TextStyle(color: cap ? Colors.greenAccent : Colors.redAccent, fontSize: 10)),
    ]);
  }

  Future<void> _startGame() async {
    setState(() => _isCreating = true);
    final matchDate = DateTime.now();
    try {
      final dbBase = ref.read(databaseProvider);
      final dao = ref.read(matchesDaoProvider);

      final existingMatch = await (dbBase.select(dbBase.matches)..where((t) => t.id.equals(widget.matchId))).getSingleOrNull();

      if (existingMatch == null) {
        await dbBase.into(dbBase.matches).insert(db.MatchesCompanion.insert(
          id: drift.Value(widget.matchId),
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
          matchDate: drift.Value(matchDate),
        ));
        await _saveRostersToDb(dao, dbBase);
      }

      if (widget.fixtureId != null) {
        await (dbBase.update(dbBase.fixtures)..where((t) => t.id.equals(widget.fixtureId!))).write(
          db.FixturesCompanion(status: const drift.Value('IN_PROGRESS'), matchId: drift.Value(widget.matchId))
        );
      }

      // Limpiar providers al iniciar el juego
      ref.invalidate(selectedStartersProvider(widget.matchId));
      ref.invalidate(selectedCaptainsProvider(widget.matchId));

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MatchControlScreen(
        matchId: widget.matchId,
        fixtureId: widget.fixtureId,
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
        categoryName: widget.categoryName,
        tournamentLogoUrl: widget.tournamentLogoUrl,
        refereeLogoUrl: widget.refereeLogoUrl,
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
      )));
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _saveRostersToDb(dynamic dao, db.AppDatabase dbBase) async {
    List<db.MatchRostersCompanion> entries = [];
    for (var p in widget.rosterA) {
      entries.add(db.MatchRostersCompanion.insert(matchId: widget.matchId, playerId: p.id.toString(), teamSide: 'A', jerseyNumber: p.defaultNumber, isCaptain: drift.Value(p.id == _captainAId)));
    }
    for (var p in widget.rosterB) {
      entries.add(db.MatchRostersCompanion.insert(matchId: widget.matchId, playerId: p.id.toString(), teamSide: 'B', jerseyNumber: p.defaultNumber, isCaptain: drift.Value(p.id == _captainBId)));
    }
    await dao.addRosterToMatch(widget.matchId, entries);
  }
}