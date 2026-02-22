// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart';
import '../core/utils/pdf_generator.dart';
import '../logic/match_game_controller.dart';
import '../ui/protest_signature_screen.dart';
import '../ui/pdf_preview_screen.dart';

class MatchControlScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String teamAName;
  final String teamBName;
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;
  final String tournamentName;
  final String venueName;
  final List<Player> fullRosterA;
  final List<Player> fullRosterB;
  final Set<int> startersAIds;
  final Set<int> startersBIds;
  final int tournamentId;
  final int venueId;
  final int teamAId;
  final int teamBId;
  final String coachA;
  final String coachB;
  final int? captainAId;
  final int? captainBId;
  final DateTime? matchDate;

  const MatchControlScreen({
    super.key,
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
    required this.mainReferee,
    required this.auxReferee,
    required this.scorekeeper,
    required this.tournamentName,
    required this.venueName,
    required this.fullRosterA,
    required this.fullRosterB,
    required this.startersAIds,
    required this.startersBIds,
    required this.tournamentId,
    required this.venueId,
    required this.teamAId,
    required this.teamBId,
    required this.coachA,
    required this.coachB,
    this.captainAId,
    this.captainBId,
    this.matchDate,
  });

  @override
  ConsumerState<MatchControlScreen> createState() => _MatchControlScreenState();
}

class _MatchControlScreenState extends ConsumerState<MatchControlScreen> {
  Uint8List? _capturedSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Leemos el estado actual del partido en memoria
      final currentState = ref.read(matchGameProvider);

