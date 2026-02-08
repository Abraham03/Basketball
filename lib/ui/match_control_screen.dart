import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/dependency_injection.dart';
import '../core/utils/pdf_generator.dart';
import '../core/models/catalog_models.dart';
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
  });

  @override
  ConsumerState<MatchControlScreen> createState() => _MatchControlScreenState();
}

class _MatchControlScreenState extends ConsumerState<MatchControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final controller = ref.read(matchGameProvider.notifier);

    // LISTENER GENERAL
    ref.listen<MatchState>(matchGameProvider, (previous, next) {
      // 1. Alerta de 5 Faltas
      next.playerStats.forEach((playerId, stats) {
        final previousFouls = previous?.playerStats[playerId]?.fouls ?? 0;
        if (stats.fouls == 5 && previousFouls == 4) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Límite de Faltas"),
              content: Text("El jugador $playerId ha llegado a 5 faltas y debe ser sustituido."),
              backgroundColor: Colors.red.shade50,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Entendido"),
                ),
              ],
            ),
          );
        }
      });

      // 2. Alerta de Fin de Periodo
      if ((previous?.timeLeft.inSeconds ?? 1) > 0 && next.timeLeft.inSeconds == 0) {
        bool isTie = next.scoreA == next.scoreB;
        bool isRegularTimeOver = next.currentPeriod >= 4;

        String title;
        String content;
        String actionButtonText;
        VoidCallback action;

        if (!isRegularTimeOver) {
          title = "Fin del Periodo ${next.currentPeriod}";
          content = "¿Deseas iniciar el Periodo ${next.currentPeriod + 1}?";
          actionButtonText = "Siguiente Periodo";
          action = () => controller.nextPeriod();
        } else {
          if (isTie) {
            title = "¡EMPATE!";
            content = "El partido terminó empatado. ¿Iniciar Tiempo Extra?";
            actionButtonText = "Iniciar Tiempo Extra";
            action = () => controller.nextPeriod();
          } else {
            title = "Fin del Partido";
            content = "El tiempo ha terminado. Marcador Final: ${next.scoreA} - ${next.scoreB}";
            actionButtonText = "Finalizar";
            action = () {
              // Usamos un Future.delayed para asegurar que el diálogo anterior cerró
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  _showFinalOptionsDialog(context, next);
                }
              });
            };
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Revisar"),
              ),
              ElevatedButton(
                onPressed: () {
                  action();
                  Navigator.pop(context);
                },
                child: Text(actionButtonText),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("En Juego"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Deshacer",
            onPressed: () {
              controller.undo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Acción deshecha"), duration: Duration(milliseconds: 500)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility), // Icono de "Ver" u "Ojo"
            tooltip: "Ver Acta (Zoom)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(
                    state: gameState,
                    teamAName: widget.teamAName,
                    teamBName: widget.teamBName,
                    tournamentName: widget.tournamentName,
                    venueName: widget.venueName,
                    mainReferee: widget.mainReferee,
                    auxReferee: widget.auxReferee,
                    scorekeeper: widget.scorekeeper,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Vista Previa",
            onPressed: () async {
              await PdfGenerator.generateAndPreview(
                gameState,
                widget.teamAName,
                widget.teamBName,
                tournamentName: widget.tournamentName,
                venueName: widget.venueName,
                mainReferee: widget.mainReferee,
                auxReferee: widget.auxReferee,
                scorekeeper: widget.scorekeeper,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Compartir PDF",
            onPressed: () async {
              await PdfGenerator.generateAndShare(
                gameState,
                widget.teamAName,
                widget.teamBName,
                tournamentName: widget.tournamentName,
                venueName: widget.venueName,
                mainReferee: widget.mainReferee,
                auxReferee: widget.auxReferee,
                scorekeeper: widget.scorekeeper,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreBoard(context, gameState, controller),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamColumn(
                    context,
                    widget.teamAName,
                    Colors.orange.shade50,
                    'A',
                    gameState.teamAOnCourt,
                    gameState.teamABench,
                    controller,
                    gameState,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                Expanded(
                  child: _buildTeamColumn(
                    context,
                    widget.teamBName,
                    Colors.blue.shade50,
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
    );
  }

  Widget _buildScoreBoard(BuildContext context, MatchState state, MatchGameController controller) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    String periodText = state.currentPeriod <= 4
        ? "PERIODO ${state.currentPeriod}"
        : "TIEMPO EXTRA ${state.currentPeriod - 4}";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.black87,
      child: Column(
        children: [
          // FILA SUPERIOR: Periodo
          GestureDetector(
            onTap: () => _showPeriodSelector(context, controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                periodText,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // FILA CENTRAL: Score A - Reloj - Score B
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // --- EQUIPO A ---
              Column(
                children: [
                  // Indicador visual si tienen la posesión
                  if (state.possession == 'A')
                    const Icon(Icons.arrow_downward, color: Colors.orange, size: 20),
                  _scoreText(state.scoreA.toString(), widget.teamAName),

                  TeamFoulsDisplay(fouls: controller.getTeamFouls('A')),
                ],
              ),

              // --- RELOJ Y POSESIÓN (CENTRO) ---
              Column(
                children: [
                  // Reloj
                  GestureDetector(
                    onTap: () => controller.toggleTimer(),
                    onLongPress: () {
                      if (!state.isRunning) {
                        _showTimePicker(context, controller, state.timeLeft);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Pausa el reloj para editar")),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: state.isRunning ? Colors.greenAccent : Colors.redAccent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white10,
                      ),
                      child: Text(
                        "$minutes:$seconds",
                        style: TextStyle(
                          color: state.isRunning ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  if (!state.isRunning)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text("Mantén para editar", style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ),

                  const SizedBox(height: 12), // Espacio debajo del reloj

                  // CONTROLES DE POSESIÓN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- BOTÓN IZQUIERDA (EQUIPO A) ---
                        GestureDetector(
                          onTap: () => controller.setPossession('A'),
                          behavior: HitTestBehavior.translucent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: state.possession == 'A' ? Colors.orange : Colors.grey.shade700,
                              size: 24,
                            ),
                          ),
                        ),

                        // Texto central
                        const Text(
                          "POSESIÓN",
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),

                        // --- BOTÓN DERECHA (EQUIPO B) ---
                        GestureDetector(
                          onTap: () => controller.setPossession('B'),
                          behavior: HitTestBehavior.translucent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Icon(
                              Icons.arrow_forward,
                              color: state.possession == 'B' ? Colors.blue : Colors.grey.shade700,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- EQUIPO B ---
              Column(
                children: [
                  // Indicador visual si tienen la posesión
                  if (state.possession == 'B')
                    const Icon(Icons.arrow_downward, color: Colors.blue, size: 20),
                  _scoreText(state.scoreB.toString(), widget.teamBName),
                  // <--- FALTAS EQUIPO B
                  TeamFoulsDisplay(fouls: controller.getTeamFouls('B')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreText(String score, String team) {
    return Column(
      children: [
        Text(score, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
        Text(team, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTeamColumn(
    BuildContext context,
    String teamName,
    Color bgColor,
    String teamId,
    List<String> onCourt,
    List<String> bench,
    MatchGameController controller,
    MatchState state,
  ) {
    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    teamName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.compare_arrows),
                  tooltip: "Sustitución",
                  style: IconButton.styleFrom(backgroundColor: Colors.white54),
                  onPressed: () => _showSubstitutionDialog(
                    context,
                    teamId,
                    onCourt,
                    bench,
                    controller,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: onCourt.length,
              itemBuilder: (context, index) {
                final playerName = onCourt[index];
                final stats = state.playerStats[playerName] ?? const PlayerStats();

                Color? cardColor;
                Color textColor = Colors.black;
                if (stats.fouls == 4) {
                  cardColor = Colors.yellow.shade400;
                } else if (stats.fouls >= 5) {
                  cardColor = Colors.red.shade400;
                  textColor = Colors.white;
                } else {
                  cardColor = Colors.white;
                }

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      child: Text(stats.playerNumber.isNotEmpty ? stats.playerNumber : "#"),
                    ),
                    title: Text(
                      playerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      "${stats.points}pts • ${stats.fouls}flt",
                      style: TextStyle(color: textColor),
                    ),
                    onTap: () => _showActionMenu(
                      context,
                      teamId,
                      playerName,
                      controller,
                      stats.fouls,
                    ),
                  ),
                );
              },
            ),
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

  // Nuevo método para procesar la finalización
void _finishMatchProcess(
      BuildContext context, MatchState state, Uint8List? signature) async {
    // 1. Loading
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      // Obtenemos dependencias
      final api = ref.read(apiServiceProvider);
      final controller = ref.read(matchGameProvider.notifier);

      // 2. Intentar subir
      bool synced = await controller.finalizeAndSync(
          api, signature, widget.teamAName, widget.teamBName);

      if (context.mounted) {
        Navigator.pop(context); // Quitar Loading

        if (synced) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("✅ Partido sincronizado exitosamente"),
              backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("⚠️ Sin conexión. Se guardó localmente."),
              backgroundColor: Colors.orange));
        }

        // 3. Mostrar PDF final
        _goToPdfPreview(context, state, signature);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Quitar Loading en error
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        // Aún así vamos al PDF
        _goToPdfPreview(context, state, signature);
      }
    }
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

  void _showActionMenu(
    BuildContext context,
    String teamId,
    String playerName,
    MatchGameController controller,
    int currentFouls,
  ) {
    final bool isDisqualified = currentFouls >= 5;

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            Text(
              isDisqualified ? "$playerName (EXPULSADO)" : playerName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDisqualified ? Colors.red : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            if (isDisqualified)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Este jugador ha alcanzado el límite de 5 faltas. Realiza una sustitución.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      controller.updateStats(teamId, playerName, points: 1);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("+1"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.updateStats(teamId, playerName, points: 2);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("+2"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.updateStats(teamId, playerName, points: 3);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("+3"),
                  ),
                  // BOTÓN DE FALTA MODIFICADO: AHORA ABRE EL NUEVO DIÁLOGO
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Cierra el menú de puntos
                      // Abre el menú detallado de faltas
                      _showFoulOptionsDialog(context, controller, teamId, playerName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Falta"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // DIÁLOGO DE FALTAS (Ahora sí se usa)
  void _showFoulOptionsDialog(
    BuildContext context, 
    MatchGameController controller, 
    String teamId, 
    String playerName
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text("Falta: $playerName"),
        children: [
          _foulOption(ctx, controller, teamId, playerName, "Personal 1 Tiro", "P1"),
          _foulOption(ctx, controller, teamId, playerName, "Personal 2 Tiros", "P2"),
          _foulOption(ctx, controller, teamId, playerName, "Personal 3 Tiros", "P3"),
          const Divider(),
          _foulOption(ctx, controller, teamId, playerName, "Técnica", "T"),
          _foulOption(ctx, controller, teamId, playerName, "Anti-deportiva", "U"),
          _foulOption(ctx, controller, teamId, playerName, "Expulsión", "D"),
        ],
      ),
    );
  }

  // Helper para las opciones de faltas
  Widget _foulOption(
    BuildContext ctx, 
    MatchGameController controller, 
    String teamId, 
    String playerName, 
    String label, 
    String typeCode
  ) {
    return SimpleDialogOption(
      onPressed: () {
        // Registra 1 falta y el tipo específico (P1, P2, T, etc.)
        controller.updateStats(teamId, playerName, fouls: 1, foulType: typeCode);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(label, style: const TextStyle(fontSize: 16)),
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
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const Text(
                    "Ajustar Reloj",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      "Aceptar",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWheel(
                    selectedMinute,
                    99,
                    (val) => selectedMinute = val,
                    "Min",
                  ),
                  const SizedBox(width: 20),
                  _buildWheel(
                    selectedSecond,
                    59,
                    (val) => selectedSecond = val,
                    "Seg",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel(
    int initial,
    int max,
    Function(int) onChanged,
    String label,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: initial),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max + 1,
              builder: (c, i) => Center(
                child: Text(
                  i.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
        ),
        Text(label),
      ],
    );
  }

  void _showSubstitutionDialog(
    BuildContext context,
    String teamId,
    List<String> onCourt,
    List<String> bench,
    MatchGameController controller,
  ) {
    String? selectedOut;
    String? selectedIn;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Realizar Cambio"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sale (Cancha):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedOut,
                hint: const Text("Seleccionar..."),
                isExpanded: true,
                items: onCourt
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedOut = val),
              ),
              const SizedBox(height: 16),
              const Text(
                "Entra (Banca):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedIn,
                hint: const Text("Seleccionar..."),
                isExpanded: true,
                items: bench
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedIn = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
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
              child: const Text("Confirmar"),
            ),
          ],
        ),
      ),
    );
  }

void _showFinalOptionsDialog(BuildContext context, MatchState currentState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Acta del Partido"),
        content: const Text("¿Cómo deseas generar el acta final?"),
        actions: [
          // OPCIÓN 1: FIRMAR BAJO PROTESTA
          TextButton.icon(
            icon: const Icon(Icons.edit_document, color: Colors.red),
            label: const Text("Firmar bajo Protesta",
                style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx); // Cerrar diálogo actual
              _handleProtestFlow(context, currentState); // Flujo de protesta
            },
          ),

          // OPCIÓN 2: FINALIZAR NORMAL (Sube a la nube)
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text("Finalizar y Subir"),
            onPressed: () {
              Navigator.pop(ctx);
              // Llama a la función de subida (sin firma extra)
              _finishMatchProcess(context, currentState, null);
            },
          ),
        ],
      ),
    );
  }

  // Flujo para capturar la firma
  Future<void> _handleProtestFlow(BuildContext context, MatchState state) async {
    // 1. Preguntar qué equipo protesta
    final String? protestingTeam = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("¿Qué equipo protesta?"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, widget.teamAName),
            child: Text("Equipo A: ${widget.teamAName}"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, widget.teamBName),
            child: Text("Equipo B: ${widget.teamBName}"),
          ),
        ],
      ),
    );

    if (protestingTeam != null && context.mounted) {
      // 2. Abrir pantalla de firma
      final Uint8List? signature = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProtestSignatureScreen(teamName: protestingTeam),
        ),
      );

      // 3. Si firmaron, ir al PDF con la firma
      if (signature != null && context.mounted) {
        _goToPdfPreview(context, state, signature);
      }
    }
  }

  // Método helper para ir al PDF (para no repetir código)
  void _goToPdfPreview(BuildContext context, MatchState state, Uint8List? signature) {
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
          // Aquí tienes que actualizar tu PdfPreviewScreen para que acepte la firma también
           protestSignature: signature,
        ),
      ),
    );
  }

}

// -------------------------------------------------------------------------
// Widget reutilizable para mostrar las faltas
// -------------------------------------------------------------------------
class TeamFoulsDisplay extends StatelessWidget {
  final int fouls;

  const TeamFoulsDisplay({super.key, required this.fouls});

  @override
  Widget build(BuildContext context) {
    // Si llegan a 5 faltas, entran en penalización (Bonus)
    final isBonus = fouls >= 5;
    final color = isBonus ? Colors.redAccent : Colors.grey;

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          "FALTAS",
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: isBonus ? Colors.red.withValues(alpha:0.2) : Colors.transparent,
            border: Border.all(
              color: color,
              width: isBonus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$fouls",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isBonus ? Colors.redAccent : Colors.white,
                ),
              ),
              if (isBonus) ...[
                const SizedBox(width: 4),
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
              ]
            ],
          ),
        ),
        if (isBonus)
          const Text(
            "BONUS",
            style: TextStyle(
              fontSize: 9,
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}