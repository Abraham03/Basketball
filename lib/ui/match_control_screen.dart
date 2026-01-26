import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/match_game_controller.dart';

class MatchControlScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(matchGameProvider);
    final controller = ref.read(matchGameProvider.notifier);

    // --- ESCUCHA DE EVENTOS (NOTIFICACIONES) ---
    // Esto se ejecuta solo cuando cambia el estado, no repinta la UI.
    ref.listen<MatchState>(matchGameProvider, (previous, next) {
      // Detectamos si alguien llegó a 5 faltas
      next.playerStats.forEach((playerId, stats) {
        final previousFouls = previous?.playerStats[playerId]?.fouls ?? 0;
        if (stats.fouls == 5 && previousFouls == 4) {
          // ALERTA VISUAL
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
          // BOTÓN DESHACER
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Deshacer última acción",
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
            icon: const Icon(Icons.save_alt),
            onPressed: () {
              /* Guardar PDF */
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
                Expanded(
                  child: _buildTeamColumn(
                    context,
                    teamAName,
                    Colors.orange.shade50,
                    'A',
                    controller,
                    gameState,
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                Expanded(
                  child: _buildTeamColumn(
                    context,
                    teamBName,
                    Colors.blue.shade50,
                    'B',
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreText(state.scoreA.toString(), teamAName),

              // RELOJ + CONTROLES DE TIEMPO
              Column(
                children: [
                  GestureDetector(
                    onTap: () => controller.toggleTimer(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
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
                      child: Text(
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
                    ),
                  ),
                  // BOTONES DE AJUSTE DE TIEMPO
                  if (!state
                      .isRunning) // Solo mostrar si está pausado para no estorbar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white70),
                          onPressed: () => controller.adjustTime(-1),
                          tooltip: "-1 Seg",
                        ),
                        const Text(
                          "Seg",
                          style: TextStyle(color: Colors.white30),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white70),
                          onPressed: () => controller.adjustTime(1),
                          tooltip: "+1 Seg",
                        ),
                      ],
                    ),
                ],
              ),

              _scoreText(state.scoreB.toString(), teamBName),
            ],
          ),
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
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(team, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildTeamColumn(
    BuildContext context,
    String teamName,
    Color bgColor,
    String teamId,
    MatchGameController controller,
    MatchState state,
  ) {
    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            width: double.infinity,
            color: Colors.black12,
            child: Text(
              teamName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 5,
              itemBuilder: (context, index) {
                // Generamos ID único para el mapa (Ej: "A_1")
                // En la app real usarás el UUID del jugador
                final playerId = "${teamId}_$index";
                final playerStats =
                    state.playerStats[playerId] ?? const PlayerStats();

                // Detectar si está en peligro (4 faltas) o fuera (5)
                Color? cardColor;
                if (playerStats.fouls == 4) cardColor = Colors.orange.shade100;
                if (playerStats.fouls >= 5) cardColor = Colors.red.shade100;

                return Card(
                  color: cardColor,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      child: Text(
                        "${4 + index}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      "Jugador ${index + 1}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    // MOSTRAMOS STATS REALES
                    subtitle: Text(
                      "${playerStats.points} Pts | ${playerStats.fouls} Faltas",
                      style: TextStyle(
                        color: playerStats.fouls >= 5
                            ? Colors.red
                            : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      if (playerStats.fouls >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Jugador expulsado.")),
                        );
                        return;
                      }

                      // Menú de Acciones
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                "Jugador ${index + 1} ($teamName)",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _actionButton(
                                    context,
                                    "+1",
                                    Colors.blue,
                                    () => controller.updateStats(
                                      teamId,
                                      playerId,
                                      points: 1,
                                    ),
                                  ),
                                  _actionButton(
                                    context,
                                    "+2",
                                    Colors.green,
                                    () => controller.updateStats(
                                      teamId,
                                      playerId,
                                      points: 2,
                                    ),
                                  ),
                                  _actionButton(
                                    context,
                                    "+3",
                                    Colors.orange,
                                    () => controller.updateStats(
                                      teamId,
                                      playerId,
                                      points: 3,
                                    ),
                                  ),
                                  _actionButton(
                                    context,
                                    "Falta",
                                    Colors.red,
                                    () => controller.updateStats(
                                      teamId,
                                      playerId,
                                      fouls: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      onPressed: () {
        onTap();
        Navigator.pop(context);
      },
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