      // 2. Solo reiniciamos los marcadores a 0 si es un partido nuevo
      if (currentState.matchId != widget.matchId) {
        ref.read(matchGameProvider.notifier).initializeNewMatch(
              matchId: widget.matchId,
              rosterA: widget.fullRosterA,
              rosterB: widget.fullRosterB,
              startersA: widget.startersAIds,
              startersB: widget.startersBIds,
              tournamentId: widget.tournamentId,
              venueId: widget.venueId,
              teamAId: widget.teamAId,
              teamBId: widget.teamBId,
              mainReferee: widget.mainReferee,
              auxReferee: widget.auxReferee,
              scorekeeper: widget.scorekeeper,
            );
      }
    });
  }

    bool _isNumberTaken(String teamSide, String newNumber, String currentPlayerName) {
    final state = ref.read(matchGameProvider);
    List<String> teammates = [];
    
    // 1. Obtenemos la lista completa del equipo (Cancha + Banca)
    if (teamSide == 'A') {
      teammates = [...state.teamAOnCourt, ...state.teamABench];
    } else {
      teammates = [...state.teamBOnCourt, ...state.teamBBench];
    }

    // 2. Buscamos si alguien más ya tiene ese número
    for (var player in teammates) {
      // Ignoramos al jugador que estamos editando (puede conservar su propio número)
      if (player == currentPlayerName) continue; 
      
      final pStats = state.playerStats[player];
      if (pStats?.playerNumber == newNumber) {
        return true; // ¡Número ocupado!
      }
    }
    return false; // Número disponible
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final controller = ref.read(matchGameProvider.notifier);

    ref.listen<MatchState>(matchGameProvider, (previous, next) {
      next.playerStats.forEach((playerId, stats) {
        final previousFouls = previous?.playerStats[playerId]?.fouls ?? 0;
        if (stats.fouls == 5 && previousFouls == 4) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("⚠️ Límite de Faltas", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text("El jugador $playerId ha llegado a 5 faltas."),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text("Entendido"))
              ],
            ),
          );
        }
      });

      if ((previous?.timeLeft.inSeconds ?? 1) > 0 && next.timeLeft.inSeconds == 0) {
        bool isRegularTimeOver = next.currentPeriod >= 4;
        String title = !isRegularTimeOver ? "Fin del Periodo ${next.currentPeriod}" : (next.scoreA == next.scoreB ? "¡EMPATE!" : "Fin del Partido");
        String content = !isRegularTimeOver ? "¿Iniciar Periodo ${next.currentPeriod + 1}?" : (next.scoreA == next.scoreB ? "¿Iniciar Tiempo Extra?" : "Marcador Final: ${next.scoreA} - ${next.scoreB}");
        String btnText = !isRegularTimeOver ? "Siguiente" : (next.scoreA == next.scoreB ? "Tiempo Extra" : "Finalizar");
        
        VoidCallback action = !isRegularTimeOver || next.scoreA == next.scoreB 
            ? () => controller.nextPeriod()
            : () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (context.mounted) _showFinalOptionsDialog(context, next);
                });
              };

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Revisar")),
              FilledButton(onPressed: () { action(); Navigator.pop(context); }, child: Text(btnText)),
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Control de Juego"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1F2B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Deshacer",
            onPressed: controller.undo,
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: "Ver Acta",
            onPressed: () => _goToPdfPreview(context, gameState, _capturedSignature),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: "Guardar",
            onPressed: () => _finishMatchProcess(context, gameState, _capturedSignature),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfessionalScoreboard(context, gameState, controller),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildTeamList(
                    context, 
                    widget.teamAName, 
                    Colors.orange.shade700, 
                    'A', 
                    gameState.teamAOnCourt, 
                    gameState.teamABench, 
                    controller, 
                    gameState
                  )
                ),
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildTeamList(
                    context, 
                    widget.teamBName, 
                    Colors.blue.shade700, 
                    'B', 
                    gameState.teamBOnCourt, 
                    gameState.teamBBench, 
                    controller, 
                    gameState
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalScoreboard(BuildContext context, MatchState state, MatchGameController controller) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    
    const Color boardColor = Color(0xFF1A1F2B);
    const Color accentColor = Colors.amberAccent;
    const TextStyle scoreStyle = TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0);
    const TextStyle nameStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: boardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showPeriodSelector(context, controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white10
              ),
              child: Text(
                state.currentPeriod <= 4 ? "PERIODO ${state.currentPeriod}" : "TIEMPO EXTRA ${state.currentPeriod - 4}",
                style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showTeamOptions(context, controller, 'A', widget.teamAName),
                      child: Text(widget.teamAName, style: nameStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreA.toString(), style: scoreStyle)),
                    const SizedBox(height: 8),
                    _buildTimeoutDots(state.teamATimeouts1, state.teamATimeouts2, Colors.orange),
                    const SizedBox(height: 4),
                    _buildCompactFouls(controller.getTeamFouls('A'), Colors.orange),
                  ],
                ),
              ),

              Expanded(
                flex: 0, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: controller.toggleTimer,
                        onLongPress: () => !state.isRunning ? _showTimePicker(context, controller, state.timeLeft) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: state.isRunning ? Colors.green : Colors.red, width: 2),
                          ),
                          child: Text(
                            "$minutes:$seconds",
                            style: TextStyle(
                              fontSize: 36, 
                              fontWeight: FontWeight.bold, 
                              fontFamily: "monospace",
                              color: state.isRunning ? Colors.greenAccent : Colors.redAccent
                            ),
                          ),
                        ),
                      ),
                      if (!state.isRunning)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text("PAUSADO", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLargePossessionArrow(
                            isActive: state.possession == 'A', 
                            color: Colors.lightGreenAccent.shade700, 
                            icon: Icons.arrow_left_rounded,
                            onTap: () => controller.setPossession('A')
                          ),
                          const SizedBox(width: 8),
                          _buildLargePossessionArrow(
                            isActive: state.possession == 'B', 
                            color: Colors.lightGreenAccent.shade700, 
                            icon: Icons.arrow_right_rounded,
                            onTap: () => controller.setPossession('B')
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showTeamOptions(context, controller, 'B', widget.teamBName),
                      child: Text(widget.teamBName, style: nameStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreB.toString(), style: scoreStyle)),
                    const SizedBox(height: 8),
                    _buildTimeoutDots(state.teamBTimeouts1, state.teamBTimeouts2, Colors.blue),
                     const SizedBox(height: 4),
                    _buildCompactFouls(controller.getTeamFouls('B'), Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargePossessionArrow({required bool isActive, required Color color, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)] : []
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white24,
          size: 75, // FLECHA GRANDE
        ),
      ),
    );
  }

  Widget _buildTimeoutDots(List<String> t1, List<String> t2, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for(int i=0; i<2; i++)
          Container(
            margin: const EdgeInsets.all(1),
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i < t1.length ? activeColor : Colors.grey.shade700),
          ),
        const SizedBox(width: 4),
        for(int i=0; i<3; i++)
          Container(
            margin: const EdgeInsets.all(1),
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i < t2.length ? activeColor : Colors.grey.shade700),
          ),
      ],
    );
  }

