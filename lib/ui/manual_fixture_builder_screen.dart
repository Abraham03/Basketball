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

  // --- NUEVO: BOTTOM SHEET PARA SELECCIÓN DE JORNADAS ---
  void _showRoundsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparente para aplicar nuestro propio diseño redondeado
      isScrollControlled: true, // Permite que el modal ocupe más espacio si es necesario
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5, // Ocupará la mitad de la pantalla
              decoration: BoxDecoration(
                color: const Color(0xFF1E2432).withValues(alpha: 0.9), // Fondo oscuro esmerilado
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  // --- BARRA DE ARRASTRE (Grip) ---
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // --- TÍTULO ---
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Seleccionar Jornada",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  
                  // --- LISTA DE JORNADAS ---
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _availableRounds.length,
                      itemBuilder: (context, index) {
                        final rId = _availableRounds[index];
                        final isSelected = rId == _selectedRoundId;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                          tileColor: isSelected ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.transparent,
                          title: Text(
                            "Jornada $rId",
                            style: TextStyle(
                              color: isSelected ? Colors.orangeAccent : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                              fontSize: 18,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.orangeAccent) 
                              : null,
                          onTap: () {
                            Navigator.pop(ctx); // Cierra el modal
                            if (rId != _selectedRoundId) {
                              setState(() => _selectedRoundId = rId);
                              _loadData(); // Carga los partidos de la nueva jornada
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              f.status.isNotIn(['CANCELLED', 'DELETED']))) 
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
              f.roundName.equals("Jornada $_selectedRoundId") &
              f.status.isNotIn(['DELETED'])))
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
        'status': f.status, 
      };
    }).toList();
  }

  // --- ALGORITMO PREDICTIVO DE EMPAREJAMIENTO ACTUALIZADO ---
  // Ahora solo bloquea si intentan jugar en la misma jornada.
  /*
  bool _canCompleteRound(int ignoreTeamA, int ignoreTeamB, {int releasingTeamA = 0, int releasingTeamB = 0}) {
    // 1. Verificar regla estricta: ¿Alguien ya jugó en ESTA jornada?
    bool aPlayedRound = false;
    bool bPlayedRound = false;

    for (var t in _teamsStatus) {
      int tId = int.parse(t['id'].toString());
      if (tId != releasingTeamA && tId != releasingTeamB) {
        if (int.parse(t['scheduled_this_round'].toString()) > 0) {
          if (tId == ignoreTeamA) aPlayedRound = true;
          if (tId == ignoreTeamB) bPlayedRound = true;
        }
      }
    }

    // SI alguno ya jugó en ESTA jornada, bloqueamos (retorna false)
    if (aPlayedRound || bPlayedRound) return false;

    // Si pasaron la regla de jornada, permitimos guardar (aunque haya advertencia visual de que ya se enfrentaron en el torneo)
    return true; 
  }
*/
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
      builder: (ctx) => const TournamentRulesDialog(showVueltas: true), 
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
                    
                    // --- MENSAJE DE ADVERTENCIA (Solo visual) ---
                    if (selectedTeamA != null && selectedTeamB != null && (_playedMatchups[selectedTeamA]?.contains(selectedTeamB) ?? false))
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          "⚠️ Cuidado: Estos equipos ya se enfrentaron anteriormente en este torneo.",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

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
                          // SIEMPRE habilitado mientras haya 2 equipos distintos
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

  // --- DIÁLOGO PARA EDITAR PARTIDO ---
  void _showEditMatchDialog(Map<String, dynamic> match) {
    int? selectedTeamA = int.tryParse(match['teamAId'].toString());
    int? selectedTeamB = int.tryParse(match['teamBId'].toString());
    
    // Guardamos los originales para la lógica predictiva
    int originalA = selectedTeamA ?? 0;
    int originalB = selectedTeamB ?? 0;
    
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
                      originalTeamIdToIgnore: originalA, 
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
                      originalTeamIdToIgnore: originalB, 
                      onChanged: (val) => setModalState(() => selectedTeamB = val),
                    ),
                    const SizedBox(height: 30),

                    // --- MENSAJE DE ADVERTENCIA (Solo visual) ---
                    if (selectedTeamA != null && selectedTeamB != null && (_playedMatchups[selectedTeamA]?.contains(selectedTeamB) ?? false))
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          "⚠️ Cuidado: Estos equipos ya se enfrentaron anteriormente en este torneo.",
                          style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

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
                          // SIEMPRE habilitado mientras haya 2 equipos distintos
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
    required int? originalTeamIdToIgnore, 
    required Function(int?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3), // Fondo un poco más oscuro para resaltar
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5), // Borde más notorio
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF1E2432), // Color de fondo del menú desplegado
              isExpanded: true,
              iconSize: 28,
              hint: const Text("Seleccionar equipo...", style: TextStyle(color: Colors.white38, fontSize: 15)),
              value: selectedValue,
              icon: Icon(Icons.expand_circle_down, color: color.withValues(alpha: 0.7)),
              items: _teamsStatus.map((team) {
                final teamId = int.parse(team['id'].toString());
                
                bool isOriginalTeam = teamId == originalTeamIdToIgnore;
                bool alreadyPlayedRound = int.parse(team['scheduled_this_round'].toString()) > 0;
                bool isSameTeam = teamId == otherSelectedValue;
                bool alreadyPlayedAgainst = otherSelectedValue != null && 
                    (_playedMatchups[otherSelectedValue]?.contains(teamId) ?? false);

                // Solo deshabilitar si es el mismo equipo o si ya jugó en ESTA jornada. 
                // "alreadyPlayedAgainst" (ya jugaron en el torneo) será solo visual (rojo) pero seleccionable.
                bool isDisabled = isSameTeam;

                // Definir colores y textos según el estado
                Color dotColor = Colors.greenAccent;
                String statusText = "JJ: ${team['total_scheduled']}";
                Color statusColor = Colors.greenAccent;
                IconData statusIcon = Icons.check_circle_outline;

                if (isSameTeam) {
                  dotColor = Colors.orangeAccent;
                  statusText = "EN USO";
                  statusColor = Colors.orangeAccent;
                  statusIcon = Icons.warning_amber_rounded;
                } else if (!isOriginalTeam && alreadyPlayedAgainst) {
                  dotColor = Colors.redAccent;
                  statusText = "YA ENFRENTADOS";
                  statusColor = Colors.redAccent;
                  statusIcon = Icons.block;
                } else if (!isOriginalTeam && alreadyPlayedRound) {
                  dotColor = Colors.redAccent;
                  statusText = "JUGÓ EN JORNADA";
                  statusColor = Colors.redAccent;
                  statusIcon = Icons.event_busy;
                } else if (isOriginalTeam) {
                  dotColor = Colors.blueAccent;
                  statusText = "EQUIPO ACTUAL";
                  statusColor = Colors.blueAccent;
                  statusIcon = Icons.restore;
                }

                return DropdownMenuItem<int>(
                  value: teamId,
                  enabled: !isDisabled,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))
                    ),
                    child: Row(
                      children: [
                        // Indicador de color
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                            boxShadow: [
                              BoxShadow(color: dotColor.withValues(alpha: 0.5), blurRadius: 4)
                            ]
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Nombre del equipo
                        Expanded(
                          child: Text(
                            team['name'].toString().toUpperCase(),
                            style: TextStyle(
                              color: isDisabled ? Colors.white38 : Colors.white,
                              fontWeight: isDisabled ? FontWeight.normal : FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Etiqueta de estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3))
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                statusText, 
                                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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


  // --- FUNCIONES PARA ELIMINAR PARTIDO ---
  void _confirmDeleteMatch(Map<String, dynamic> match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Eliminar Partido", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "¿Estás seguro de que deseas eliminar el partido entre\n\n${match['teamAName']} vs ${match['teamBName']}?", 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteManualMatch(match['id'].toString());
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteManualMatch(String fixtureId) async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final api = ref.read(apiServiceProvider);

      int? numericId = int.tryParse(fixtureId);
      
      if (numericId != null) {
        // El partido ya existía en la nube. Intentamos borrarlo.
        try {
          final success = await api.deleteSingleFixture(numericId);
          if (success) {
            // Se borró en la nube, lo borramos localmente por completo
            await (db.delete(db.fixtures)..where((f) => f.id.equals(fixtureId))).go();
          } else {
            // Falló en la nube, hacemos borrado lógico (Soft Delete)
            await (db.update(db.fixtures)..where((f) => f.id.equals(fixtureId))).write(
              const FixturesCompanion(status: drift.Value('DELETED'), isSynced: drift.Value(false))
            );
          }
        } catch (e) {
          // No hay internet, hacemos borrado lógico para sincronizarlo después
          await (db.update(db.fixtures)..where((f) => f.id.equals(fixtureId))).write(
            const FixturesCompanion(status: drift.Value('DELETED'), isSynced: drift.Value(false))
          );
        }
      } else {
        // Si no tiene ID numérico, significa que nunca subió a la nube (se creó offline). Se puede borrar de raíz.
        await (db.delete(db.fixtures)..where((f) => f.id.equals(fixtureId))).go();
      }

      await _loadData(); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Partido eliminado exitosamente"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al eliminar: $e"), backgroundColor: Colors.red),
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
                                      Text("Jornada Actual", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  
                                  // --- BOTÓN QUE ABRE EL BOTTOM SHEET ---
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _showRoundsBottomSheet, // <- Llama al modal
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.3), 
                                          borderRadius: BorderRadius.circular(16), 
                                          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 1.5), 
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orangeAccent.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Jornada $_selectedRoundId",
                                              style: const TextStyle(
                                                color: Colors.orangeAccent, 
                                                fontSize: 18, 
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.0
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.expand_circle_down, color: Colors.orangeAccent, size: 22),
                                          ],
                                        ),
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
                                             if (match['status'] == 'SCHEDULED')
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_calendar, color: Colors.white54),
                                                      onPressed: () => _showEditMatchDialog(match),
                                                      tooltip: "Editar Equipos",
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      onPressed: () => _confirmDeleteMatch(match),
                                                      tooltip: "Eliminar Partido",
                                                    ),
                                                  ],
                                                )
                                              else
                                                // Si ya se jugó o está en curso, mostramos un candado
                                                const Padding(
                                                  padding: EdgeInsets.all(12.0),
                                                  child: Icon(Icons.lock, color: Colors.redAccent, size: 20),
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