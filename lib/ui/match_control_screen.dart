// ignore_for_file: deprecated_member_use

import 'dart:ui' hide Display; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_presentation_display/display.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_presentation_display/flutter_presentation_display.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:convert';

import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart';
import '../core/utils/pdf_generator.dart';
import '../logic/match_game_controller.dart';
import '../ui/protest_signature_screen.dart';
import '../ui/pdf_preview_screen.dart';
import '../core/database/app_database.dart' as db;
import '../core/network/websocket_server.dart'; 

import '../ui/widgets/app_background.dart';
import '../ui/widgets/scoreboard_widget.dart';

class MatchControlScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String? fixtureId;
  final String teamAName;
  final String teamBName;
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;
  final String tournamentName;
  final String categoryName;
  final String tournamentLogoUrl;
  final String refereeLogoUrl;
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
    required this.categoryName,
    required this.tournamentLogoUrl,
    required this.refereeLogoUrl,
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
  bool _isFinished = false;
  String _localIp = "Buscando IP...";
  final FlutterPresentationDisplay _displayManager = FlutterPresentationDisplay();

  // --- VARIABLES PARA ALMACENAR EL NOMBRE DEL CAPITÁN RÁPIDAMENTE ---
  String? _captainAName;
  String? _captainBName;
  String? _playerToSubstituteId; // Guarda el nombre del jugador que inició el cambio
  String? _teamOfSubstitution;  // Guarda el equipo 'A' o 'B'

  @override
  void initState() {
    super.initState();
    
    if (widget.captainAId != null) {
      final capA = widget.fullRosterA.where((p) => p.id == widget.captainAId).firstOrNull;
      _captainAName = capA?.name;
    }
    if (widget.captainBId != null) {
      final capB = widget.fullRosterB.where((p) => p.id == widget.captainBId).firstOrNull;
      _captainBName = capB?.name;
    }

    LocalWebSocketServer.instance.startServer();
    _checkExternalDisplays(); 
    _fetchLocalIp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final oldState = ref.read(matchGameProvider);

      if (oldState.matchId != widget.matchId) {
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
      
      final newState = ref.read(matchGameProvider);
      _broadcastFastUpdate(newState, ref.read(matchGameProvider.notifier));
    });
  }

  void _broadcastFastUpdate(MatchState state, MatchGameController controller) {
    try {
      final payload = jsonEncode({
        "state": state.toJson(),
        "teamAName": widget.teamAName,
        "teamBName": widget.teamBName,
        "teamAFouls": controller.getTeamFouls('A'),
        "teamBFouls": controller.getTeamFouls('B'),
      });
      LocalWebSocketServer.instance.broadcast(payload);
    } catch (e) {
      debugPrint("Error broadcast: $e");
    }
  }

  @override
  void dispose() {
    _closeExternalDisplay(); 
    super.dispose();
  }

  Future<void> _fetchLocalIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (mounted) {
        setState(() => _localIp = ip ?? "IP no disponible");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _localIp = "Error de red");
      }
    }
  }

  Future<void> _checkExternalDisplays() async {
    try {
      List<Display>? displays = await _displayManager.getDisplays();
      
      if (displays != null && displays.length > 1) {
        final displayId = displays[1].displayId;
        
        if (displayId != null) {
          debugPrint("Pantalla secundaria detectada: $displayId");
          await _displayManager.showSecondaryDisplay(
            displayId: displayId,
            routerName: "presentation_scoreboard", 
          );
        }
      }
    } catch (e) {
      debugPrint("No se pudo iniciar la pantalla externa: $e");
    }
  }

  Future<void> _closeExternalDisplay() async {
    try {
      List<Display>? displays = await _displayManager.getDisplays();
      if (displays != null && displays.length > 1) {
        final displayId = displays[1].displayId;
        if (displayId != null) {
          await _displayManager.hideSecondaryDisplay(displayId: displayId);
        }
      }
    } catch (e) {
      debugPrint("Error cerrando pantalla: $e");
    }
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

  List<String> _sortPlayersByNumberDesc(List<String> playerNames, MatchState state) {
    List<String> sortedList = List.from(playerNames);
    sortedList.sort((a, b) {
      final numA = int.tryParse(state.playerStats[a]?.playerNumber ?? "0") ?? 0;
      final numB = int.tryParse(state.playerStats[b]?.playerNumber ?? "0") ?? 0;
      return numB.compareTo(numA); 
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final controller = ref.read(matchGameProvider.notifier);

    ref.listen<MatchState>(matchGameProvider, (previous, next) {
      _broadcastFastUpdate(next, controller);

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
                  if (context.mounted && !_isFinished) _showFinalOptionsDialog(context, next);
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

    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _isFinished ? "PARTIDO FINALIZADO" : "CONTROL DE JUEGO", 
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 16, color: _isFinished ? Colors.redAccent : Colors.white)
            ),
            Text("IP Tablero: $_localIp", style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5), 
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.undo), tooltip: "Deshacer", onPressed: _isFinished ? null : controller.undo),
          IconButton(icon: const Icon(Icons.visibility_outlined), tooltip: "Ver Acta", onPressed: () => _goToPdfPreview(context, gameState, _capturedSignature)),
          IconButton(icon: const Icon(Icons.save_alt), tooltip: "Finalizar Partido", onPressed: _isFinished ? null : () => _showFinalOptionsDialog(context, gameState)),
        ],
      ),
      body: AppBackground(
        opacity: 0.6, 
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 750;
            
            final sortedCourtA = _sortPlayersByNumberDesc(gameState.teamAOnCourt, gameState);
            final sortedCourtB = _sortPlayersByNumberDesc(gameState.teamBOnCourt, gameState);

            Widget teamAWidget = Expanded(child: _buildTeamList(context, widget.teamAName, Colors.orangeAccent, 'A', sortedCourtA, gameState.teamABench, controller, gameState, isWideScreen));
            Widget teamBWidget = Expanded(child: _buildTeamList(context, widget.teamBName, Colors.lightBlueAccent, 'B', sortedCourtB, gameState.teamBBench, controller, gameState, isWideScreen));

            Widget scoreboardView = ScoreboardWidget(
              state: gameState,
              controller: controller,
              teamAName: widget.teamAName,
              teamBName: widget.teamBName,
              teamAFouls: controller.getTeamFouls('A'),
              teamBFouls: controller.getTeamFouls('B'),
              isFinished: _isFinished,
              onPeriodTap: () => _showPeriodSelector(context, controller),
              onTimeLongPress: () => _showTimePicker(context, controller, gameState.timeLeft),
            );

            return SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isLandscape 
                    ? Row(
                        children: [
                          Expanded(flex: 4, child: SingleChildScrollView(child: scoreboardView)),
                          Expanded(
                            flex: 6,
                            child: Container(
                              margin: EdgeInsets.all(isWideScreen ? 12.0 : 6.0),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [teamAWidget, SizedBox(width: isWideScreen ? 12 : 6), teamBWidget]),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          scoreboardView,
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(isWideScreen ? 12.0 : 6.0),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [teamAWidget, SizedBox(width: isWideScreen ? 12 : 6), teamBWidget]),
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

  Widget _buildTeamList(
  BuildContext context,
  String teamName,
  Color primaryColor,
  String teamId,
  List<String> onCourt,
  List<String> bench,
  MatchGameController controller,
  MatchState state,
  bool isWideScreen,
) {
  final sortedCourt = _sortPlayersByNumberDesc(onCourt, state);
  final sortedBench = _sortPlayersByNumberDesc(bench, state);

  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: isWideScreen ? 12 : 8, horizontal: 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                border: const Border(bottom: BorderSide(color: Colors.white24, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(teamName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    onPressed: _isFinished ? null : () => _showTeamOptions(context, controller, teamId, teamName),
                    icon: Icon(Icons.settings_outlined, color: primaryColor, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildListSectionHeader("EN CANCHA", primaryColor),
                  ...sortedCourt.map((p) => _buildPlayerRow(context, p, teamId, primaryColor, true, controller, state, isWideScreen, onCourt)),
                  const SizedBox(height: 16),
                  _buildListSectionHeader("BANCA", Colors.white38),
                  ...sortedBench.map((p) => _buildPlayerRow(context, p, teamId, Colors.white30, false, controller, state, isWideScreen, onCourt)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // Widget auxiliar para las cabeceras de sección dentro de la lista
  Widget _buildListSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withOpacity(0.2), height: 1)),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
  BuildContext context,
  String playerName,
  String teamId,
  Color color,
  bool isOnCourt,
  MatchGameController controller,
  MatchState state,
  bool isWideScreen,
  List<String> playersOnCourt, // <--- 1. Recibimos la lista aquí
) {
  final stats = state.playerStats[playerName] ?? const PlayerStats();
  final bool isDisqualified = stats.fouls >= 5;
  final bool isCaptain = (teamId == 'A' && playerName == _captainAName) ||
      (teamId == 'B' && playerName == _captainBName);
  final bool isSelectedForSwap = _playerToSubstituteId == playerName;

  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: InkWell(
      onLongPress: _isFinished ? null : () {
        setState(() {
          _playerToSubstituteId = playerName;
          _teamOfSubstitution = teamId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seleccionado para cambio"), duration: Duration(seconds: 1))
        );
      },
      onTap: () {
        if (_playerToSubstituteId != null && _teamOfSubstitution == teamId) {
          if (_playerToSubstituteId != playerName) {
            
            // 2. CORRECCIÓN LÓGICA: Verificar estados para evitar duplicados
            // Comprobamos si el jugador seleccionado previamente estaba en cancha
            bool selectionWasOnCourt = playersOnCourt.contains(_playerToSubstituteId);
            bool targetIsOnCourt = isOnCourt;

            // SOLO permitimos el cambio si uno está en banca y el otro en cancha
            if (selectionWasOnCourt != targetIsOnCourt) {
              String pOut = targetIsOnCourt ? playerName : _playerToSubstituteId!;
              String pIn = targetIsOnCourt ? _playerToSubstituteId! : playerName;
              controller.substitutePlayer(teamId, pOut, pIn);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Selecciona un jugador de banca y uno de cancha"))
              );
            }
          }
          setState(() {
            _playerToSubstituteId = null;
            _teamOfSubstitution = null;
          });
        } else {
          if (!_isFinished) _showActionMenu(context, teamId, playerName, controller, stats.fouls, isWideScreen, state);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 35, 10), 
            decoration: BoxDecoration(
              color: isSelectedForSwap
                  ? Colors.orangeAccent.withOpacity(0.2)
                  : (isOnCourt ? color.withOpacity(0.08) : Colors.white.withOpacity(0.02)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelectedForSwap
                    ? Colors.orangeAccent
                    : (isDisqualified ? Colors.redAccent.withOpacity(0.5) : (isOnCourt ? color.withOpacity(0.2) : Colors.white10)),
                width: isSelectedForSwap || isOnCourt ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: stats.playerNumber.length > 2 ? 36 : 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isOnCourt ? color.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        stats.playerNumber,
                        style: TextStyle(
                            color: isOnCourt ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.w900,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              playerName,
                              style: TextStyle(
                                color: isDisqualified ? Colors.redAccent : (isOnCourt ? Colors.white : Colors.white60),
                                fontWeight: isOnCourt ? FontWeight.bold : FontWeight.w500,
                                fontSize: isWideScreen ? 14 : 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCaptain)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                              child: const Text("C", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (stats.points > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${stats.points} PTS",
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            _buildMiniFoulDots(stats.fouls),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white24),
                onPressed: () => _showEditPlayerDialog(context, controller, playerName, stats.playerNumber, teamId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMiniFoulDots(int count) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      bool isFilled = i < count;
      Color dotColor = !isFilled
          ? Colors.white.withOpacity(0.05)
          : (i == 4 ? Colors.redAccent : Colors.orangeAccent);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor,
          border: !isFilled ? Border.all(color: Colors.white10, width: 0.5) : null,
        ),
      );
    }),
  );
}

  void _showEditPlayerDialog(BuildContext context, MatchGameController controller, String playerName, String currentNumber, String teamSide) {
    final numberController = TextEditingController(text: currentNumber);
    final errorNotifier = ValueNotifier<String?>(null);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B), title: Text("Editar: $playerName", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Este cambio solo aplicará para el partido actual.", style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 16),
            ValueListenableBuilder<String?>(
              valueListenable: errorNotifier,
              builder: (context, errorText, child) {
                return TextField(
                  controller: numberController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: "Número", labelStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.format_list_numbered, color: Colors.white54), errorText: errorText),
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
          padding: const EdgeInsets.all(20), constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView( 
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("REGISTRAR FALTA", style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)), Text(playerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white), overflow: TextOverflow.ellipsis)])),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx))
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),
                _buildFoulSectionHeader("PERSONAL (P)", Icons.person, Colors.blueGrey.shade200),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                    _buildFoulChip(ctx, controller, teamId, playerName, "Lateral", "P", Colors.white10, Colors.white),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "P1", Colors.white10, Colors.white),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "P2", Colors.white10, Colors.white),
                    _buildFoulChip(ctx, controller, teamId, playerName, "3 Tiros", "P3", Colors.white10, Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFoulSectionHeader("CONDUCTA / GRAVES", Icons.warning_amber_rounded, Colors.orangeAccent),
                const SizedBox(height: 8),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
                    _buildCompactCategoryLabel("TÉCNICA", Colors.orangeAccent),
                    _buildFoulChip(ctx, controller, teamId, playerName, "Simple", "T", Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent, isCompact: true),
                    _buildFoulChip(ctx, controller, teamId, playerName, "1 Tiro", "T1", Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent, isCompact: true),
                    _buildFoulChip(ctx, controller, teamId, playerName, "2 Tiros", "T2", Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent, isCompact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.redAccent))),
                    icon: const Icon(Icons.gavel_rounded, size: 18), label: const FittedBox(fit: BoxFit.scaleDown, child: Text("DESCALIFICANTE (D)", style: TextStyle(fontWeight: FontWeight.bold))),
                    onPressed: () { controller.updateStats(teamId, playerName, fouls: 5, foulType: "D"); Navigator.pop(ctx); },
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
    return Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)))]);
  }

  Widget _buildCompactCategoryLabel(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))), child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)));
  }

  Widget _buildFoulChip(BuildContext ctx, MatchGameController controller, String teamId, String playerName, String label, String typeCode, Color bgColor, Color textColor, {bool isCompact = false}) {
    return InkWell(
      onTap: () { controller.updateStats(teamId, playerName, fouls: 1, foulType: typeCode); Navigator.pop(ctx); },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isCompact ? null : 70, padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 6, vertical: 10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: textColor.withOpacity(0.3))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text(typeCode, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)), if (!isCompact) ...[const SizedBox(height: 2), FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)), textAlign: TextAlign.center))]]),
      ),
    );
  }

  void _showActionMenu(BuildContext context, String teamId, String playerName, MatchGameController controller, int currentFouls, bool isWideScreen, MatchState state) {
    bool isDisqualified = currentFouls >= 5;
    
    showDialog(
      context: context, 
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: const Color(0xFF0D1117).withOpacity(0.8), 
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(playerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center), 
                  const SizedBox(height: 4), 
                  Text(isDisqualified ? "JUGADOR DESCALIFICADO" : "Selecciona una acción", style: TextStyle(color: isDisqualified ? Colors.redAccent : Colors.white54, fontWeight: isDisqualified ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center), 
                  const SizedBox(height: 24),
                  if (isDisqualified) ...[
                    const Icon(Icons.block, size: 50, color: Colors.redAccent), const SizedBox(height: 10), const Text("No se pueden agregar más eventos a este jugador.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)), const SizedBox(height: 20),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), icon: const Icon(Icons.swap_horiz), label: const Text("REALIZAR SUSTITUCIÓN AHORA"), onPressed: () { Navigator.pop(context); final onCourt = teamId == 'A' ? state.teamAOnCourt : state.teamBOnCourt; final bench = teamId == 'A' ? state.teamABench : state.teamBBench; _showSubstitutionDialog(context, teamId, onCourt, bench, controller, state, preSelectedOut: playerName); }))
                  ] else
                    Wrap(
                      spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                      children: [
                        _buildStatButton("+1", Colors.lightBlueAccent, () { controller.updateStats(teamId, playerName, points: 1); Navigator.pop(context); }, isWideScreen),
                        _buildStatButton("+2", Colors.greenAccent, () { controller.updateStats(teamId, playerName, points: 2); Navigator.pop(context); }, isWideScreen),
                        _buildStatButton("+3", Colors.orangeAccent, () { controller.updateStats(teamId, playerName, points: 3); Navigator.pop(context); }, isWideScreen),
                        _buildStatButton("Falta", Colors.redAccent, () { Navigator.pop(context); _showFoulOptionsDialog(context, controller, teamId, playerName); }, isWideScreen, icon: Icons.error_outline),
                      ],
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16))
                  )
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
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        width: btnSize, height: btnSize, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) Icon(icon, color: color, size: isWideScreen ? 28 : 24) else Text(label, style: TextStyle(fontSize: isWideScreen ? 24 : 20, fontWeight: FontWeight.bold, color: color)), if (icon != null) Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))]),
      ),
    );
  }

  void _showTeamOptions(BuildContext context, MatchGameController controller, String teamId, String teamName) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: const Color(0xFF0D1117).withOpacity(0.8), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Opciones: $teamName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center), const SizedBox(height: 10), const Divider(color: Colors.white24),
                ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.timer_outlined, color: Colors.white)), title: const Text("Solicitar Tiempo Fuera", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), onTap: () { controller.addTimeout(teamId); Navigator.pop(context); }),
                ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.sports, color: Colors.orangeAccent)), title: const Text("Falta Técnica al Entrenador (C)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), onTap: () { controller.addTeamFoul(teamId, 'C'); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta al Coach (C) registrada"))); }),
                ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle), child: const Icon(Icons.chair, color: Colors.lightBlueAccent)), title: const Text("Falta Técnica a la Banca (B)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), onTap: () { controller.addTeamFoul(teamId, 'B'); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta a la Banca (B) registrada"))); }), const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubstitutionDialog(BuildContext context, String teamId, List<String> onCourt, List<String> bench, MatchGameController controller, MatchState state, {String? preSelectedOut}) {
    String? selectedOut = preSelectedOut; 
    String? selectedIn;
    
    final sortedOnCourt = _sortPlayersByNumberDesc(onCourt, state);
    final sortedBench = _sortPlayersByNumberDesc(bench, state);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2B), title: const Text("Sustitución", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [_dropdown("Sale (Cancha)", sortedOnCourt, selectedOut, (v) => setState(() => selectedOut = v), state), const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Icon(Icons.arrow_downward, color: Colors.orangeAccent)), _dropdown("Entra (Banca)", sortedBench, selectedIn, (v) => setState(() => selectedIn = v), state)]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent), onPressed: (selectedOut != null && selectedIn != null) ? () { controller.substitutePlayer(teamId, selectedOut!, selectedIn!); Navigator.pop(context); } : null, child: const Text("Confirmar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String? val, Function(String?) changed, MatchState state) {
    return Theme(
      data: ThemeData.dark(),
      child: InputDecorator(decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), border: const OutlineInputBorder(), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24))), 
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val, isDense: true, isExpanded: true, dropdownColor: const Color(0xFF2C323F), style: const TextStyle(color: Colors.white, fontSize: 16), 
          items: items.map((e) {
            final numDorsal = state.playerStats[e]?.playerNumber ?? "#";
            return DropdownMenuItem(value: e, child: Text("$numDorsal - $e"));
          }).toList(), 
          onChanged: changed))),
    );
  }

  void _showTimePicker(BuildContext context, MatchGameController controller, Duration currentTime) {
    int selectedMinute = currentTime.inMinutes; int selectedSecond = currentTime.inSeconds % 60;
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1A1F2B),
      builder: (_) => Container(
        height: 300, padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent))), const Text("Ajustar Reloj", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)), TextButton(onPressed: () { controller.setTime(Duration(minutes: selectedMinute, seconds: selectedSecond)); Navigator.pop(context); }, child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)))]),
             const SizedBox(height: 20),
             Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 70, child: ListWheelScrollView.useDelegate(itemExtent: 50, controller: FixedExtentScrollController(initialItem: selectedMinute), physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (v) => selectedMinute = v, childDelegate: ListWheelChildBuilderDelegate(childCount: 100, builder: (c,i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 30, color: Colors.white)))))), const Text(":", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)), SizedBox(width: 70, child: ListWheelScrollView.useDelegate(itemExtent: 50, controller: FixedExtentScrollController(initialItem: selectedSecond), physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: (v) => selectedSecond = v, childDelegate: ListWheelChildBuilderDelegate(childCount: 60, builder: (c,i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 30, color: Colors.white))))))]))
          ],
        ),
      )
    );
  }
  
  void _confirmExit(BuildContext context) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2B), title: const Text("¿Salir?", style: TextStyle(color: Colors.white)), content: const Text("El partido continuará guardado localmente.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () { Navigator.pop(ctx); Navigator.of(context).popUntil((r) => r.isFirst); }, child: const Text("Salir", style: TextStyle(color: Colors.white))),
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
    // 1. Mostrar diálogo de carga
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
      final dbBase = ref.read(databaseProvider);

      // --- 1. RECUPERAR DATOS DEL TORNEO (PARA EL LOGO DEL ÁRBITRO) ---
      final tournamentObj = await (dbBase.select(dbBase.tournaments)
            ..where((t) => t.id.equals(widget.tournamentId.toString())))
          .getSingleOrNull();

      // Asumimos que agregaste 'refereeLogoUrl' a tu tabla Tournaments en Drift
      final String refereeLogoUrl = tournamentObj?.refereeLogoUrl ?? "";    

      // --- 2. RECUPERAR FIRMAS DE OFICIALES (POR NOMBRE Y ROL) ---
      // Usamos .get() y firstOrNull para evitar el error de "Too many elements"
      final mainRefObj = await (dbBase.select(dbBase.officials)
            ..where((t) => t.name.equals(widget.mainReferee))
            ..where((t) => t.role.equals('ARBITRO_PRINCIPAL')))
          .get()
          .then((list) => list.firstOrNull);

      final auxRefObj = await (dbBase.select(dbBase.officials)
            ..where((t) => t.name.equals(widget.auxReferee))
            ..where((t) => t.role.equals('ARBITRO_AUXILIAR')))
          .get()
          .then((list) => list.firstOrNull);

      Uint8List? mainSignBytes;
      Uint8List? auxSignBytes;

      if (mainRefObj?.signatureData != null && mainRefObj!.signatureData!.isNotEmpty) {
        mainSignBytes = base64Decode(mainRefObj.signatureData!);
      }
      if (auxRefObj?.signatureData != null && auxRefObj!.signatureData!.isNotEmpty) {
        auxSignBytes = base64Decode(auxRefObj.signatureData!);
      }

      // --- 3. GENERAR BYTES DEL PDF (CON LAS FIRMAS INCLUIDAS) ---
      final pdfBytes = await PdfGenerator.generateBytes(
        state,
        widget.teamAName,
        widget.teamBName,
        tournamentName: widget.tournamentName,
        categoryName: widget.categoryName,
        tournamentLogoUrl: widget.tournamentLogoUrl,
        refereeLogoUrl: refereeLogoUrl,
        venueName: widget.venueName,
        mainReferee: widget.mainReferee,
        auxReferee: widget.auxReferee,
        scorekeeper: widget.scorekeeper,
        coachA: widget.coachA,
        coachB: widget.coachB,
        captainAId: widget.captainAId,
        captainBId: widget.captainBId,
        protestSignature: signature, // Firma de protesta (capitán)
        matchDate: widget.matchDate ?? DateTime.now(),
        mainRefSignature: mainSignBytes, // Firma Árbitro Principal
        auxRefSignature: auxSignBytes,   // Firma Árbitro Auxiliar
      );

      // --- 4. FINALIZAR Y SINCRONIZAR A LA NUBE ---
      bool synced = await controller.finalizeAndSync(
        api,
        signature,
        pdfBytes,
        widget.teamAName,
        widget.teamBName,
      );

      // --- 5. ACTUALIZAR ESTADOS LOCALES ---
      await (dbBase.update(dbBase.matches)
            ..where((tbl) => tbl.id.equals(state.matchId)))
          .write(const db.MatchesCompanion(status: drift.Value('FINISHED')));

      if (state.fixtureId != null) {
        await (dbBase.update(dbBase.fixtures)
              ..where((tbl) => tbl.id.equals(state.fixtureId!)))
            .write(
          db.FixturesCompanion(
            status: const drift.Value('FINISHED'),
            scoreA: drift.Value(state.scoreA),
            scoreB: drift.Value(state.scoreB),
          ),
        );
      }

      // --- 6. MANEJO DE UI FINAL ---
      if (context.mounted) {
        setState(() => _isFinished = true);
        Navigator.pop(context); // Quitar CircularProgressIndicator

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced
                  ? "Sincronizado correctamente"
                  : "Guardado localmente (Sin conexión)",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: synced ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        );

        if (autoShow) _goToPdfPreview(context, state, signature);
      }
    } catch (e) {
      debugPrint("Error en _finishMatchProcess: $e");
      if (context.mounted) {
        Navigator.pop(context); // Quitar CircularProgressIndicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al finalizar: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
        if (autoShow) _goToPdfPreview(context, state, signature);
      }
    }
  }
  
  void _goToPdfPreview(BuildContext context, MatchState state, Uint8List? signature) async {
    final database = ref.read(databaseProvider);

    // Buscamos por NOMBRE y por el ROL específico del partido
  final mainRefObj = await (database.select(database.officials)
        ..where((t) => t.name.equals(state.mainReferee))
        ..where((t) => t.role.equals('ARBITRO_PRINCIPAL'))) // <--- Filtro de rol
        .get().then((list) => list.firstOrNull);

  final auxRefObj = await (database.select(database.officials)
        ..where((t) => t.name.equals(state.auxReferee))
        ..where((t) => t.role.equals('ARBITRO_AUXILIAR'))) // <--- Filtro de rol
        .get().then((list) => list.firstOrNull);

    Uint8List? mainSignBytes;
    Uint8List? auxSignBytes;

    // 2. Decodificar de Base64 a Uint8List
    if (mainRefObj?.signatureData != null && mainRefObj!.signatureData!.isNotEmpty) {
      try {
        mainSignBytes = base64Decode(mainRefObj.signatureData!);
      } catch (e) {
        debugPrint("Error decodificando firma principal: $e");
      }
    }
    
    if (auxRefObj?.signatureData != null && auxRefObj!.signatureData!.isNotEmpty) {
      try {
        auxSignBytes = base64Decode(auxRefObj.signatureData!);
      } catch (e) {
        debugPrint("Error decodificando firma auxiliar: $e");
      }
    }

    // 3. Navegar
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            state: state,
            teamAName: widget.teamAName,
            teamBName: widget.teamBName,
            tournamentName: widget.tournamentName,
            categoryName: widget.categoryName,
            tournamentLogoUrl: widget.tournamentLogoUrl,
            refereeLogoUrl: widget.refereeLogoUrl,
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
            mainRefSignature: mainSignBytes, 
            auxRefSignature: auxSignBytes,   
          ),
        ),
      );
    }
  }
  
  void _showFinalOptionsDialog(BuildContext context, MatchState currentState) {
    if (_isFinished) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B), 
        title: const Text("Finalizar Partido", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center), 
        content: const Text("¿Cómo concluyó el encuentro?", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.only(top: 15, bottom: 20, left: 24, right: 24),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)), 
                icon: const Icon(Icons.check_circle), 
                label: const Text("Finalizar Normal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                onPressed: () { 
                  Navigator.pop(ctx); 
                  _handleIncidentsFlow(context, currentState); // <--- Llama al nuevo diálogo
                }
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: const BorderSide(color: Colors.orangeAccent), padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.warning_amber_rounded), 
                label: const Text("Inasistencia / Default", style: TextStyle(fontWeight: FontWeight.bold)), 
                onPressed: () { Navigator.pop(ctx); _handleForfeitFlow(context, currentState); }
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.edit_document), 
                label: const Text("Firmar Bajo Protesta"), 
                onPressed: () { Navigator.pop(ctx); _handleProtestFlow(context, currentState); }
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
              )
            ],
          )
        ],
      ),
    );
  }

  // --- NUEVO FLUJO PARA NOVEDADES ---
  Future<void> _handleIncidentsFlow(BuildContext context, MatchState state) async {
    final textController = TextEditingController(text: "Sin novedad");
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        title: const Text("Reporte de Novedades", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Hubo algún incidente o problema durante el partido?", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Observaciones",
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Finalizar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm == true && context.mounted) {
      String novedades = textController.text.trim();
      if (novedades.isEmpty) novedades = "Sin novedad";
      
      final controller = ref.read(matchGameProvider.notifier);
      controller.setObservaciones(novedades);
      
      final newState = ref.read(matchGameProvider);
      _finishMatchProcess(context, newState, null, autoShow: true);
    }
  }

  Future<void> _handleForfeitFlow(BuildContext context, MatchState state) async {
    final controller = ref.read(matchGameProvider.notifier);
    
    final String? defaultingTeam = await showDialog<String>(
      context: context, 
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1F2B), 
        title: const Text("¿Quién no se presentó?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'A'), 
            child: Padding(padding: const EdgeInsets.all(12), child: Text("Faltó Local: ${widget.teamAName}", style: const TextStyle(fontSize: 16, color: Colors.orangeAccent)))
          ), 
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'B'), 
            child: Padding(padding: const EdgeInsets.all(12), child: Text("Faltó Visita: ${widget.teamBName}", style: const TextStyle(fontSize: 16, color: Colors.lightBlueAccent)))
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'BOTH'), 
            child: const Padding(padding: EdgeInsets.all(12), child: Text("Ambos Equipos (Doble Default)", style: TextStyle(fontSize: 16, color: Colors.redAccent)))
          ),
          const Divider(color: Colors.white24),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null), 
            child: const Padding(padding: EdgeInsets.all(12), child: Text("Cancelar", style: TextStyle(fontSize: 16, color: Colors.grey)))
          ),
        ]
      )
    );
    
    if (defaultingTeam != null && context.mounted) {
      controller.declareForfeit(defaultingTeam);
      controller.setObservaciones("Partido finalizado por inasistencia (Default)."); // <--- AÑADIDO PARA AUTOMATIZAR
      
      final newState = ref.read(matchGameProvider);
      _finishMatchProcess(context, newState, null, autoShow: true);
    }
  }

  void _showPeriodSelector(BuildContext context, MatchGameController controller) {
    showDialog(context: context, builder: (_) => SimpleDialog(backgroundColor: const Color(0xFF1A1F2B), title: const Text("Seleccionar Periodo", style: TextStyle(color: Colors.white)), children: [_periodOption(context, controller, 1, "Periodo 1"), _periodOption(context, controller, 2, "Periodo 2"), _periodOption(context, controller, 3, "Periodo 3"), _periodOption(context, controller, 4, "Periodo 4"), const Divider(color: Colors.white24), _periodOption(context, controller, 5, "Tiempo Extra 1"), _periodOption(context, controller, 6, "Tiempo Extra 2")]));
  }

  Widget _periodOption(BuildContext context, MatchGameController controller, int period, String label) {
    return SimpleDialogOption(onPressed: () { controller.setPeriod(period); Navigator.pop(context); }, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(label, style: const TextStyle(color: Colors.white70))));
  }

  Future<void> _handleProtestFlow(BuildContext context, MatchState state) async {
    final String? protestingTeam = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(backgroundColor: const Color(0xFF1A1F2B), title: const Text("¿Quién protesta?", style: TextStyle(color: Colors.white)), children: [SimpleDialogOption(onPressed: () => Navigator.pop(ctx, widget.teamAName), child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.teamAName, style: const TextStyle(fontSize: 16, color: Colors.orangeAccent)))), SimpleDialogOption(onPressed: () => Navigator.pop(ctx, widget.teamBName), child: Padding(padding: const EdgeInsets.all(12), child: Text(widget.teamBName, style: const TextStyle(fontSize: 16, color: Colors.lightBlueAccent))))]));
    if (protestingTeam != null && context.mounted) {
      final Uint8List? signature = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProtestSignatureScreen(teamName: protestingTeam)));
      if (signature != null && context.mounted) { 
        setState(() => _capturedSignature = signature); 
        _finishMatchProcess(context, state, signature, autoShow: true); 
      }
    }
  }
}