Widget _buildCompactFouls(int fouls, Color color) {
    // Definimos si estamos en penalización (5 o más) para mantener el color rojo de alerta
    bool isPenalty = fouls >= 5;

    // LÓGICA DE CAPA: Si fouls es mayor a 4, mostramos 4. Si no, mostramos el real.
    int displayFouls = fouls > 4 ? 4 : fouls;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        // Mantenemos el fondo rojo para indicar visualmente que ya se llenó el cupo
        color: isPenalty ? Colors.red.withOpacity(0.2) : Colors.transparent,
        border: Border.all(color: isPenalty ? Colors.red : Colors.grey.shade700),
        borderRadius: BorderRadius.circular(4)
      ),
      child: Text(
        // SIEMPRE muestra "Faltas: X", pero X nunca pasará de 4.
        "Faltas: $displayFouls", 
        style: TextStyle(
          color: isPenalty ? Colors.redAccent : Colors.grey, 
          fontSize: 11, 
          fontWeight: FontWeight.bold
        )
      ),
    );
  }
  Widget _buildTeamList(
    BuildContext context,
    String teamName,
    Color primaryColor,
    String teamId,
    List<String> onCourt,
    List<String> bench,
    MatchGameController controller,
    MatchState state,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("EN CANCHA", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
               InkWell(
                 onTap: () => _showSubstitutionDialog(context, teamId, onCourt, bench, controller),
                 child: Icon(Icons.swap_vert_circle, color: primaryColor, size: 28),
               )
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: onCourt.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final playerName = onCourt[index];
              final stats = state.playerStats[playerName] ?? const PlayerStats();
              bool isDisqualified = stats.fouls >= 5;

              return InkWell(
                onTap: () => _showActionMenu(context, teamId, playerName, controller, stats.fouls),
                onLongPress: () {
                  _showEditPlayerDialog(context, controller, playerName, stats.playerNumber, teamId);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isDisqualified ? Border.all(color: Colors.red.shade200) : null,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDisqualified ? Colors.red.shade100 : primaryColor.withOpacity(0.1),
                        child: Text(
                          stats.playerNumber.isNotEmpty ? stats.playerNumber : "#",
                          style: TextStyle(color: isDisqualified ? Colors.red : primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(playerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text("${stats.points} pts", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(5, (i) {
                                    Color dotColor = Colors.grey.shade300;
                                    if (i < stats.fouls) {
                                       dotColor = (i == 4) ? Colors.red : Colors.orange;
                                    }
                                    return Container(
                                      margin: const EdgeInsets.only(right: 3),
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                                    );
                                  }),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

void _showEditPlayerDialog(
    BuildContext context, 
    MatchGameController controller, 
    String playerName, 
    String currentNumber,
    String teamSide 
  ) {
    final numberController = TextEditingController(text: currentNumber);
    final errorNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar: $playerName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Este cambio solo aplicará para el partido actual.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: errorNotifier,
              builder: (context, errorText, child) {
                return TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  // Se eliminó 'const' aquí porque 'errorText' es variable
                  decoration: InputDecoration(
                    labelText: "Número (Dorsal)",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    errorText: errorText, 
                  ),
                  onChanged: (_) => errorNotifier.value = null,
                );
              }
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              final newNum = numberController.text.trim();
              if (newNum.isEmpty) {
                errorNotifier.value = "El número no puede estar vacío";
                return;
              }
              if (_isNumberTaken(teamSide, newNum, playerName)) {
                errorNotifier.value = "El número $newNum ya está en uso";
                return;
              }
              
              controller.updateMatchPlayerInfo(playerName, newNumber: newNum);
              Navigator.pop(ctx);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }



  void _showFoulOptionsDialog(BuildContext context, MatchGameController controller, String teamId, String playerName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("REGISTRAR FALTA", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Text(playerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const Divider(height: 24),

              _buildFoulSectionHeader("PERSONAL (P)", Icons.person, Colors.blueGrey),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildFoulChip(ctx, controller, teamId, playerName, "Lateral", "P", Colors.blueGrey.shade50, Colors.blueGrey.shade800),
                  _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "P1", Colors.blueGrey.shade50, Colors.blueGrey.shade800),
                  _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "P2", Colors.blueGrey.shade50, Colors.blueGrey.shade800),
                  _buildFoulChip(ctx, controller, teamId, playerName, "3 Tiros", "P3", Colors.blueGrey.shade50, Colors.blueGrey.shade800),
                ],
              ),

              const SizedBox(height: 20),

              _buildFoulSectionHeader("CONDUCTA / GRAVES", Icons.warning_amber_rounded, Colors.orange.shade800),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactCategoryLabel("TÉCNICA", Colors.orange),
                    const SizedBox(width: 8),
                    _buildFoulChip(ctx, controller, teamId, playerName, "Simple", "T", Colors.orange.shade50, Colors.orange.shade900, isCompact: true),
                    const SizedBox(width: 6),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "T1", Colors.orange.shade50, Colors.orange.shade900, isCompact: true),
                    const SizedBox(width: 6),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "T2", Colors.orange.shade50, Colors.orange.shade900, isCompact: true),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactCategoryLabel("ANTIDEP.", Colors.deepOrange),
                    const SizedBox(width: 8),
                    _buildFoulChip(ctx, controller, teamId, playerName, "Simple", "U", Colors.deepOrange.shade50, Colors.deepOrange.shade900, isCompact: true),
                    const SizedBox(width: 6),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "U1", Colors.deepOrange.shade50, Colors.deepOrange.shade900, isCompact: true),
                    const SizedBox(width: 6),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "U2", Colors.deepOrange.shade50, Colors.deepOrange.shade900, isCompact: true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade800,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red.shade200))
                  ),
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: const Text("DESCALIFICANTE (D)", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // 1. Registrar la falta en la base de datos/estado
                    controller.updateStats(teamId, playerName, fouls: 5, foulType: "D");
                    
                    // 2. Cerrar el diálogo actual de selección de faltas
                    Navigator.pop(ctx); 

                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoulSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCompactCategoryLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFoulChip(
    BuildContext ctx, 
    MatchGameController controller, 
    String teamId, 
    String playerName, 
    String label, 
    String typeCode, 
    Color bgColor, 
    Color textColor,
    {bool isCompact = false}
  ) {
    return InkWell(
      onTap: () {
        controller.updateStats(teamId, playerName, fouls: 1, foulType: typeCode);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isCompact ? null : 80,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 8, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(typeCode, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
            if (!isCompact) ...[
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)), textAlign: TextAlign.center),
            ]
          ],
        ),
      ),
    );
  }

