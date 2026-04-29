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
    // Clonamos las listas iniciales
    _orderedRosterA = List.from(widget.rosterA);
    _orderedRosterB = List.from(widget.rosterB);
    _sortRosters();

    final currentStarters = ref.read(selectedStartersProvider(widget.matchId));
    final currentCaptains = ref.read(selectedCaptainsProvider(widget.matchId));

    _startersA = Set<int>.from(currentStarters['A'] ?? {});
    _startersB = Set<int>.from(currentStarters['B'] ?? {});
    _captainAId = currentCaptains['A'];
    _captainBId = currentCaptains['B'];
  }

  void _sortRosters() {
    _orderedRosterA.sort((a, b) => a.defaultNumber.compareTo(b.defaultNumber));
    _orderedRosterB.sort((a, b) => a.defaultNumber.compareTo(b.defaultNumber));
  }

  void _syncWithProvider() {
    ref.read(selectedStartersProvider(widget.matchId).notifier).state = {
      'A': Set<int>.from(_startersA),
      'B': Set<int>.from(_startersB),
    };
    
    ref.read(selectedCaptainsProvider(widget.matchId).notifier).state = {
      'A': _captainAId,
      'B': _captainBId,
    };
  }

  // FALLO 1: Descarga y sincronización automática si hay internet
  Future<void> _refreshRosters() async {
    final dbBase = ref.read(databaseProvider);
    final api = ref.read(apiServiceProvider);

    // Intentar subir pendientes a la nube si hay internet
    try {
      final pending = await (dbBase.select(dbBase.players)..where((p) => p.isSynced.equals(false))).get();
      for (var p in pending) {
        final realId = await api.addPlayer(p.teamId, p.name, p.defaultNumber);
        await dbBase.transaction(() async {
           // Actualizar localmente con ID real y marcar como sincronizado
           await (dbBase.update(dbBase.players)..where((tbl) => tbl.id.equals(p.id))).write(
             db.PlayersCompanion(id: drift.Value(realId.toString()), isSynced: const drift.Value(true))
           );
        });
      }
    } catch (e) {
      debugPrint("Sincronización en segundo plano falló (Modo Offline activo): $e");
    }

    // Recargar listas de la base de datos local
    final playersA = await (dbBase.select(dbBase.players)..where((p) => p.teamId.equals(widget.teamA.id))).get();
    final playersB = await (dbBase.select(dbBase.players)..where((p) => p.teamId.equals(widget.teamB.id))).get();

    setState(() {
      _orderedRosterA = playersA.map((p) => catalog.Player(
        id: int.tryParse(p.id) ?? -1,
        name: p.name,
        teamId: p.teamId,
        defaultNumber: p.defaultNumber,
      )).toList();
      
      _orderedRosterB = playersB.map((p) => catalog.Player(
        id: int.tryParse(p.id) ?? -1,
        name: p.name,
        teamId: p.teamId,
        defaultNumber: p.defaultNumber,
      )).toList();
      _sortRosters();
    });
  }

  void _showAddPlayerDialog(bool isTeamA) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final teamId = isTeamA ? widget.teamA.id : widget.teamB.id;
    final currentRoster = isTeamA ? _orderedRosterA : _orderedRosterB;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Nuevo Jugador - ${isTeamA ? 'Local' : 'Visita'}", 
                   style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle("Nombre Completo"),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: numberController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle("Número de Jersey"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              final name = nameController.text.trim().toUpperCase();
              final number = int.tryParse(numberController.text) ?? -1;

              if (name.isEmpty || number == -1) return;

              // FALLO 3: Validar que no se repita el número
              final exists = currentRoster.any((p) => p.defaultNumber == number);
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("El número $number ya está asignado en este equipo."))
                );
                return;
              }
              
              final dbBase = ref.read(databaseProvider);
              // Generamos un ID negativo temporal 100% numérico para evitar pantallas negras
              final tempId = (-DateTime.now().millisecondsSinceEpoch).toString();

              await dbBase.into(dbBase.players).insert(
                db.PlayersCompanion.insert(
                  id: drift.Value(tempId),
                  name: name,
                  teamId: teamId, 
                  defaultNumber: drift.Value(number),
                  isSynced: const drift.Value(false),
                )
              );

              await _refreshRosters();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.orangeAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: false, 
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF1A1F2B),
          title: const Text("Titulares", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.orangeAccent,
            indicatorWeight: 3,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: Colors.white38,
            tabs: [
              _buildTabItem(widget.teamA.name, true),
              _buildTabItem(widget.teamB.name, false),
            ],
          ),
        ),
        body: AppBackground(
          opacity: 0.4,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  // FALLO 2: Evitar selección múltiple involuntaria (física)
                  physics: const NeverScrollableScrollPhysics(), 
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
    );
  }

  Widget _buildTabItem(String name, bool isTeamA) {
    return Tab(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(name.toUpperCase(), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.person_add_alt_1, size: 18), onPressed: () => _showAddPlayerDialog(isTeamA)),
        ],
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
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedIds.remove(player.id);
                if (isCaptain) {
                  if (isTeamA) _captainAId = null; else _captainBId = null;
                }
              } else if (selectedIds.length < 5) {
                selectedIds.add(player.id);
              }
            });
            _syncWithProvider();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? themeColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isSelected ? themeColor : Colors.white10, 
                width: isSelected ? 2 : 1
              ),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Row(
              children: [
                // Icono de selección
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined, 
                  color: isSelected ? themeColor : Colors.white24,
                  size: 20,
                ),
                const SizedBox(width: 16),
                
                // CONTENEDOR DEL NÚMERO (Resaltado)
                Container(
                  width: 45,
                  alignment: Alignment.center,
                  child: Text(
                    player.defaultNumber.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : themeColor.withOpacity(0.8),
                      fontSize: 30, // Número grande
                      fontWeight: FontWeight.w900, // Peso máximo para resaltar
                      letterSpacing: -5,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // NOMBRE DEL JUGADOR
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name, 
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCaptain) 
                        Text(
                          "CAPITÁN", 
                          style: TextStyle(color: Colors.amber.shade300, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                        ),
                    ],
                  ),
                ),

                // Botón de Capitán
                if (isSelected) 
                  IconButton(
                    icon: Icon(
                      isCaptain ? Icons.star : Icons.star_border, 
                      color: isCaptain ? Colors.amber : Colors.white24
                    ),
                    onPressed: () {
                      setState(() { 
                        if (isTeamA) _captainAId = player.id; else _captainBId = player.id;
                      });
                      _syncWithProvider();
                    },
                  ),
              ],
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
              icon: _isCreating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.sports_basketball),
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
        fullRosterA: _orderedRosterA, // Usar las listas actualizadas
        fullRosterB: _orderedRosterB,
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
    for (var p in _orderedRosterA) {
      entries.add(db.MatchRostersCompanion.insert(matchId: widget.matchId, playerId: p.id.toString(), teamSide: 'A', jerseyNumber: p.defaultNumber, isCaptain: drift.Value(p.id == _captainAId)));
    }
    for (var p in _orderedRosterB) {
      entries.add(db.MatchRostersCompanion.insert(matchId: widget.matchId, playerId: p.id.toString(), teamSide: 'B', jerseyNumber: p.defaultNumber, isCaptain: drift.Value(p.id == _captainBId)));
    }
    await dao.addRosterToMatch(widget.matchId, entries);
  }
}