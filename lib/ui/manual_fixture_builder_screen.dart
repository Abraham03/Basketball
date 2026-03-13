import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../ui/widgets/app_background.dart';
import '../../core/di/dependency_injection.dart';
import '../core/database/app_database.dart';
import '../ui/widgets/tournament_rules_dialog.dart';

class ManualFixtureBuilderScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const ManualFixtureBuilderScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<ManualFixtureBuilderScreen> createState() =>
      _ManualFixtureBuilderScreenState();
}

class _ManualFixtureBuilderScreenState
    extends ConsumerState<ManualFixtureBuilderScreen> {
  int _selectedRoundId = 1;
  List<int> _availableRounds = [1];

  List<Map<String, dynamic>> _teamsStatus = [];
  List<Map<String, dynamic>> _createdMatchesForRound = [];
  
  Map<int, Set<int>> _playedMatchups = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadAvailableRounds();
    await _fetchTeamsStatus(); 
    await _loadCreatedMatchesLocally();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAvailableRounds() async {
    final db = ref.read(databaseProvider);
    
    final localFixtures = await (db.select(db.fixtures)
          ..where((f) => f.tournamentId.equals(widget.tournamentId)))
        .get();

    Set<int> roundsSet = {1, _selectedRoundId};

    for (var f in localFixtures) {
      final matchStr = RegExp(r'\d+').firstMatch(f.roundName);
      if (matchStr != null) {
        roundsSet.add(int.parse(matchStr.group(0)!));
      }
    }

    List<int> sortedRounds = roundsSet.toList()..sort();

    if (!sortedRounds.contains(_selectedRoundId)) {
      _selectedRoundId = sortedRounds.last;
    }

    setState(() {
      _availableRounds = sortedRounds;
    });
  }

  Future<void> _fetchTeamsStatus() async {
    try {
      final api = ref.read(apiServiceProvider);
      
      final statusData = await api.fetchTeamsSchedulingStatus(
          widget.tournamentId, _selectedRoundId);

      final fixtureData = await api.fetchFixture(widget.tournamentId);
      
      Map<int, Set<int>> matchups = {};

      if (fixtureData.isNotEmpty && fixtureData['rounds'] != null) {
        final roundsMap = fixtureData['rounds'] as Map<String, dynamic>;
        
        for (var entry in roundsMap.entries) {
          for (var match in (entry.value as List)) {
            if (match['status'] == 'CANCELLED') continue;

            final teamA = int.tryParse(match['team_a_id'].toString()) ?? 0;
            final teamB = int.tryParse(match['team_b_id'].toString()) ?? 0;
            
            if (teamA != 0 && teamB != 0) {
              matchups.putIfAbsent(teamA, () => {}).add(teamB);
              matchups.putIfAbsent(teamB, () => {}).add(teamA);
            }
          }
        }
      }

      if (mounted) {
        _teamsStatus = statusData;
        _playedMatchups = matchups;
      }
    } catch (e) {
      debugPrint("API falló. Usando BD Local. Error: $e");
      if (mounted) {
        await _loadTeamsStatusLocally();
      }
    }
  }

  Future<void> _loadTeamsStatusLocally() async {
    final db = ref.read(databaseProvider);

    final localTeams = await (db.select(db.teams).join([
      drift.innerJoin(db.tournamentTeams,
          db.tournamentTeams.teamId.equalsExp(db.teams.id))
    ])..where(db.tournamentTeams.tournamentId.equals(widget.tournamentId)))
        .get();

    final localFixtures = await (db.select(db.fixtures)
          ..where((f) =>
              f.tournamentId.equals(widget.tournamentId) &
              f.status.isNotIn(['CANCELLED'])))
        .get();

    List<Map<String, dynamic>> fallbackStatus = [];
    Map<int, Set<int>> matchups = {};

    for (var f in localFixtures) {
      final tA = int.tryParse(f.teamAId) ?? 0;
      final tB = int.tryParse(f.teamBId) ?? 0;
      
      if (tA != 0 && tB != 0) {
        matchups.putIfAbsent(tA, () => {}).add(tB);
        matchups.putIfAbsent(tB, () => {}).add(tA);
      }
    }

    for (var row in localTeams) {
      final team = row.readTable(db.teams);

      int totalScheduled = localFixtures
          .where((f) => f.teamAId == team.id || f.teamBId == team.id)
          .length;

      int scheduledThisRound = localFixtures
          .where((f) =>
              (f.teamAId == team.id || f.teamBId == team.id) &&
              f.roundName == "Jornada $_selectedRoundId")
          .length;

      fallbackStatus.add({
        "id": int.tryParse(team.id) ?? 0,
        "name": team.name,
        "logo_url": team.logoUrl,
        "total_scheduled": totalScheduled,
        "scheduled_this_round": scheduledThisRound,
      });
    }

    fallbackStatus.sort((a, b) {
      int roundCmp =
          (a['total_scheduled'] as int).compareTo(b['total_scheduled'] as int);
      if (roundCmp != 0) return roundCmp;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    _teamsStatus = fallbackStatus;
    _playedMatchups = matchups;
  }

  Future<void> _loadCreatedMatchesLocally() async {
    final db = ref.read(databaseProvider);
    final localFixtures = await (db.select(db.fixtures)
          ..where((f) =>
              f.tournamentId.equals(widget.tournamentId) &
              f.roundName.equals("Jornada $_selectedRoundId")))
        .get();

    _createdMatchesForRound = localFixtures.map((f) {
      return {
        'id': f.id,
        'teamAId': f.teamAId,
        'teamBId': f.teamBId,
        'teamAName': f.teamAName,
        'teamBName': f.teamBName,
        'logoA': f.logoA,
        'logoB': f.logoB,
      };
    }).toList();
  }

  void _addNewRound() {
    setState(() {
      int newRound =
          _availableRounds.isNotEmpty ? _availableRounds.last + 1 : 1;
      _availableRounds.add(newRound);
      _selectedRoundId = newRound; 
    });
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Jornada $_selectedRoundId lista para nuevos partidos.'),
          backgroundColor: Colors.green),
    );
  }

  Future<void> _showTournamentRulesDialog() async {
    final rules = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const TournamentRulesDialog(showVueltas: false),
    );

    if (rules != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final api = ref.read(apiServiceProvider);
        final success = await api.saveTournamentRules(
          tournamentId: widget.tournamentId,
          vueltas: rules['vueltas'] ?? 1,
          ptsVictoria: rules['win'],
          ptsDerrota: rules['loss'],
          ptsEmpate: rules['draw'],
          ptsForfeitWin: rules['forfeitWin'],
          ptsForfeitLoss: rules['forfeitLoss'],
        );

        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("✅ Reglas guardadas con éxito"),
                backgroundColor: Colors.green));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("❌ Falló al guardar las reglas"),
                backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("❌ Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // --- DIÁLOGO PARA CREAR PARTIDO ---
  void _showAddMatchDialog() {
    int? selectedTeamA;
    int? selectedTeamB;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 450, 
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2432).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Nuevo Partido",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 24),
                    _buildTeamSelectorCard(
                      title: "Equipo Local",
                      color: Colors.orangeAccent,
                      selectedValue: selectedTeamA,
                      otherSelectedValue: selectedTeamB,
                      originalTeamIdToIgnore: null,
                      onChanged: (val) => setModalState(() => selectedTeamA = val),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("VS", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    _buildTeamSelectorCard(
                      title: "Equipo Visitante",
                      color: Colors.lightBlueAccent,
                      selectedValue: selectedTeamB,
                      otherSelectedValue: selectedTeamA,
                      originalTeamIdToIgnore: null,
                      onChanged: (val) => setModalState(() => selectedTeamB = val),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (selectedTeamA != null && selectedTeamB != null && selectedTeamA != selectedTeamB)
                              ? () async {
                                  Navigator.pop(ctx);
                                  await _saveManualMatch(selectedTeamA!, selectedTeamB!);
                                }
                              : null,
                          child: const Text("Crear Partido", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- NUEVO: DIÁLOGO PARA EDITAR PARTIDO ---
  void _showEditMatchDialog(Map<String, dynamic> match) {
    int? selectedTeamA = int.tryParse(match['teamAId'].toString());
    int? selectedTeamB = int.tryParse(match['teamBId'].toString());
    final String fixtureId = match['id'].toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 450, 
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2432).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Editar Partido",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 24),
                    _buildTeamSelectorCard(
                      title: "Equipo Local",
                      color: Colors.orangeAccent,
                      selectedValue: selectedTeamA,
                      otherSelectedValue: selectedTeamB,
                      originalTeamIdToIgnore: int.tryParse(match['teamAId'].toString()), // Ignorar regla de "ya jugó" para el equipo original
                      onChanged: (val) => setModalState(() => selectedTeamA = val),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text("VS", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    _buildTeamSelectorCard(
                      title: "Equipo Visitante",
                      color: Colors.lightBlueAccent,
                      selectedValue: selectedTeamB,
                      otherSelectedValue: selectedTeamA,
                      originalTeamIdToIgnore: int.tryParse(match['teamBId'].toString()), // Ignorar regla de "ya jugó" para el equipo original
                      onChanged: (val) => setModalState(() => selectedTeamB = val),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (selectedTeamA != null && selectedTeamB != null && selectedTeamA != selectedTeamB)
                              ? () async {
                                  Navigator.pop(ctx);
                                  await _updateManualMatch(fixtureId, selectedTeamA!, selectedTeamB!);
                                }
                              : null,
                          child: const Text("Actualizar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSelectorCard({
    required String title,
    required Color color,
    required int? selectedValue,
    required int? otherSelectedValue,
    required int? originalTeamIdToIgnore, // Parámetro para saber qué equipo no bloquear al editar
    required Function(int?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF2C3444),
              isExpanded: true,
              hint: const Text("Seleccionar equipo...", style: TextStyle(color: Colors.white54)),
              value: selectedValue,
              icon: Icon(Icons.arrow_drop_down_circle, color: color),
              items: _teamsStatus.map((team) {
                final teamId = int.parse(team['id'].toString());
                
                // Si el equipo que estamos renderizando es el mismo que estaba originalmente en el partido, 
                // no lo bloqueamos porque el usuario podría querer dejarlo igual.
                bool isOriginalTeam = teamId == originalTeamIdToIgnore;

                bool alreadyPlayedRound = int.parse(team['scheduled_this_round'].toString()) > 0;
                bool isSameTeam = teamId == otherSelectedValue;
                bool alreadyPlayedAgainst = otherSelectedValue != null && 
                    (_playedMatchups[otherSelectedValue]?.contains(teamId) ?? false);

                // Se bloquea si cumple las reglas Y NO es el equipo original que ya estaba en ese lado
                bool isDisabled = (!isOriginalTeam && alreadyPlayedRound) || isSameTeam || (!isOriginalTeam && alreadyPlayedAgainst);

                return DropdownMenuItem<int>(
                  value: teamId,
                  enabled: !isDisabled,
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDisabled ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          team['name'],
                          style: TextStyle(
                            color: isDisabled ? Colors.white54 : Colors.white,
                            fontWeight: isDisabled ? FontWeight.normal : FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      if (isSameTeam)
                        const Text("EN USO", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold))
                      else if (!isOriginalTeam && alreadyPlayedAgainst)
                        const Text("YA ENFRENTADOS", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))
                      else if (!isOriginalTeam && alreadyPlayedRound)
                        const Text("JUGÓ EN JORNADA", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))
                      else if (isOriginalTeam)
                        const Text("EQUIPO ACTUAL", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold))
                      else
                        Text("JJ: ${team['total_scheduled']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveManualMatch(int teamA, int teamB) async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final api = ref.read(apiServiceProvider);

      final teamAData = _teamsStatus.firstWhere((t) => int.parse(t['id'].toString()) == teamA);
      final teamBData = _teamsStatus.firstWhere((t) => int.parse(t['id'].toString()) == teamB);

      final String tempFixtureId = const Uuid().v4();

      await db.into(db.fixtures).insert(
        FixturesCompanion.insert(
          id: tempFixtureId,
          tournamentId: widget.tournamentId,
          roundName: "Jornada $_selectedRoundId",
          teamAId: teamA.toString(),
          teamBId: teamB.toString(),
          teamAName: teamAData['name'],
          teamBName: teamBData['name'],
          logoA: drift.Value(teamAData['logo_url']),
          logoB: drift.Value(teamBData['logo_url']),
          status: const drift.Value('SCHEDULED'),
          isSynced: const drift.Value(false),
        ),
      );

      try {
        final success = await api.addManualFixture(
          tournamentId: widget.tournamentId,
          roundOrder: _selectedRoundId,
          teamAId: teamA,
          teamBId: teamB,
        );

        if (success) {
          final newFixtureData = await api.fetchFixture(widget.tournamentId);

          if (newFixtureData.isNotEmpty && newFixtureData['rounds'] != null) {
            await (db.delete(db.fixtures)
                  ..where((f) => f.tournamentId.equals(widget.tournamentId)))
                .go();

            final roundsMap = newFixtureData['rounds'] as Map<String, dynamic>;
            await db.transaction(() async {
              for (var entry in roundsMap.entries) {
                final roundName = entry.key;
                final matches = entry.value as List;
                for (var m in matches) {
                  await db.into(db.fixtures).insert(
                      FixturesCompanion.insert(
                        id: m['id'].toString(),
                        tournamentId: widget.tournamentId,
                        roundName: roundName,
                        teamAId: m['team_a_id'].toString(),
                        teamBId: m['team_b_id'].toString(),
                        teamAName: m['team_a'] ?? 'A',
                        teamBName: m['team_b'] ?? 'B',
                        logoA: drift.Value(m['logo_a']),
                        logoB: drift.Value(m['logo_b']),
                        status: drift.Value(m['status'] ?? 'SCHEDULED'),
                        isSynced: const drift.Value(true),
                      ),
                      mode: drift.InsertMode.insertOrReplace);
                }
              }
            });
          }
        }
      } catch (e) {
        debugPrint("Guardado local exitoso, pero falló subida a nube: $e");
      }

      await _loadData(); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Partido agregado"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- FUNCIÓN PARA ACTUALIZAR PARTIDO ---
  Future<void> _updateManualMatch(String fixtureId, int newTeamA, int newTeamB) async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final api = ref.read(apiServiceProvider);

      final teamAData = _teamsStatus.firstWhere((t) => int.parse(t['id'].toString()) == newTeamA);
      final teamBData = _teamsStatus.firstWhere((t) => int.parse(t['id'].toString()) == newTeamB);

      // 1. Actualizamos localmente (Drift) siempre
      await (db.update(db.fixtures)..where((f) => f.id.equals(fixtureId))).write(
        FixturesCompanion(
          teamAId: drift.Value(newTeamA.toString()),
          teamBId: drift.Value(newTeamB.toString()),
          teamAName: drift.Value(teamAData['name']),
          teamBName: drift.Value(teamBData['name']),
          logoA: drift.Value(teamAData['logo_url']),
          logoB: drift.Value(teamBData['logo_url']),
          isSynced: const drift.Value(false), // Marcamos como no sincronizado por defecto
        )
      );

      // 2. Intentamos subir a la nube SOLO si el partido ya existía en el servidor (ID numérico)
      // Si es un UUID (creado offline), dejamos que HomeMenuScreen lo suba después como "nuevo".
      int? numericId = int.tryParse(fixtureId);
      
      if (numericId != null) {
        try {
          final success = await api.updateFixtureTeams(
            fixtureId: numericId,
            newTeamAId: newTeamA,
            newTeamBId: newTeamB,
          );

          if (success) {
            // Si se subió con éxito, lo marcamos como sincronizado
            await (db.update(db.fixtures)..where((f) => f.id.equals(fixtureId))).write(
              const FixturesCompanion(isSynced: drift.Value(true))
            );
          }
        } catch (e) {
          debugPrint("Actualización local exitosa, pero falló nube: $e");
        }
      }

      await _loadData(); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🔄 Partido actualizado"), backgroundColor: Colors.blueAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error actualizando: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Constructor Manual",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "Reglas de Torneo (Puntos)",
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: _showTournamentRulesDialog,
          ),
          IconButton(
            tooltip: "Crear Nueva Jornada",
            icon: const Icon(Icons.add_to_photos, color: Colors.greenAccent),
            onPressed: _addNewRound,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMatchDialog,
        icon: const Icon(Icons.add),
        label: const Text("Partido", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
      body: AppBackground(
        opacity: 0.8,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000), 
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.black54, Colors.black87],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  )
                                ]
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("PROGRAMACIÓN", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                                      SizedBox(height: 4),
                                      Text("Selecciona Jornada", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        dropdownColor: const Color(0xFF2C3444),
                                        value: _selectedRoundId,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orangeAccent),
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.w900),
                                        items: _availableRounds.map((rId) {
                                          return DropdownMenuItem<int>(
                                            value: rId,
                                            child: Text("Jornada $rId"),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null && val != _selectedRoundId) {
                                            setState(() => _selectedRoundId = val);
                                            _loadData();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Expanded(
                              child: _createdMatchesForRound.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                                        const SizedBox(height: 20),
                                        Text("No hay partidos en la Jornada $_selectedRoundId", style: const TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 10),
                                        const Text("Presiona 'Agregar Partido' para comenzar.", style: TextStyle(color: Colors.white38, fontSize: 14)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), 
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _createdMatchesForRound.length,
                                    itemBuilder: (context, index) {
                                      final match = _createdMatchesForRound[index];
                                      return Card(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        elevation: 0,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1))
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // NUEVO: Botón para editar
                                              IconButton(
                                                icon: const Icon(Icons.edit_calendar, color: Colors.white54),
                                                onPressed: () => _showEditMatchDialog(match),
                                                tooltip: "Editar Equipos",
                                              ),
                                              Expanded(
                                                child: Text(
                                                  match['teamAName'],
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orangeAccent.withValues(alpha: 0.2),
                                                    shape: BoxShape.circle
                                                  ),
                                                  child: const Text("VS", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  match['teamBName'],
                                                  textAlign: TextAlign.left,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              // Espacio vacío para equilibrar el botón de edición izquierdo
                                              const SizedBox(width: 48), 
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}