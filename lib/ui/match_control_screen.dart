// lib/ui/screens/match_control_screen.dart
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
import '../ui/widgets/app_background.dart';

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
      ref
          .read(matchGameProvider.notifier)
          .initializeNewMatch(
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
    });
  }

  bool _isNumberTaken(
    String teamSide,
    String newNumber,
    String currentPlayerName,
  ) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Límite de Faltas",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              content: Text(
                "El jugador $playerId ha llegado a 5 faltas y debe ser sustituido.",
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Entendido"),
                ),
              ],
            ),
          );
        }
      });

      if ((previous?.timeLeft.inSeconds ?? 1) > 0 &&
          next.timeLeft.inSeconds == 0) {
        bool isRegularTimeOver = next.currentPeriod >= 4;
        String title = !isRegularTimeOver
            ? "Fin del Periodo ${next.currentPeriod}"
            : (next.scoreA == next.scoreB ? "¡EMPATE!" : "Fin del Partido");
        String content = !isRegularTimeOver
            ? "¿Iniciar Periodo ${next.currentPeriod + 1}?"
            : (next.scoreA == next.scoreB
                  ? "¿Iniciar Tiempo Extra?"
                  : "Marcador Final: ${next.scoreA} - ${next.scoreB}");
        String btnText = !isRegularTimeOver
            ? "Siguiente"
            : (next.scoreA == next.scoreB ? "Tiempo Extra" : "Finalizar");

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(content, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Revisar"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
                onPressed: () {
                  action();
                  Navigator.pop(context);
                },
                child: Text(
                  btnText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true, // Cristal effect
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text(
          "Mesa de Control",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(
          0.5,
        ), // Appbar oscuro semi-transparente
        elevation: 0,
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
            onPressed: () =>
                _goToPdfPreview(context, gameState, _capturedSignature),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.greenAccent),
            tooltip: "Guardar",
            onPressed: () =>
                _finishMatchProcess(context, gameState, _capturedSignature),
          ),
        ],
      ),

      body: AppBackground(
        opacity:
            0.65, // Oscurecer el fondo para alto contraste de la mesa de control
        child: SafeArea(
          child: Column(
            children: [
              // 1. MARCADOR PRINCIPAL
              _buildProfessionalScoreboard(context, gameState, controller),

              // 2. LISTAS DE JUGADORES
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- EQUIPO A ---
                    Expanded(
                      child: _buildTeamList(
                        context,
                        widget.teamAName,
                        Colors.orangeAccent,
                        'A',
                        gameState.teamAOnCourt,
                        gameState.teamABench,
                        controller,
                        gameState,
                      ),
                    ),

                    // DIVISOR CENTRAL CON ESTILO
                    Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),

                    // --- EQUIPO B ---
                    Expanded(
                      child: _buildTeamList(
                        context,
                        widget.teamBName,
                        Colors.lightBlueAccent,
                        'B',
                        gameState.teamBOnCourt,
                        gameState.teamBBench,
                        controller,
                        gameState,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTE: MARCADOR (SCOREBOARD) ---
  Widget _buildProfessionalScoreboard(
    BuildContext context,
    MatchState state,
    MatchGameController controller,
  ) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // PERIODO INDICADOR
              GestureDetector(
                onTap: () => _showPeriodSelector(context, controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    state.currentPeriod <= 4
                        ? "PERIODO ${state.currentPeriod}"
                        : "TIEMPO EXTRA ${state.currentPeriod - 4}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SCORE A
                  Expanded(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showTeamOptions(
                            context,
                            controller,
                            'A',
                            widget.teamAName,
                          ),
                          child: Text(
                            widget.teamAName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.orangeAccent,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            state.scoreA.toString(),
                            style: const TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        _buildTimeoutDots(
                          state.teamATimeouts1,
                          state.teamATimeouts2,
                          Colors.orangeAccent,
                        ),
                        const SizedBox(height: 8),
                        _buildCompactFouls(
                          controller.getTeamFouls('A'),
                          Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),

                  // RELOJ Y POSESIÓN
                  Expanded(
                    flex: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: controller.toggleTimer,
                            onLongPress: () => !state.isRunning
                                ? _showTimePicker(
                                    context,
                                    controller,
                                    state.timeLeft,
                                  )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: state.isRunning
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (state.isRunning)
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: Text(
                                "$minutes:$seconds",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "monospace",
                                  color: state.isRunning
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                          if (!state.isRunning)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                "PAUSADO",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),

                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLargePossessionArrow(
                                isActive: state.possession == 'A',
                                color: Colors.orangeAccent,
                                icon: Icons.arrow_left_rounded,
                                onTap: () => controller.setPossession('A'),
                              ),
                              const SizedBox(width: 8),
                              _buildLargePossessionArrow(
                                isActive: state.possession == 'B',
                                color: Colors.lightBlueAccent,
                                icon: Icons.arrow_right_rounded,
                                onTap: () => controller.setPossession('B'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SCORE B
                  Expanded(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showTeamOptions(
                            context,
                            controller,
                            'B',
                            widget.teamBName,
                          ),
                          child: Text(
                            widget.teamBName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.lightBlueAccent,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            state.scoreB.toString(),
                            style: const TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        _buildTimeoutDots(
                          state.teamBTimeouts1,
                          state.teamBTimeouts2,
                          Colors.lightBlueAccent,
                        ),
                        const SizedBox(height: 8),
                        _buildCompactFouls(
                          controller.getTeamFouls('B'),
                          Colors.lightBlueAccent,
                        ),
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

  Widget _buildLargePossessionArrow({
    required bool isActive,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : Colors.transparent),
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? color : Colors.white30,
          size: 50, // Ajustado para que encaje mejor visualmente
        ),
      ),
    );
  }

  Widget _buildTimeoutDots(
    List<String> t1,
    List<String> t2,
    Color activeColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 2; i++)
          Container(
            margin: const EdgeInsets.all(2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < t1.length ? activeColor : Colors.white24,
            ),
          ),
        const SizedBox(width: 6),
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.all(2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < t2.length ? activeColor : Colors.white24,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactFouls(int fouls, Color color) {
    bool isPenalty = fouls >= 5;
    int displayFouls = fouls > 4 ? 4 : fouls;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPenalty ? Colors.redAccent.withOpacity(0.2) : Colors.black45,
        border: Border.all(
          color: isPenalty ? Colors.redAccent : Colors.white24,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "FALTAS: $displayFouls",
        style: TextStyle(
          color: isPenalty ? Colors.redAccent : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // --- COMPONENTE: LISTA DE JUGADORES EN CANCHA ---
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
        // Encabezado de la lista
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.black.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "EN CANCHA",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              InkWell(
                onTap: () => _showSubstitutionDialog(
                  context,
                  teamId,
                  onCourt,
                  bench,
                  controller,
                ),
                child: Icon(
                  Icons.change_circle_outlined,
                  color: primaryColor,
                  size: 28,
                ),
              ),
            ],
          ),
        ),

        // Lista de Jugadores
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: onCourt.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final playerName = onCourt[index];
              final stats =
                  state.playerStats[playerName] ?? const PlayerStats();
              bool isDisqualified = stats.fouls >= 5;

              return InkWell(
                onTap: () => _showActionMenu(
                  context,
                  teamId,
                  playerName,
                  controller,
                  stats.fouls,
                ),
                onLongPress: () {
                  _showEditPlayerDialog(
                    context,
                    controller,
                    playerName,
                    stats.playerNumber,
                    teamId,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDisqualified
                            ? Colors.red.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDisqualified
                              ? Colors.redAccent
                              : Colors.white24,
                          width: isDisqualified ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Número del Jugador
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDisqualified
                                  ? Colors.redAccent.withOpacity(0.2)
                                  : primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDisqualified
                                    ? Colors.redAccent
                                    : primaryColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                stats.playerNumber.isNotEmpty
                                    ? stats.playerNumber
                                    : "#",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Nombre y Estadísticas (Pts / Faltas)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDisqualified
                                        ? Colors.red.shade100
                                        : Colors.white,
                                    decoration: isDisqualified
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "${stats.points} PTS",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: List.generate(5, (i) {
                                        Color dotColor = Colors.white24;
                                        if (i < stats.fouls) {
                                          dotColor = (i == 4)
                                              ? Colors.redAccent
                                              : Colors.orangeAccent;
                                        }
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: dotColor,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- RESTO DE LAS FUNCIONES (Mantenidas y estilizadas) ---

  void _showEditPlayerDialog(
    BuildContext context,
    MatchGameController controller,
    String playerName,
    String currentNumber,
    String teamSide,
  ) {
    final numberController = TextEditingController(text: currentNumber);
    final errorNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Editar: $playerName",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  decoration: InputDecoration(
                    labelText: "Número (Dorsal)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    errorText: errorText,
                  ),
                  onChanged: (_) => errorNotifier.value = null,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
            child: const Text(
              "Guardar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showFoulOptionsDialog(
    BuildContext context,
    MatchGameController controller,
    String teamId,
    String playerName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                        const Text(
                          "REGISTRAR FALTA",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          playerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),

              _buildFoulSectionHeader(
                "PERSONAL (P)",
                Icons.person,
                Colors.blueGrey,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFoulChip(
                    ctx,
                    controller,
                    teamId,
                    playerName,
                    "Lateral",
                    "P",
                    Colors.blueGrey.shade50,
                    Colors.blueGrey.shade800,
                  ),
                  _buildFoulChip(
                    ctx,
                    controller,
                    teamId,
                    playerName,
                    "1 Tiro",
                    "P1",
                    Colors.blueGrey.shade50,
                    Colors.blueGrey.shade800,
                  ),
                  _buildFoulChip(
                    ctx,
                    controller,
                    teamId,
                    playerName,
                    "2 Tiros",
                    "P2",
                    Colors.blueGrey.shade50,
                    Colors.blueGrey.shade800,
                  ),
                  _buildFoulChip(
                    ctx,
                    controller,
                    teamId,
                    playerName,
                    "3 Tiros",
                    "P3",
                    Colors.blueGrey.shade50,
                    Colors.blueGrey.shade800,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildFoulSectionHeader(
                "CONDUCTA / GRAVES",
                Icons.warning_amber_rounded,
                Colors.orange.shade800,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactCategoryLabel("TÉCNICA", Colors.orange),
                    const SizedBox(width: 8),
                    _buildFoulChip(
                      ctx,
                      controller,
                      teamId,
                      playerName,
                      "Simple",
                      "T",
                      Colors.orange.shade50,
                      Colors.orange.shade900,
                      isCompact: true,
                    ),
                    const SizedBox(width: 6),
                    _buildFoulChip(
                      ctx,
                      controller,
                      teamId,
                      playerName,
                      "1 Tiro",
                      "T1",
                      Colors.orange.shade50,
                      Colors.orange.shade900,
                      isCompact: true,
                    ),
                    const SizedBox(width: 6),
                    _buildFoulChip(
                      ctx,
                      controller,
                      teamId,
                      playerName,
                      "2 Tiros",
                      "T2",
                      Colors.orange.shade50,
                      Colors.orange.shade900,
                      isCompact: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactCategoryLabel("ANTIDEP.", Colors.deepOrange),
                    const SizedBox(width: 8),
                    _buildFoulChip(
                      ctx,
                      controller,
                      teamId,
                      playerName,
                      "Simple",
                      "U",
                      Colors.deepOrange.shade50,
                      Colors.deepOrange.shade900,
                      isCompact: true,
                    ),
                    const SizedBox(width: 6),
                    _buildFoulChip(
                      ctx,
                      controller,
                      teamId,
                      playerName,
                      "1 Tiro",
                      "U1",
                      Colors.deepOrange.shade50,
                      Colors.deepOrange.shade900,
                      isCompact: true,
                    ),
                    const SizedBox(width: 6),
                    _buildFoulChip(
                      ctx,
                      controller,
                      teamId,
                      playerName,
                      "2 Tiros",
                      "U2",
                      Colors.deepOrange.shade50,
                      Colors.deepOrange.shade900,
                      isCompact: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade800,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                  icon: const Icon(Icons.gavel_rounded, size: 20),
                  label: const Text(
                    "DESCALIFICANTE (D)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  onPressed: () {
                    controller.updateStats(
                      teamId,
                      playerName,
                      fouls: 5,
                      foulType: "D",
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoulSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCategoryLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
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
    Color textColor, {
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: () {
        controller.updateStats(
          teamId,
          playerName,
          fouls: 1,
          foulType: typeCode,
        );
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: isCompact ? null : 80,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              typeCode,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showActionMenu(
    BuildContext context,
    String teamId,
    String playerName,
    MatchGameController controller,
    int currentFouls,
  ) {
    bool isDisqualified = currentFouls >= 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Para efecto cristal
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2B), // Azul muy oscuro para el modal
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                playerName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isDisqualified
                    ? "JUGADOR EXPULSADO (5 FALTAS)"
                    : "Selecciona una acción a registrar",
                style: TextStyle(
                  color: isDisqualified ? Colors.redAccent : Colors.white54,
                  fontWeight: isDisqualified
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 30),

              if (isDisqualified) ...[
                const Icon(Icons.block, size: 60, color: Colors.redAccent),
                const SizedBox(height: 15),
                const Text(
                  "No se pueden agregar más estadísticas a este jugador. Debe ser sustituido.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text(
                      "REALIZAR SUSTITUCIÓN AHORA",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final currentState = ref.read(matchGameProvider);
                      final onCourt = teamId == 'A'
                          ? currentState.teamAOnCourt
                          : currentState.teamBOnCourt;
                      final bench = teamId == 'A'
                          ? currentState.teamABench
                          : currentState.teamBBench;

                      _showSubstitutionDialog(
                        context,
                        teamId,
                        onCourt,
                        bench,
                        controller,
                        preSelectedOut: playerName,
                      );
                    },
                  ),
                ),
              ] else
                // --- BOTONES DE ACCIÓN MEJORADOS ---
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatButton("+1", Colors.lightBlueAccent, () {
                      controller.updateStats(teamId, playerName, points: 1);
                      Navigator.pop(context);
                    }),
                    _buildStatButton("+2", Colors.greenAccent, () {
                      controller.updateStats(teamId, playerName, points: 2);
                      Navigator.pop(context);
                    }),
                    _buildStatButton("+3", Colors.orangeAccent, () {
                      controller.updateStats(teamId, playerName, points: 3);
                      Navigator.pop(context);
                    }),
                    _buildStatButton("Falta", Colors.redAccent, () {
                      Navigator.pop(context);
                      _showFoulOptionsDialog(
                        context,
                        controller,
                        teamId,
                        playerName,
                      );
                    }, icon: Icons.sports),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatButton(
    String label,
    Color color,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: color.withOpacity(0.3),
      child: Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: color, size: 30)
            else
              Text(
                label,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            if (icon != null) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTeamOptions(
    BuildContext context,
    MatchGameController controller,
    String teamId,
    String teamName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Opciones de: ${teamName.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white10,
                leading: const Icon(
                  Icons.timer_outlined,
                  color: Colors.lightBlueAccent,
                ),
                title: const Text(
                  "Solicitar Tiempo Fuera",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  controller.addTimeout(teamId);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white10,
                leading: const Icon(Icons.sports, color: Colors.orangeAccent),
                title: const Text(
                  "Falta Técnica Entrenador (C)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  controller.addTeamFoul(teamId, 'C');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Falta al Coach (C) registrada"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white10,
                leading: const Icon(Icons.chair, color: Colors.redAccent),
                title: const Text(
                  "Falta Técnica Banca (B)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  controller.addTeamFoul(teamId, 'B');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Falta a la Banca (B) registrada"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubstitutionDialog(
    BuildContext context,
    String teamId,
    List<String> onCourt,
    List<String> bench,
    MatchGameController controller, {
    String? preSelectedOut,
  }) {
    String? selectedOut = preSelectedOut;
    String? selectedIn;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.change_circle, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Sustitución",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdown(
                "Sale a la banca",
                onCourt,
                selectedOut,
                (v) => setState(() => selectedOut = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              _dropdown(
                "Entra a la cancha",
                bench,
                selectedIn,
                (v) => setState(() => selectedIn = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (selectedOut != null && selectedIn != null)
                  ? () {
                      controller.substitutePlayer(
                        teamId,
                        selectedOut!,
                        selectedIn!,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text(
                "Confirmar Cambio",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? val,
    Function(String?) changed,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isDense: true,
          isExpanded: true,
          hint: const Text("Seleccionar jugador"),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: changed,
        ),
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    MatchGameController controller,
    Duration currentTime,
  ) {
    int selectedMinute = currentTime.inMinutes;
    int selectedSecond = currentTime.inSeconds % 60;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const Text(
                  "Ajustar Reloj",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.setTime(
                      Duration(
                        minutes: selectedMinute,
                        seconds: selectedSecond,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Guardar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      controller: FixedExtentScrollController(
                        initialItem: selectedMinute,
                      ),
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (v) => selectedMinute = v,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 100,
                        builder: (c, i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    ":",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      controller: FixedExtentScrollController(
                        initialItem: selectedSecond,
                      ),
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (v) => selectedSecond = v,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 60,
                        builder: (c, i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "¿Salir del partido?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "El progreso del partido se mantendrá guardado en este dispositivo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text("Salir"),
          ),
        ],
      ),
    );
  }

  void _finishMatchProcess(
    BuildContext context,
    MatchState state,
    Uint8List? signature, {
    bool autoShow = true,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      ),
    );
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

      bool synced = await controller.finalizeAndSync(
        api,
        signature,
        pdfBytes,
        widget.teamAName,
        widget.teamBName,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced
                  ? "✅ Sincronizado correctamente en la nube"
                  : "💾 Guardado localmente (Sin conexión)",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: synced
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
        );
        if (autoShow) _goToPdfPreview(context, state, signature);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        if (autoShow) _goToPdfPreview(context, state, signature);
      }
    }
  }

  void _goToPdfPreview(
    BuildContext context,
    MatchState state,
    Uint8List? signature,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          state: state,
          teamAName: widget.teamAName,
          teamBName: widget.teamBName,
          tournamentName: widget.tournamentName,
          venueName: widget.venueName,
          mainReferee: widget.mainReferee,
          auxReferee: widget.auxReferee,
          scorekeeper: widget.scorekeeper,
          coachA: widget.coachA,
          coachB: widget.coachB,
          captainAId: widget.captainAId,
          captainBId: widget.captainBId,
          matchDate: widget.matchDate,
          protestSignature: signature,
        ),
      ),
    );
  }

  void _showFinalOptionsDialog(BuildContext context, MatchState currentState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "🏁 Finalizar Partido",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Cómo deseas proceder con el acta oficial del juego?",
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.edit_document, color: Colors.redAccent),
            label: const Text(
              "Firmar Bajo Protesta",
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleProtestFlow(context, currentState);
            },
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text(
              "Finalizar y Sincronizar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _finishMatchProcess(context, currentState, null);
            },
          ),
        ],
      ),
    );
  }

  void _showPeriodSelector(
    BuildContext context,
    MatchGameController controller,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Seleccionar Periodo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _periodOption(
    BuildContext context,
    MatchGameController controller,
    int period,
    String label,
  ) {
    return InkWell(
      onTap: () {
        controller.setPeriod(period);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _handleProtestFlow(
    BuildContext context,
    MatchState state,
  ) async {
    final String? protestingTeam = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "¿Qué equipo protesta?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: Colors.orange.shade50,
              title: Text(
                widget.teamAName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              onTap: () => Navigator.pop(ctx, widget.teamAName),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: Colors.blue.shade50,
              title: Text(
                widget.teamBName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              onTap: () => Navigator.pop(ctx, widget.teamBName),
            ),
          ],
        ),
      ),
    );

    if (protestingTeam != null && context.mounted) {
      final Uint8List? signature = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProtestSignatureScreen(teamName: protestingTeam),
        ),
      );
      if (signature != null && context.mounted) {
        setState(() => _capturedSignature = signature);
        _finishMatchProcess(context, state, signature, autoShow: false);
      }
    }
  }
}
