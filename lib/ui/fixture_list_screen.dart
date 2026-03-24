// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; 

import '../core/database/app_database.dart';
import '../core/di/dependency_injection.dart';
import 'match_setup_screen.dart';
import '../logic/match_game_controller.dart';
import 'match_control_screen.dart';
import '../ui/widgets/app_background.dart';
import '../ui/manual_fixture_builder_screen.dart';
import '../ui/widgets/tournament_rules_dialog.dart';

// Provider REACTIVO para leer el fixture local de un torneo específico
final localFixtureProvider = StreamProvider.family<Map<String, List<Fixture>>, String>((ref, tournamentId) {
  final db = ref.read(databaseProvider);
  
  return (db.select(db.fixtures)
        ..where((tbl) => tbl.tournamentId.equals(tournamentId))
      ).watch().map((matches) {
        
    final Map<String, List<Fixture>> grouped = {};
    for (var m in matches) {
      if (!grouped.containsKey(m.roundName)) {
        grouped[m.roundName] = [];
      }
      grouped[m.roundName]!.add(m);
    }
    
    return grouped;
  });
});

class FixtureListScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const FixtureListScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<FixtureListScreen> createState() => _FixtureListScreenState();
}

class _FixtureListScreenState extends ConsumerState<FixtureListScreen> {
  // Lo dejamos nulo inicialmente para poder asignarle la Jornada 1 de forma automática al cargar
  String? _selectedRound;