void _showActionMenu(BuildContext context, String teamId, String playerName, MatchGameController controller, int currentFouls) {
    bool isDisqualified = currentFouls >= 5;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(playerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                isDisqualified ? "JUGADOR DESCALIFICADO" : "Selecciona una acción", 
                style: TextStyle(
                  color: isDisqualified ? Colors.red : Colors.grey, 
                  fontWeight: isDisqualified ? FontWeight.bold : FontWeight.normal
                )
              ),
              const SizedBox(height: 24),
              
              if (isDisqualified) ...[
                // --- LÓGICA DE BLOQUEO Y SUSTITUCIÓN ---
                const Icon(Icons.block, size: 50, color: Colors.red),
                const SizedBox(height: 10),
                const Text(
                  "No se pueden agregar más eventos a este jugador.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text("REALIZAR SUSTITUCIÓN AHORA"),
                    onPressed: () {
                      Navigator.pop(context); // Cerramos el menú
                      // Abrimos el diálogo de sustitución pre-llenado
                      // Necesitamos acceder a las listas del estado actual
                      final currentState = ref.read(matchGameProvider);
                      final onCourt = teamId == 'A' ? currentState.teamAOnCourt : currentState.teamBOnCourt;
                      final bench = teamId == 'A' ? currentState.teamABench : currentState.teamBBench;
                      
                      _showSubstitutionDialog(
                        context, 
                        teamId, 
                        onCourt, 
                        bench, 
                        controller, 
                        preSelectedOut: playerName // <--- AQUÍ PASAMOS EL JUGADOR
                      );
                    },
                  ),
                )
              ] else
                // --- LÓGICA NORMAL ---
                Wrap(
                  spacing: 16, runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatButton("+1", Colors.blue, () { controller.updateStats(teamId, playerName, points: 1); Navigator.pop(context); }),
                    _buildStatButton("+2", Colors.green, () { controller.updateStats(teamId, playerName, points: 2); Navigator.pop(context); }),
                    _buildStatButton("+3", Colors.orange, () { controller.updateStats(teamId, playerName, points: 3); Navigator.pop(context); }),
                    _buildStatButton("Falta", Colors.red, () { Navigator.pop(context); _showFoulOptionsDialog(context, controller, teamId, playerName); }, icon: Icons.error_outline),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  

  Widget _buildStatButton(String label, Color color, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: color, size: 28)
            else Text(label, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            if (icon != null) Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))
          ],
        ),
      ),
    );
  }

  void _showTeamOptions(BuildContext context, MatchGameController controller, String teamId, String teamName) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(teamName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: Colors.blueGrey),
              title: const Text("Solicitar Tiempo Fuera"),
              onTap: () { controller.addTimeout(teamId); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.sports, color: Colors.orange),
              title: const Text("Falta Técnica al Entrenador (C)"),
              onTap: () { controller.addTeamFoul(teamId, 'C'); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta al Coach (C) registrada"))); },
            ),
            ListTile(
              leading: const Icon(Icons.chair, color: Colors.blue),
              title: const Text("Falta Técnica a la Banca (B)"),
              onTap: () { controller.addTeamFoul(teamId, 'B'); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta a la Banca (B) registrada"))); },
            ),
          ],
        ),
      ),
    );
  }

