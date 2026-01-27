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
    // Inicializamos el partido al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchGameProvider.notifier).initMatch(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchGameProvider);
    final controller = ref.read(matchGameProvider.notifier);

    // Listener para alertas (5 faltas)
    ref.listen<MatchState>(matchGameProvider, (previous, next) {
      next.playerStats.forEach((playerId, stats) {
        final previousFouls = previous?.playerStats[playerId]?.fouls ?? 0;
        // Solo mostramos alerta si acaba de subir a 5 (para no spammear)
        if (stats.fouls == 5 && previousFouls == 4) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🚨 Límite de Faltas"),
              content: Text("El jugador $playerId ha llegado a 5 faltas."),
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
                const SnackBar(
                  content: Text("Acción deshecha"),
                  duration: Duration(milliseconds: 500),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Generar PDF",
            onPressed: () async {
              // Llamamos al generador pasando el estado actual
              await PdfGenerator.generateAndPreview(
                gameState,
                widget.teamAName,
                widget.teamBName,
              );
            },
          ),
          // BOTÓN 2: COMPARTIR (Nuevo)
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Compartir PDF",
            onPressed: () async {
              await PdfGenerator.generateAndShare(
                gameState,
                widget.teamAName,
                widget.teamBName,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreBoard(gameState, controller),
          Expanded(
            child: Row(
              children: [
                // EQUIPO A
                Expanded(
                  child: _buildTeamColumn(
                    context,
                    widget.teamAName,
                    Colors.orange.shade50,
                    'A',
                    gameState.teamAOnCourt, // Solo cancha
                    gameState.teamABench, // Banca para cambios
                    controller,
                    gameState,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                // EQUIPO B
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

  Widget _buildScoreBoard(MatchState state, MatchGameController controller) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreText(state.scoreA.toString(), widget.teamAName),

          // --- RELOJ INTERACTIVO (CORREGIDO) ---
          GestureDetector(
            // UN TOQUE: SIEMPRE PAUSA O INICIA
            onTap: () => controller.toggleTimer(),

            // MANTENER PRESIONADO: EDITA (Solo si está pausado para evitar errores)
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
                  color: state.isRunning
                      ? Colors.greenAccent
                      : Colors.redAccent,
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
                      color: state.isRunning
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  // Indicador visual pequeño para que sepan que pueden editar
                  if (!state.isRunning)
                    const Text(
                      "Mantén para editar",
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                ],
              ),
            ),
          ),

          _scoreText(state.scoreB.toString(), widget.teamBName),
        ],
      ),
    );
  }

  Widget _scoreText(String score, String team) {
    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
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
          // CABECERA + BOTÓN DE CAMBIO
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

          // LISTA JUGADORES (SOLO CANCHA)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: onCourt.length,
              itemBuilder: (context, index) {
                final playerName = onCourt[index];
                final stats =
                    state.playerStats[playerName] ?? const PlayerStats();

                // --- COLORES DE FALTAS (CORREGIDO) ---
                Color? cardColor;
                Color textColor = Colors.black; // Color de texto por defecto

                if (stats.fouls == 4) {
                  // Falta 4: Amarillo fuerte
                  cardColor = Colors.yellow.shade400;
                } else if (stats.fouls >= 5) {
                  // Falta 5: Rojo intenso y texto blanco
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
                        color: textColor, // Aplicar color de texto
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

  // DIÁLOGO PICKER DE TIEMPO (SCROLLABLE)
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

  // DIÁLOGO DE SUSTITUCIÓN
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

  void _showActionMenu(
    BuildContext context,
    String teamId,
    String playerName,
    MatchGameController controller,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Column(
          children: [
            Text(
              playerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
}