  // --- HELPER PARA RESOLVER LA RUTA DEL LOGO ---
  String _resolveLogoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return path.replaceAll('../', 'https://basket.techsolutions.management/');
  }

  // --- HELPER PARA TEXTO DE ENFRENTAMIENTO ---
  String _getEncounterText(int count) {
    switch (count) {
      case 1: return "1er Encuentro";
      case 2: return "2do Encuentro";
      case 3: return "3er Encuentro";
      case 4: return "4to Encuentro";
      case 5: return "5to Encuentro";
      case 6: return "6to Encuentro";
      default: return "${count}º Encuentro";
    }
  }

  // --- BOTTOM SHEET DE OPCIONES DE GENERACIÓN ---
  void _showGenerationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2432),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Creación de Calendario", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text("Elige cómo deseas programar los partidos de este torneo.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white.withValues(alpha: 0.05),
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.auto_awesome, color: Colors.white)),
              title: const Text("Generación Automática", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Crea todas las jornadas y cruza a todos los equipos usando el método de Round Robin.", style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _generateNewFixture(context); 
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white.withValues(alpha: 0.05),
              leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.edit_calendar, color: Colors.black)),
              title: const Text("Constructor Manual", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text("Crea jornadas y programa partidos uno por uno, ideal para torneos en progreso.", style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ManualFixtureBuilderScreen(tournamentId: widget.tournamentId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET DE FILTRO DE JORNADAS ---
  void _showRoundsFilterBottomSheet(List<String> rounds, String currentActiveRound) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45, 
              decoration: BoxDecoration(
                color: const Color(0xFF1E2432).withValues(alpha: 0.9), 
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Filtrar por Jornada",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: rounds.length,
                      itemBuilder: (context, index) {
                        final round = rounds[index];
                        final isSelected = round == currentActiveRound;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                          tileColor: isSelected ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.transparent,
                          title: Text(
                            round.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.orangeAccent : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.orangeAccent) 
                              : null,
                          onTap: () {
                            Navigator.pop(ctx); 
                            if (round != currentActiveRound) {
                              setState(() => _selectedRound = round); 
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

  Future<void> _generateNewFixture(BuildContext context) async {
    final rules = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const TournamentRulesDialog(showVueltas: true),
    );

    if (rules == null || !mounted) return;
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
    );

    try {
      final api = ref.read(apiServiceProvider);
      
      final rulesSaved = await api.saveTournamentRules(
        tournamentId: widget.tournamentId,
        vueltas: rules['vueltas'],
        ptsVictoria: rules['win'],
        ptsDerrota: rules['loss'],
        ptsEmpate: rules['draw'],
        ptsForfeitWin: rules['forfeitWin'],
        ptsForfeitLoss: rules['forfeitLoss'],
      );

      if (!rulesSaved) throw Exception("Error guardando las reglas del torneo");

      final success = await api.generateFixture(
        tournamentId: widget.tournamentId,
      );
      
      if (success) {
        final newFixtureData = await api.fetchFixture(widget.tournamentId);
        
        if (newFixtureData.isNotEmpty && newFixtureData['rounds'] != null) {
          final db = ref.read(databaseProvider);
          await (db.delete(db.fixtures)..where((f) => f.tournamentId.equals(widget.tournamentId))).go();

          final roundsMap = newFixtureData['rounds'] as Map<String, dynamic>;
          await db.transaction(() async {
            for (var entry in roundsMap.entries) {
              final roundName = entry.key;
              for (var m in (entry.value as List)) {
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
                  ),
                  mode: drift.InsertMode.insertOrReplace
                );
              }
            }
          });
          
          ref.invalidate(localFixtureProvider(widget.tournamentId));
          setState(() => _selectedRound = null); // Reset a default al generar
        }

        if (!mounted) return; 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Calendario generado con éxito"), backgroundColor: Colors.green));
      } else {
        throw Exception("El servidor rechazó la solicitud de generación");
      }
    } catch (e) {
      if (!mounted) return; 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixtureAsync = ref.watch(localFixtureProvider(widget.tournamentId));

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent, 
      
      appBar: AppBar(
        title: const Text("Calendario de Juegos", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0)),
        backgroundColor: Colors.black.withValues(alpha: 0.6), 
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGenerationOptions(context),
        icon: const Icon(Icons.add_chart),
        label: const Text("Crear Calendario", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        elevation: 4,
      ),

      body: AppBackground(
        opacity: 0.8,
        child: fixtureAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
          error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
          data: (groupedRounds) {
            if (groupedRounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_month_outlined, size: 70, color: Colors.white54),
                    ),
                    const SizedBox(height: 24),
                    const Text("Aún no hay partidos", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      "Configura y genera el calendario\ndesde el botón inferior.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)
                    ),
                  ],
                ),
              );
            }

            // --- LÓGICA DE CONTEO DE ENFRENTAMIENTOS ---
            List<Fixture> allMatches = [];
            for (var list in groupedRounds.values) {
              allMatches.addAll(list);
            }
            
            // Ordenar los partidos de forma cronológica (por Jornada)
            allMatches.sort((a, b) {
              int roundA = int.tryParse(a.roundName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              int roundB = int.tryParse(b.roundName.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (roundA != roundB) return roundA.compareTo(roundB);
              return a.id.compareTo(b.id);
            });

            // Mapa para almacenar qué enfrentamiento es para cada partido
            Map<String, int> encounterMap = {};
            Map<String, int> pairCounts = {};

            for (var m in allMatches) {
              // Creamos una clave única para cada par de equipos (ej: "12_15")
              List<String> teams = [m.teamAId, m.teamBId];
              teams.sort();
              String pairKey = teams.join('_');
              
              pairCounts[pairKey] = (pairCounts[pairKey] ?? 0) + 1;
              encounterMap[m.id] = pairCounts[pairKey]!;
            }

            // 1. Configuramos la lista completa de opciones del Bottom Sheet
            List<String> allRounds = ["Todas", ...groupedRounds.keys];

            // 2. Establecemos "Jornada 1" (o la primera llave disponible) como predeterminada si no hay selección
            String activeRound = _selectedRound ?? (groupedRounds.keys.isNotEmpty ? groupedRounds.keys.first : "Todas");

            // 3. Filtramos los datos
            Map<String, List<Fixture>> filteredRounds = {};
            if (activeRound == "Todas") {
              filteredRounds = groupedRounds;
            } else if (groupedRounds.containsKey(activeRound)) {
              filteredRounds[activeRound] = groupedRounds[activeRound]!;
            }

            return SafeArea(
              child: Column(
                children: [
                  
                  // --- BOTÓN DE FILTRO POR JORNADA (ABRE BOTTOM SHEET) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filtrar Partidos", 
                          style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showRoundsFilterBottomSheet(allRounds, activeRound),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    activeRound.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.orangeAccent, 
                                      fontSize: 15, 
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.filter_list, color: Colors.orangeAccent, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LISTA DE PARTIDOS FILTRADOS ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100), 
                      itemCount: filteredRounds.keys.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final roundName = filteredRounds.keys.elementAt(index);
                        final matches = filteredRounds[roundName]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Solo mostramos el separador si estamos en la vista "Todas"
                            if (activeRound == "Todas") 
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flag, color: Colors.black87, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            roundName.toUpperCase(), 
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87, letterSpacing: 1.2)
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Colors.white38, indent: 12)),
                                  ],
                                ),
                              ),
                            
                            // Renderizamos el Card enviando el número de enfrentamiento calculado
                            ...matches.map((m) => _buildMatchCard(context, m, encounterMap[m.id] ?? 1)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPER PARA LOGOS ---
  Widget _buildTeamLogo(String? logoPath, String teamName) {
    final String resolvedUrl = _resolveLogoUrl(logoPath);
    final String initial = teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipOval(
        child: resolvedUrl.isNotEmpty
            ? Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)),
                ),
              )
            : Center(
                child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)),
              ),
      ),
    );
  }

  // --- DISEÑO DE TARJETA DE PARTIDO PROFESIONAL ---
  Widget _buildMatchCard(BuildContext context, Fixture match, int encounterNumber) {
    final isPlayable = match.status == 'SCHEDULED' || 
                       match.status == 'PENDING' || 
                       match.status == 'IN_PROGRESS' || 
                       match.status == 'PLAYING';

    final isFinished = match.status == 'FINISHED';

    String dateFormatted = "Horario por definir";
    if (match.scheduledDatetime != null) {
      final dt = match.scheduledDatetime!;
      dateFormatted = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}  •  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} hrs";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPlayable ? () {
                 if (match.status == 'IN_PROGRESS' || match.status == 'PLAYING') {
                   final currentState = ref.read(matchGameProvider);
                   if (currentState.matchId == match.matchId && currentState.matchId.isNotEmpty) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => MatchControlScreen(
                         matchId: currentState.matchId,
                         teamAName: match.teamAName,
                         teamBName: match.teamBName,
                         tournamentName: "Torneo Activo", 
                         categoryName: "LIBRE",
                         tournamentLogoUrl: "",
                         venueName: match.venueName ?? '',
                         mainReferee: currentState.mainReferee,
                         auxReferee: currentState.auxReferee,
                         scorekeeper: currentState.scorekeeper,
                         fullRosterA: const [], 
                         fullRosterB: const [], 
                         startersAIds: const {},
                         startersBIds: const {},
                         tournamentId: currentState.tournamentId ?? int.tryParse(widget.tournamentId) ?? 0,
                         venueId: currentState.venueId ?? 0,
                         teamAId: currentState.teamAId ?? 0,
                         teamBId: currentState.teamBId ?? 0,
                         coachA: '',
                         coachB: '',
                       )));
                     return; 
                   }
                 }

                 Navigator.push(context, MaterialPageRoute(builder: (_) => MatchSetupScreen(
                     tournamentId: widget.tournamentId,
                     preSelectedFixture: match,
                   ),
                 ));
              } : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("ℹ️ Partido en estado: ${match.status}"), backgroundColor: Colors.blueGrey)
                  );
              },
              splashColor: Colors.orange.withValues(alpha: 0.3),
              highlightColor: Colors.orange.withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearBinding.linear(
                    Colors.white.withValues(alpha: 0.15), 
                    Colors.white.withValues(alpha: 0.03)
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadge(match.status),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month, size: 14, color: Colors.orangeAccent),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        dateFormatted, 
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 13, color: Colors.white54),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        match.venueName ?? 'Sede TBD', 
                                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildTeamLogo(match.logoA, match.teamAName),
                                const SizedBox(height: 8),
                                Text(
                                  match.teamAName, 
                                  textAlign: TextAlign.center, 
                                  maxLines: 2,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Text(
                                  isFinished && match.scoreA != null && match.scoreB != null 
                                      ? "${match.scoreA} - ${match.scoreB}" 
                                      : "VS", 
                                  style: TextStyle(
                                    color: isFinished ? Colors.white : Colors.orangeAccent, 
                                    fontSize: 28, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0
                                  )
                                ),
                                const SizedBox(height: 4),
                                
                                // --- NUEVO: ETIQUETA DE NÚMERO DE ENFRENTAMIENTO ---
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getEncounterText(encounterNumber).toUpperCase(), 
                                    style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: isPlayable ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.05), 
                                    shape: BoxShape.circle,
                                    boxShadow: isPlayable ? [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)] : []
                                  ),
                                  child: Icon(
                                    (match.status == 'IN_PROGRESS' || match.status == 'PLAYING') 
                                        ? Icons.restore 
                                        : isPlayable 
                                            ? Icons.play_arrow_rounded 
                                            : Icons.lock_outline_rounded,
                                    color: isPlayable ? Colors.black : Colors.white38, 
                                    size: 26
                                  )
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildTeamLogo(match.logoB, match.teamBName),
                                const SizedBox(height: 8),
                                Text(
                                  match.teamBName, 
                                  textAlign: TextAlign.center, 
                                  maxLines: 2,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color txtColor;
    String label;

    switch (status) {
      case 'FINISHED':
        bgColor = Colors.green.withValues(alpha: 0.2);
        txtColor = Colors.greenAccent;
        label = "FINALIZADO";
        break;
      case 'IN_PROGRESS':
      case 'PLAYING':
        bgColor = Colors.orange.withValues(alpha: 0.2);
        txtColor = Colors.orangeAccent;
        label = "EN JUEGO";
        break;
      case 'FORFEIT_A':
      case 'FORFEIT_B':
        bgColor = Colors.red.withValues(alpha: 0.2);
        txtColor = Colors.redAccent;
        label = "AUSENCIA";
        break;
      case 'SCHEDULED':
      case 'PENDING':
      default:
        bgColor = Colors.white.withValues(alpha: 0.1);
        txtColor = Colors.white70;
        label = "PROGRAMADO";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: txtColor.withValues(alpha: 0.5))
      ),
      child: Text(label, style: TextStyle(color: txtColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }
}

class LinearBinding {
   static LinearGradient linear(Color c1, Color c2) {
      return LinearGradient(
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
         colors: [c1, c2],
      );
   }
}