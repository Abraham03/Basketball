import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/pdf_generator.dart';
import '../logic/match_game_controller.dart';

class MatchControlScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String teamAName;
  final String teamBName;

  const MatchControlScreen({
    super.key,
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
  });

  @override
  ConsumerState<MatchControlScreen> createState() => _MatchControlScreenState();
}

class _MatchControlScreenState extends ConsumerState<MatchControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchGameProvider.notifier).initMatch(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final controller = ref.read(matchGameProvider.notifier);

    // ✅ LISTENER GENERAL
    ref.listen<MatchState>(matchGameProvider, (previous, next) {
      // 1. Alerta de 5 Faltas (Igual que antes)
      next.playerStats.forEach((playerId, stats) {
        final previousFouls = previous?.playerStats[playerId]?.fouls ?? 0;
        if (stats.fouls == 5 && previousFouls == 4) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🚨 Límite de Faltas"),
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

      // 2. Alerta de Fin de Periodo (cuando el reloj llega a 0)
      // <--- MODIFICADO: Lógica inteligente para Tiempos Extra y Final
      if ((previous?.timeLeft.inSeconds ?? 1) > 0 && next.timeLeft.inSeconds == 0) {
        
        bool isTie = next.scoreA == next.scoreB;
        bool isRegularTimeOver = next.currentPeriod >= 4;

        String title;
        String content;
        String actionButtonText;
        VoidCallback action;

        if (!isRegularTimeOver) {
          // Periodos 1, 2, 3 -> Siguiente normal
          title = "Fin del Periodo ${next.currentPeriod}";
          content = "¿Deseas iniciar el Periodo ${next.currentPeriod + 1}?";
          actionButtonText = "Siguiente Periodo";
          action = () => controller.nextPeriod();
        } else {
          // Fin del 4to o Prórroga
          if (isTie) {
            title = "¡EMPATE!";
            content = "El partido terminó empatado. ¿Iniciar Tiempo Extra?";
            actionButtonText = "Iniciar Tiempo Extra"; // Esto pondrá 5 mins
            action = () => controller.nextPeriod();
          } else {
            title = "Fin del Partido";
            content = "El tiempo ha terminado. Marcador Final: ${next.scoreA} - ${next.scoreB}";
            actionButtonText = "Finalizar";
            action = () {}; // Aquí podrías navegar atrás o guardar final
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
            icon: const Icon(Icons.print),
            tooltip: "Vista Previa",
            onPressed: () async {
              await PdfGenerator.generateAndPreview(gameState, widget.teamAName, widget.teamBName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Compartir PDF",
            onPressed: () async {
              await PdfGenerator.generateAndShare(gameState, widget.teamAName, widget.teamBName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreBoard(context, gameState, controller), // <--- MODIFICADO: Pide context
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

  // <--- MODIFICADO: Agregamos BuildContext para abrir el diálogo
  Widget _buildScoreBoard(BuildContext context, MatchState state, MatchGameController controller) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    // <--- NUEVO: Texto dinámico para Tiempos Extra
    String periodText = state.currentPeriod <= 4 
        ? "PERIODO ${state.currentPeriod}" 
        : "TIEMPO EXTRA ${state.currentPeriod - 4}";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.black87,
      child: Column(
        children: [
          // <--- MODIFICADO: Ahora es clickeable para cambiar manualmente
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreText(state.scoreA.toString(), widget.teamAName),
              
              // RELOJ
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
                  child: Column(
                    children: [
                      Text(
                        "$minutes:$seconds",
                        style: TextStyle(
                          color: state.isRunning ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (!state.isRunning)
                        const Text("Mantén para editar", style: TextStyle(color: Colors.white38, fontSize: 10))
                    ],
                  ),
                ),
              ),
              
              _scoreText(state.scoreB.toString(), widget.teamBName),
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
                final stats =
                    state.playerStats[playerName] ?? const PlayerStats();

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
                      child: Text("${index + 4}"),
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

  // <--- NUEVO: Diálogo para seleccionar periodo manualmente
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

  // <--- NUEVO: Helper para opción de periodo
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
                  ElevatedButton(
                    onPressed: () {
                      controller.updateStats(teamId, playerName, fouls: 1);
                      Navigator.pop(context);
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

  // --- RESTO DE DIÁLOGOS ---

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
}