void _showSubstitutionDialog(
    BuildContext context, 
    String teamId, 
    List<String> onCourt, 
    List<String> bench, 
    MatchGameController controller, 
    {String? preSelectedOut} 
  ) {
    // Inicializamos con el jugador expulsado si existe
    String? selectedOut = preSelectedOut; 
    String? selectedIn;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Sustitución"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Si viene pre-seleccionado (expulsado), bloqueamos el dropdown o lo dejamos fijo
              _dropdown(
                "Sale (Cancha)", 
                onCourt, 
                selectedOut, 
                (v) => setState(() => selectedOut = v)
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Icon(Icons.arrow_downward, color: Colors.grey)),
              _dropdown(
                "Entra (Banca)", 
                bench, 
                selectedIn, 
                (v) => setState(() => selectedIn = v)
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancelar")
            ),
            FilledButton(
              onPressed: (selectedOut != null && selectedIn != null) 
                  ? () { 
                      controller.substitutePlayer(teamId, selectedOut!, selectedIn!); 
                      Navigator.pop(context); 
                    } 
                  : null,
              child: const Text("Confirmar Cambio"),
            )
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String? val, Function(String?) changed) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isDense: true,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: changed,
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, MatchGameController controller, Duration currentTime) {
    int selectedMinute = currentTime.inMinutes;
    int selectedSecond = currentTime.inSeconds % 60;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.red))),
                 const Text("Ajustar Reloj", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 TextButton(onPressed: () { controller.setTime(Duration(minutes: selectedMinute, seconds: selectedSecond)); Navigator.pop(context); }, child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold))),
             ]),
             const SizedBox(height: 20),
             Expanded(
                 child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                     SizedBox(width: 70, child: ListWheelScrollView.useDelegate(itemExtent: 50, controller: FixedExtentScrollController(initialItem: selectedMinute), physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (v) => selectedMinute = v, childDelegate: ListWheelChildBuilderDelegate(childCount: 100, builder: (c,i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 30)))))),
                     const Text(":", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                     SizedBox(width: 70, child: ListWheelScrollView.useDelegate(itemExtent: 50, controller: FixedExtentScrollController(initialItem: selectedSecond), physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (v) => selectedSecond = v, childDelegate: ListWheelChildBuilderDelegate(childCount: 60, builder: (c,i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 30)))))),
                 ])
             )
          ],
        ),
      )
    );
  }
  
  void _confirmExit(BuildContext context) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("¿Salir?"),
          content: const Text("El partido continuará guardado."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.of(context).popUntil((r) => r.isFirst); }, child: const Text("Salir")),
          ],
        ),
      );
  }

  void _finishMatchProcess(BuildContext context, MatchState state, Uint8List? signature, {bool autoShow = true}) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    try {
      final api = ref.read(apiServiceProvider);
      final controller = ref.read(matchGameProvider.notifier);

      // Usamos los datos del widget y del state para generar los bytes
      final pdfBytes = await PdfGenerator.generateBytes(
        state,
        widget.teamAName,
        widget.teamBName,
        tournamentName: widget.tournamentName,
        venueName: widget.venueName,
        mainReferee: widget.mainReferee,
        auxReferee: widget.auxReferee,
        scorekeeper: widget.scorekeeper,
        coachA: widget.coachA,
        coachB: widget.coachB,
        captainAId: widget.captainAId,
        captainBId: widget.captainBId,
        protestSignature: signature,
        matchDate: widget.matchDate ?? DateTime.now(),
      );

      // 2. ENVIAR AL CONTROLADOR
      bool synced = await controller.finalizeAndSync(
        api, 
        signature, 
        pdfBytes, // <--- Pasamos el PDF generado
        widget.teamAName, 
        widget.teamBName
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(synced ? "Sincronizado correctamente" : "Guardado localmente (Sin conexión)"), 
            behavior: SnackBarBehavior.floating,
            backgroundColor: synced ? Colors.green.shade700 : Colors.orange.shade700
        ));
        if (autoShow) _goToPdfPreview(context, state, signature);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        if (autoShow) _goToPdfPreview(context, state, signature);
      }
    }
  }
  
  void _goToPdfPreview(BuildContext context, MatchState state, Uint8List? signature) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
          state: state, teamAName: widget.teamAName, teamBName: widget.teamBName, 
          tournamentName: widget.tournamentName, venueName: widget.venueName, 
          mainReferee: widget.mainReferee, auxReferee: widget.auxReferee, scorekeeper: widget.scorekeeper,
          coachA: widget.coachA, coachB: widget.coachB, captainAId: widget.captainAId, captainBId: widget.captainBId,
          matchDate: widget.matchDate, protestSignature: signature
      )));
  }
  
  void _showFinalOptionsDialog(BuildContext context, MatchState currentState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Finalizar Partido"),
        content: const Text("¿Cómo deseas proceder con el acta?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          OutlinedButton.icon(
              icon: const Icon(Icons.edit_document, color: Colors.red), 
              label: const Text("Firmar Bajo Protesta", style: TextStyle(color: Colors.red)), 
              onPressed: () { Navigator.pop(ctx); _handleProtestFlow(context, currentState); }
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
              icon: const Icon(Icons.check_circle), 
              label: const Text("Finalizar y Sincronizar"), 
              onPressed: () { Navigator.pop(ctx); _finishMatchProcess(context, currentState, null); }
          ),
        ],
      ),
    );
  }

    void _showPeriodSelector(BuildContext context, MatchGameController controller) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Seleccionar Periodo"),
        children: [
          _periodOption(context, controller, 1, "Periodo 1"),
          _periodOption(context, controller, 2, "Periodo 2"),
          _periodOption(context, controller, 3, "Periodo 3"),
          _periodOption(context, controller, 4, "Periodo 4"),
          const Divider(),
          _periodOption(context, controller, 5, "Tiempo Extra 1"),
          _periodOption(context, controller, 6, "Tiempo Extra 2"),
        ],
      ),
    );
  }

    Widget _periodOption(BuildContext context, MatchGameController controller, int period, String label) {
    return SimpleDialogOption(
      onPressed: () {
        controller.setPeriod(period);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(label),
      ),
    );
  }

  Future<void> _handleProtestFlow(BuildContext context, MatchState state) async {
    final String? protestingTeam = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("¿Quién protesta?"),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, widget.teamAName), child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.teamAName, style: const TextStyle(fontSize: 16)))),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, widget.teamBName), child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.teamBName, style: const TextStyle(fontSize: 16)))),
        ],
      ),
    );

    if (protestingTeam != null && context.mounted) {
      final Uint8List? signature = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProtestSignatureScreen(teamName: protestingTeam)));
      if (signature != null && context.mounted) {
        setState(() => _capturedSignature = signature);
        _finishMatchProcess(context, state, signature, autoShow: false);
      }
    }
  }
}