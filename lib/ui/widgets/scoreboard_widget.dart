// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../logic/match_game_controller.dart';

class ScoreboardWidget extends StatelessWidget {
  final MatchState state;
  final MatchGameController? controller; 
  final String teamAName;
  final String teamBName;
  final int teamAFouls;
  final int teamBFouls;

  final bool isReadOnly; 
  final bool isFinished;
  final VoidCallback? onPeriodTap;
  final VoidCallback? onTimeLongPress;

  const ScoreboardWidget({
    super.key,
    required this.state,
    this.controller,
    required this.teamAName,
    required this.teamBName,
    required this.teamAFouls,
    required this.teamBFouls,
    this.isReadOnly = false,
    this.isFinished = false,
    this.onPeriodTap,
    this.onTimeLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    // Estilos de Score
    TextStyle scoreStyleA = const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.blueAccent, fontFamily: "monospace", height: 1.1);
    TextStyle scoreStyleB = const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.redAccent, fontFamily: "monospace", height: 1.1);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: const Border(bottom: BorderSide(color: Colors.white24, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- EQUIPO A ---
              Expanded(
                child: Column(
                  children: [
                    Text(teamAName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(state.scoreA.toString().padLeft(2, '0'), style: scoreStyleA),
                    // Tiempos Fuera Equipo A
                    _buildTimeoutDots(state.teamATimeouts1, state.teamATimeouts2, state.teamAOTTimeouts, Colors.blueAccent, state.currentPeriod),
                    const SizedBox(height: 4),
                    _buildCompactFouls(teamAFouls, Colors.blueAccent),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: (isReadOnly || isFinished) ? null : () => controller?.setPossession('A'),
                      child: Icon(Icons.sports_basketball, color: state.possession == 'A' ? Colors.limeAccent : Colors.white24, size: 28),
                    )
                  ],
                ),
              ),

              // --- CENTRO: RELOJ Y PERIODO ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: (isReadOnly || isFinished) ? null : onPeriodTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amberAccent.withOpacity(0.5))),
                        child: Text(state.currentPeriod <= 4 ? "PER ${state.currentPeriod}" : "EXT ${state.currentPeriod - 4}", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: (isReadOnly || isFinished) ? null : controller?.toggleTimer,
                      onLongPress: (isReadOnly || isFinished || state.isRunning) ? null : onTimeLongPress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: state.isRunning ? Colors.greenAccent : Colors.redAccent, width: 2)),
                        child: Text("$minutes:$seconds", style: TextStyle(color: state.isRunning ? Colors.greenAccent : Colors.amber, fontSize: 34, fontWeight: FontWeight.w900, fontFamily: "monospace")),
                      ),
                    ),
                  ],
                ),
              ),

              // --- EQUIPO B ---
              Expanded(
                child: Column(
                  children: [
                    Text(teamBName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(state.scoreB.toString().padLeft(2, '0'), style: scoreStyleB),
                    // Tiempos Fuera Equipo B
                    _buildTimeoutDots(state.teamBTimeouts1, state.teamBTimeouts2, state.teamBOTTimeouts, Colors.redAccent, state.currentPeriod),
                    const SizedBox(height: 4),
                    _buildCompactFouls(teamBFouls, Colors.redAccent),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: (isReadOnly || isFinished) ? null : () => controller?.setPossession('B'),
                      child: Icon(Icons.sports_basketball, color: state.possession == 'B' ? Colors.limeAccent : Colors.white24, size: 28),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para los puntos de Tiempos Fuera
  Widget _buildTimeoutDots(List<String> t1, List<String> t2, List<String> tOT, Color activeColor, int currentPeriod) {
    if (currentPeriod >= 5) {
       return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for(int i = 0; i < 3; i++) Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: i < tOT.length ? activeColor : Colors.white10)),
       ]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for(int i=0; i<2; i++) Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: i < t1.length ? activeColor : Colors.white10)),
        const SizedBox(width: 6),
        for(int i=0; i<3; i++) Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: i < t2.length ? activeColor : Colors.white10)),
      ],
    );
  }

  Widget _buildCompactFouls(int fouls, Color color) {
    bool isPenalty = fouls >= 5;
    int displayFouls = fouls > 4 ? 4 : fouls;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: isPenalty ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6), border: Border.all(color: isPenalty ? Colors.redAccent : Colors.white10)),
      child: Text("FALTAS: $displayFouls", style: TextStyle(color: isPenalty ? Colors.redAccent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}