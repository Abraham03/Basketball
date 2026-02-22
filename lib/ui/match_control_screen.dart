// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart';
import '../core/utils/pdf_generator.dart';
import '../logic/match_game_controller.dart';
import '../ui/protest_signature_screen.dart';
import '../ui/pdf_preview_screen.dart';

// --- IMPORTAMOS EL FONDO REUTILIZABLE ---
import '../ui/widgets/app_background.dart';

class MatchControlScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String? fixtureId;
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
    this.fixtureId,
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
      final currentState = ref.read(matchGameProvider);

      if (currentState.matchId != widget.matchId) {
        ref.read(matchGameProvider.notifier).initializeNewMatch(
              matchId: widget.matchId,
              fixtureId: widget.fixtureId,
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
    
    if (teamSide == 'A') {
      teammates = [...state.teamAOnCourt, ...state.teamABench];
    } else {
      teammates = [...state.teamBOnCourt, ...state.teamBBench];
    }

    for (var player in teammates) {
      if (player == currentPlayerName) continue; 
      
      final pStats = state.playerStats[player];
      if (pStats?.playerNumber == newNumber) {
        return true; 
      }
    }
    return false; 
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
              backgroundColor: const Color(0xFF1A1F2B),
              title: const Text("⚠️ Límite de Faltas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              content: Text("El jugador $playerId ha llegado a 5 faltas.", style: const TextStyle(color: Colors.white70)),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Entendido", style: TextStyle(color: Colors.white))
                )
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
            backgroundColor: const Color(0xFF1A1F2B),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            content: Text(content, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Revisar", style: TextStyle(color: Colors.grey))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent),
                onPressed: () { action(); Navigator.pop(context); }, 
                child: Text(btnText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        );
      }
    });

    // Detectamos la orientación de la pantalla
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text("CONTROL DE JUEGO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5), 
        foregroundColor: Colors.white,
        elevation: 0,
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
      body: AppBackground(
        opacity: 0.6, 
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 750;
            
            // Creamos los widgets de los equipos para reutilizarlos en ambos diseños
            Widget teamAWidget = Expanded(
              child: _buildTeamList(
                context, 
                widget.teamAName, 
                Colors.orangeAccent, 
                'A', 
                gameState.teamAOnCourt, 
                gameState.teamABench, 
                controller, 
                gameState,
                isWideScreen
              )
            );

            Widget teamBWidget = Expanded(
              child: _buildTeamList(
                context, 
                widget.teamBName, 
                Colors.lightBlueAccent, 
                'B', 
                gameState.teamBOnCourt, 
                gameState.teamBBench, 
                controller, 
                gameState,
                isWideScreen
              )
            );

            return SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isLandscape 
                    // --- DISEÑO HORIZONTAL (LANDSCAPE) ---
                    ? Row(
                        children: [
                          // Marcador a la izquierda (ocupa 40% de la pantalla)
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: _buildProfessionalScoreboard(context, gameState, controller, isWideScreen, isLandscape: true),
                            ),
                          ),
                          // Listas de equipos a la derecha (ocupa 60% de la pantalla)
                          Expanded(
                            flex: 6,
                            child: Container(
                              margin: EdgeInsets.all(isWideScreen ? 12.0 : 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  teamAWidget,
                                  SizedBox(width: isWideScreen ? 12 : 6),
                                  teamBWidget,
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    // --- DISEÑO VERTICAL (PORTRAIT) ---
                    : Column(
                        children: [
                          _buildProfessionalScoreboard(context, gameState, controller, isWideScreen, isLandscape: false),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(isWideScreen ? 12.0 : 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  teamAWidget,
                                  SizedBox(width: isWideScreen ? 12 : 6),
                                  teamBWidget,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  // =======================================================================
  // MARCADOR DIGITAL (ESTILO PANTALLA LED CON EFECTO GLASS)
  // =======================================================================
  Widget _buildProfessionalScoreboard(BuildContext context, MatchState state, MatchGameController controller, bool isWideScreen, {required bool isLandscape}) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    
    // Tamaños dinámicos ajustados. Si es Landscape, reducimos un poco para que quepa bien en la columna lateral
    final double scoreFontSize = isWideScreen ? (isLandscape ? 70 : 90) : 55;
    final double timeFontSize = isWideScreen ? (isLandscape ? 40 : 50) : 38;
    final double nameFontSize = isWideScreen ? (isLandscape ? 14 : 18) : 14;
    final double arrowSize = isWideScreen ? (isLandscape ? 45 : 60) : 40;

    TextStyle scoreStyle = TextStyle(
      fontSize: scoreFontSize, 
      fontWeight: FontWeight.w900, 
      color: Colors.white, 
      fontFamily: "monospace",
      height: 1.1,
      shadows: const [Shadow(color: Colors.white70, blurRadius: 15)] 
    );
    
    TextStyle nameStyle = TextStyle(
      fontSize: nameFontSize, 
      fontWeight: FontWeight.bold, 
      color: Colors.white,
      letterSpacing: isWideScreen ? 2.0 : 1.0
    );

    return ClipRRect(
      // Si está en Landscape, redondeamos todos los bordes, si no, solo los de abajo
      borderRadius: isLandscape ? BorderRadius.circular(20) : const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
        child: Container(
          margin: isLandscape ? const EdgeInsets.only(left: 8, top: 8, bottom: 8) : EdgeInsets.zero,
          padding: EdgeInsets.fromLTRB(16, isWideScreen ? 16 : 8, 16, isWideScreen ? 24 : 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5), 
            border: Border.all(color: Colors.white24, width: 2), // Borde completo si es landscape
            borderRadius: isLandscape ? BorderRadius.circular(20) : null,
          ),
          // Si estamos en landscape y la pantalla no es "Wide" (celular en horizontal), 
          // evitamos que la columna estalle usando SingleChildScrollView interno.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showPeriodSelector(context, controller),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 20 : 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.amberAccent.withOpacity(0.1)
                  ),
                  child: Text(
                    state.currentPeriod <= 4 ? "PERIODO ${state.currentPeriod}" : "TIEMPO EXTRA ${state.currentPeriod - 4}",
                    style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, letterSpacing: isWideScreen ? 2 : 1, fontSize: isWideScreen ? 14 : 12),
                  ),
                ),
              ),
              SizedBox(height: isWideScreen ? 20 : 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // EQUIPO A
                  Expanded(
                    flex: isWideScreen ? 1 : 2,
                    child: Column(
                      children: [
                        Text(widget.teamAName.toUpperCase(), style: nameStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: isWideScreen ? 10 : 4),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreA.toString().padLeft(2, '0'), style: scoreStyle)),
                        SizedBox(height: isWideScreen ? 12 : 8),
                        _buildTimeoutDots(state.teamATimeouts1, state.teamATimeouts2, Colors.orangeAccent, isWideScreen),
                        const SizedBox(height: 8),
                        _buildCompactFouls(controller.getTeamFouls('A'), Colors.orangeAccent, isWideScreen),
                      ],
                    ),
                  ),

                  // RELOJ CENTRAL Y POSESIÓN
                  Expanded(
                    flex: isWideScreen ? 0 : (isLandscape ? 2 : 3), // Ajuste para celulares en horizontal
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 20 : (isLandscape ? 4 : 8)),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: controller.toggleTimer,
                            onLongPress: () => !state.isRunning ? _showTimePicker(context, controller, state.timeLeft) : null,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 20 : 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: state.isRunning ? Colors.greenAccent : Colors.redAccent, width: 3),
                                boxShadow: [
                                  BoxShadow(color: state.isRunning ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3), blurRadius: 20)
                                ]
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "$minutes:$seconds",
                                  style: TextStyle(
                                    fontSize: timeFontSize, 
                                    fontWeight: FontWeight.bold, 
                                    fontFamily: "monospace",
                                    color: state.isRunning ? Colors.greenAccent : Colors.redAccent,
                                    shadows: [Shadow(color: state.isRunning ? Colors.green : Colors.red, blurRadius: 10)]
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!state.isRunning)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text("RELOJ DETENIDO", style: TextStyle(color: Colors.redAccent, fontSize: isWideScreen ? 11 : 9, fontWeight: FontWeight.w900, letterSpacing: 1), textAlign: TextAlign.center,),
                            ),
                          
                          SizedBox(height: isWideScreen ? 25 : 15),
                          
                          // FLECHAS DE POSESIÓN (AMARILLAS)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLargePossessionArrow(
                                isActive: state.possession == 'A', 
                                color: Colors.amber, 
                                icon: Icons.arrow_left_rounded,
                                size: arrowSize,
                                onTap: () => controller.setPossession('A')
                              ),
                              SizedBox(width: isWideScreen ? 15 : (isLandscape ? 4 : 8)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                                child: Text("POSS", style: TextStyle(color: Colors.white54, fontSize: isWideScreen ? 10 : 8, fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(width: isWideScreen ? 15 : (isLandscape ? 4 : 8)),
                              _buildLargePossessionArrow(
                                isActive: state.possession == 'B', 
                                color: Colors.amber, 
                                icon: Icons.arrow_right_rounded,
                                size: arrowSize,
                                onTap: () => controller.setPossession('B')
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  // EQUIPO B
                  Expanded(
                    flex: isWideScreen ? 1 : 2,
                    child: Column(
                      children: [
                        Text(widget.teamBName.toUpperCase(), style: nameStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: isWideScreen ? 10 : 4),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreB.toString().padLeft(2, '0'), style: scoreStyle)),
                        SizedBox(height: isWideScreen ? 12 : 8),
                        _buildTimeoutDots(state.teamBTimeouts1, state.teamBTimeouts2, Colors.lightBlueAccent, isWideScreen),
                         const SizedBox(height: 8),
                        _buildCompactFouls(controller.getTeamFouls('B'), Colors.lightBlueAccent, isWideScreen),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargePossessionArrow({required bool isActive, required Color color, required IconData icon, required double size, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? color : Colors.white10, width: 2),
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] : []
        ),
        child: Icon(
          icon,
          color: isActive ? color : Colors.white24,
          size: size, 
        ),
      ),
    );
  }

  Widget _buildTimeoutDots(List<String> t1, List<String> t2, Color activeColor, bool isWideScreen) {
    double dotSize = isWideScreen ? 14 : 10;
    return Wrap( 
      alignment: WrapAlignment.center,
      spacing: isWideScreen ? 6 : 4,
      runSpacing: 4,
      children: [
        for(int i=0; i<2; i++)
          Container(
            width: dotSize, height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: i < t1.length ? activeColor : Colors.white24,
              boxShadow: i < t1.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: 8)] : null
            ),
          ),
        SizedBox(width: isWideScreen ? 10 : 6),
        for(int i=0; i<3; i++)
          Container(
            width: dotSize, height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: i < t2.length ? activeColor : Colors.white24,
              boxShadow: i < t2.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: 8)] : null
            ),
          ),
      ],
    );
  }

  Widget _buildCompactFouls(int fouls, Color color, bool isWideScreen) {
    bool isPenalty = fouls >= 5;
    int displayFouls = fouls > 4 ? 4 : fouls;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 16 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPenalty ? Colors.redAccent.withOpacity(0.3) : Colors.white10,
        border: Border.all(color: isPenalty ? Colors.redAccent : Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(8)
      ),
      child: FittedBox( 
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("FALTAS: ", style: TextStyle(color: Colors.white70, fontSize: isWideScreen ? 12 : 10, fontWeight: FontWeight.bold)),
            Text(
              "$displayFouls", 
              style: TextStyle(
                color: isPenalty ? Colors.redAccent : Colors.white, 
                fontSize: isWideScreen ? 18 : 14, 
                fontWeight: FontWeight.w900,
                fontFamily: "monospace"
              )
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // LISTA DE JUGADORES (EFECTO GLASS DASHBOARD CARD)
  // =======================================================================
  Widget _buildTeamList(
    BuildContext context,
    String teamName,
    Color primaryColor,
    String teamId,
    List<String> onCourt,
    List<String> bench,
    MatchGameController controller,
    MatchState state,
    bool isWideScreen
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4), 
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(20)
          ),
          child: Column(
            children: [
              // CABECERA DE LA LISTA
              Container(
                padding: EdgeInsets.symmetric(vertical: isWideScreen ? 12 : 8, horizontal: isWideScreen ? 16 : 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  border: const Border(bottom: BorderSide(color: Colors.white24, width: 1))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Expanded(
                       child: Text("EN CANCHA", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: isWideScreen ? 13 : 11, letterSpacing: 1.0), overflow: TextOverflow.ellipsis),
                     ),
                     Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           onPressed: () => _showTeamOptions(context, controller, teamId, teamName),
                           icon: Icon(Icons.more_vert, color: primaryColor, size: isWideScreen ? 28 : 24),
                           tooltip: "Opciones de Equipo (Faltas, Tiempos)",
                           padding: EdgeInsets.zero,
                           constraints: const BoxConstraints(),
                         ),
                         SizedBox(width: isWideScreen ? 16 : 8),
                         InkWell(
                           onTap: () => _showSubstitutionDialog(context, teamId, onCourt, bench, controller),
                           borderRadius: BorderRadius.circular(20),
                           child: Icon(Icons.swap_horizontal_circle, color: primaryColor, size: isWideScreen ? 34 : 28),
                         )
                       ],
                     )
                  ],
                ),
              ),
              
              // JUGADORES
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(isWideScreen ? 12 : 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: onCourt.length,
                  separatorBuilder: (_, __) => SizedBox(height: isWideScreen ? 8 : 6),
                  itemBuilder: (context, index) {
                    final playerName = onCourt[index];
                    final stats = state.playerStats[playerName] ?? const PlayerStats();
                    bool isDisqualified = stats.fouls >= 5;

                    return InkWell(
                      onTap: () => _showActionMenu(context, teamId, playerName, controller, stats.fouls, isWideScreen),
                      onLongPress: () {
                        _showEditPlayerDialog(context, controller, playerName, stats.playerNumber, teamId);
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: isWideScreen ? 14 : 10, horizontal: isWideScreen ? 12 : 8),
                        decoration: BoxDecoration(
                          color: isDisqualified ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.08), 
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isDisqualified ? Colors.redAccent.withOpacity(0.5) : Colors.white12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isWideScreen ? 24 : 20,
                              backgroundColor: isDisqualified ? Colors.redAccent.withOpacity(0.3) : primaryColor.withOpacity(0.2),
                              child: Text(
                                stats.playerNumber.isNotEmpty ? stats.playerNumber : "#",
                                style: TextStyle(color: isDisqualified ? Colors.redAccent : primaryColor, fontWeight: FontWeight.w900, fontSize: isWideScreen ? 18 : 14),
                              ),
                            ),
                            SizedBox(width: isWideScreen ? 16 : 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(playerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWideScreen ? 16 : 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  SizedBox(height: isWideScreen ? 6 : 4),
                                  
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                                        child: Text("${stats.points} PTS", style: TextStyle(fontSize: isWideScreen ? 11 : 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                                      ),
                                      Wrap(
                                        spacing: 4,
                                        children: List.generate(5, (i) {
                                          Color dotColor = Colors.white24;
                                          if (i < stats.fouls) {
                                             dotColor = (i == 4) ? Colors.redAccent : Colors.orangeAccent;
                                          }
                                          return Container(
                                            width: isWideScreen ? 10 : 8, 
                                            height: isWideScreen ? 10 : 8,
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
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // DIÁLOGOS Y MENÚS INFERIORES
  // =======================================================================
  void _showEditPlayerDialog(BuildContext context, MatchGameController controller, String playerName, String currentNumber, String teamSide) {
    final numberController = TextEditingController(text: currentNumber);
    final errorNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        title: Text("Editar: $playerName", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Este cambio solo aplicará para el partido actual.", style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: errorNotifier,
              builder: (context, errorText, child) {
                return TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Número (Dorsal)",
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.format_list_numbered, color: Colors.white54),
                    errorText: errorText, 
                  ),
                  onChanged: (_) => errorNotifier.value = null,
                );
              }
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              final newNum = numberController.text.trim();
              if (newNum.isEmpty) { errorNotifier.value = "El número no puede estar vacío"; return; }
              if (_isNumberTaken(teamSide, newNum, playerName)) { errorNotifier.value = "El número $newNum ya está en uso"; return; }
              controller.updateMatchPlayerInfo(playerName, newNumber: newNum);
              Navigator.pop(ctx);
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF1A1F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView( 
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
                          const Text("REGISTRAR FALTA", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Text(playerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx))
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),

                _buildFoulSectionHeader("PERSONAL (P)", Icons.person, Colors.blueGrey.shade200),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildFoulChip(ctx, controller, teamId, playerName, "Lateral", "P", Colors.white10, Colors.white),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "P1", Colors.white10, Colors.white),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "P2", Colors.white10, Colors.white),
                    _buildFoulChip(ctx, controller, teamId, playerName, "3 Tiros", "P3", Colors.white10, Colors.white),
                  ],
                ),

                const SizedBox(height: 20),

                _buildFoulSectionHeader("CONDUCTA / GRAVES", Icons.warning_amber_rounded, Colors.orangeAccent),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildCompactCategoryLabel("TÉCNICA", Colors.orangeAccent),
                    _buildFoulChip(ctx, controller, teamId, playerName, "Simple", "T", Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent, isCompact: true),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "T1", Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent, isCompact: true),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "T2", Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent, isCompact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8, runSpacing: 8,
                  children: [
                    _buildCompactCategoryLabel("ANTIDEP.", Colors.deepOrangeAccent),
                    _buildFoulChip(ctx, controller, teamId, playerName, "Simple", "U", Colors.deepOrangeAccent.withOpacity(0.1), Colors.deepOrangeAccent, isCompact: true),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "U1", Colors.deepOrangeAccent.withOpacity(0.1), Colors.deepOrangeAccent, isCompact: true),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "U2", Colors.deepOrangeAccent.withOpacity(0.1), Colors.deepOrangeAccent, isCompact: true),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.redAccent))
                    ),
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: const FittedBox(fit: BoxFit.scaleDown, child: Text("DESCALIFICANTE (D)", style: TextStyle(fontWeight: FontWeight.bold))),
                    onPressed: () {
                      controller.updateStats(teamId, playerName, fouls: 5, foulType: "D");
                      Navigator.pop(ctx); 
                    },
                  ),
                )
              ],
            ),
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
        Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
      ],
    );
  }

  Widget _buildCompactCategoryLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFoulChip(BuildContext ctx, MatchGameController controller, String teamId, String playerName, String label, String typeCode, Color bgColor, Color textColor, {bool isCompact = false}) {
    return InkWell(
      onTap: () { controller.updateStats(teamId, playerName, fouls: 1, foulType: typeCode); Navigator.pop(ctx); },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isCompact ? null : 70, 
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 6, vertical: 10),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: textColor.withOpacity(0.3))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(typeCode, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
            if (!isCompact) ...[
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)), textAlign: TextAlign.center)),
            ]
          ],
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context, String teamId, String playerName, MatchGameController controller, int currentFouls, bool isWideScreen) {
    bool isDisqualified = currentFouls >= 5;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: const Color(0xFF0D1117).withOpacity(0.8),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(playerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    isDisqualified ? "JUGADOR DESCALIFICADO" : "Selecciona una acción", 
                    style: TextStyle(color: isDisqualified ? Colors.redAccent : Colors.white54, fontWeight: isDisqualified ? FontWeight.bold : FontWeight.normal),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  if (isDisqualified) ...[
                    const Icon(Icons.block, size: 50, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    const Text("No se pueden agregar más eventos a este jugador.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text("REALIZAR SUSTITUCIÓN AHORA"),
                        onPressed: () {
                          Navigator.pop(context); 
                          final currentState = ref.read(matchGameProvider);
                          final onCourt = teamId == 'A' ? currentState.teamAOnCourt : currentState.teamBOnCourt;
                          final bench = teamId == 'A' ? currentState.teamABench : currentState.teamBBench;
                          _showSubstitutionDialog(context, teamId, onCourt, bench, controller, preSelectedOut: playerName);
                        },
                      ),
                    )
                  ] else
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatButton("+1", Colors.lightBlueAccent, () { controller.updateStats(teamId, playerName, points: 1); Navigator.pop(context); }, isWideScreen),
                        _buildStatButton("+2", Colors.greenAccent, () { controller.updateStats(teamId, playerName, points: 2); Navigator.pop(context); }, isWideScreen),
                        _buildStatButton("+3", Colors.orangeAccent, () { controller.updateStats(teamId, playerName, points: 3); Navigator.pop(context); }, isWideScreen),
                        _buildStatButton("Falta", Colors.redAccent, () { Navigator.pop(context); _showFoulOptionsDialog(context, controller, teamId, playerName); }, isWideScreen, icon: Icons.error_outline),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatButton(String label, Color color, VoidCallback onTap, bool isWideScreen, {IconData? icon}) {
    double btnSize = isWideScreen ? 80 : 70; 
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: btnSize, height: btnSize,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: color, size: isWideScreen ? 28 : 24)
            else Text(label, style: TextStyle(fontSize: isWideScreen ? 24 : 20, fontWeight: FontWeight.bold, color: color)),
            if (icon != null) Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))
          ],
        ),
      ),
    );
  }

  void _showTeamOptions(BuildContext context, MatchGameController controller, String teamId, String teamName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: const Color(0xFF0D1117).withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Opciones: $teamName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.timer_outlined, color: Colors.white)),
                  title: const Text("Solicitar Tiempo Fuera", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () { controller.addTimeout(teamId); Navigator.pop(context); },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.sports, color: Colors.orangeAccent)),
                  title: const Text("Falta Técnica al Entrenador (C)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () { controller.addTeamFoul(teamId, 'C'); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta al Coach (C) registrada"))); },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.chair, color: Colors.lightBlueAccent)),
                  title: const Text("Falta Técnica a la Banca (B)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () { controller.addTeamFoul(teamId, 'B'); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta a la Banca (B) registrada"))); },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubstitutionDialog(BuildContext context, String teamId, List<String> onCourt, List<String> bench, MatchGameController controller, {String? preSelectedOut}) {
    String? selectedOut = preSelectedOut; 
    String? selectedIn;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2B),
          title: const Text("Sustitución", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdown("Sale (Cancha)", onCourt, selectedOut, (v) => setState(() => selectedOut = v)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Icon(Icons.arrow_downward, color: Colors.orangeAccent)),
              _dropdown("Entra (Banca)", bench, selectedIn, (v) => setState(() => selectedIn = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent),
              onPressed: (selectedOut != null && selectedIn != null) ? () { controller.substitutePlayer(teamId, selectedOut!, selectedIn!); Navigator.pop(context); } : null,
              child: const Text("Confirmar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String? val, Function(String?) changed) {
    return Theme(
      data: ThemeData.dark(),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), border: const OutlineInputBorder(), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            isDense: true,
            isExpanded: true,
            dropdownColor: const Color(0xFF2C323F),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: changed,
          ),
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, MatchGameController controller, Duration currentTime) {
    int selectedMinute = currentTime.inMinutes;
    int selectedSecond = currentTime.inSeconds % 60;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2B),
      builder: (_) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))),
                 const Text("Ajustar Reloj", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                 TextButton(onPressed: () { controller.setTime(Duration(minutes: selectedMinute, seconds: selectedSecond)); Navigator.pop(context); }, child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
             ]),
             const SizedBox(height: 20),
             Expanded(
                 child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                     SizedBox(width: 70, child: ListWheelScrollView.useDelegate(itemExtent: 50, controller: FixedExtentScrollController(initialItem: selectedMinute), physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (v) => selectedMinute = v, childDelegate: ListWheelChildBuilderDelegate(childCount: 100, builder: (c,i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 30, color: Colors.white)))))),
                     const Text(":", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                     SizedBox(width: 70, child: ListWheelScrollView.useDelegate(itemExtent: 50, controller: FixedExtentScrollController(initialItem: selectedSecond), physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (v) => selectedSecond = v, childDelegate: ListWheelChildBuilderDelegate(childCount: 60, builder: (c,i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 30, color: Colors.white)))))),
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
          backgroundColor: const Color(0xFF1A1F2B),
          title: const Text("¿Salir?", style: TextStyle(color: Colors.white)),
          content: const Text("El partido continuará guardado localmente.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () { Navigator.pop(ctx); Navigator.of(context).popUntil((r) => r.isFirst); }, child: const Text("Salir", style: TextStyle(color: Colors.white))),
          ],
        ),
      );
  }

  void _finishMatchProcess(BuildContext context, MatchState state, Uint8List? signature, {bool autoShow = true}) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)));
    try {
      final api = ref.read(apiServiceProvider);
      final controller = ref.read(matchGameProvider.notifier);

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

      bool synced = await controller.finalizeAndSync(api, signature, pdfBytes, widget.teamAName, widget.teamBName);

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
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
        backgroundColor: const Color(0xFF1A1F2B),
        title: const Text("Finalizar Partido", style: TextStyle(color: Colors.white)),
        content: const Text("¿Cómo deseas proceder con el acta?", style: TextStyle(color: Colors.white70)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          OutlinedButton.icon(
              icon: const Icon(Icons.edit_document, color: Colors.redAccent), 
              label: const Text("Firmar Bajo Protesta", style: TextStyle(color: Colors.redAccent)), 
              onPressed: () { Navigator.pop(ctx); _handleProtestFlow(context, currentState); }
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent),
              icon: const Icon(Icons.check_circle, color: Colors.black), 
              label: const Text("Finalizar y Sincronizar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
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
        backgroundColor: const Color(0xFF1A1F2B),
        title: const Text("Seleccionar Periodo", style: TextStyle(color: Colors.white)),
        children: [
          _periodOption(context, controller, 1, "Periodo 1"),
          _periodOption(context, controller, 2, "Periodo 2"),
          _periodOption(context, controller, 3, "Periodo 3"),
          _periodOption(context, controller, 4, "Periodo 4"),
          const Divider(color: Colors.white24),
          _periodOption(context, controller, 5, "Tiempo Extra 1"),
          _periodOption(context, controller, 6, "Tiempo Extra 2"),
        ],
      ),
    );
  }

  Widget _periodOption(BuildContext context, MatchGameController controller, int period, String label) {
    return SimpleDialogOption(
      onPressed: () { controller.setPeriod(period); Navigator.pop(context); },
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(label, style: const TextStyle(color: Colors.white70))),
    );
  }

  Future<void> _handleProtestFlow(BuildContext context, MatchState state) async {
    final String? protestingTeam = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        title: const Text("¿Quién protesta?", style: TextStyle(color: Colors.white)),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, widget.teamAName), child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.teamAName, style: const TextStyle(fontSize: 16, color: Colors.orangeAccent)))),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, widget.teamBName), child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.teamBName, style: const TextStyle(fontSize: 16, color: Colors.lightBlueAccent)))),
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