// ignore_for_file: unnecessary_import, deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../logic/match_game_controller.dart';

/// MARCADOR PROFESIONAL BROADCAST - DISEÑO ESCALABLE Y MODERNO
class TvScoreboardWidget extends StatelessWidget {
  final MatchState state;
  final String teamAName;
  final String teamBName;
  final int teamAFouls;
  final int teamBFouls;
  final bool isFinished;

  const TvScoreboardWidget({
    super.key,
    required this.state,
    required this.teamAName,
    required this.teamBName,
    required this.teamAFouls,
    required this.teamBFouls,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // 'h' y 'w' son nuestras unidades base para que todo escale proporcionalmente.
      final double h = constraints.maxHeight;
      final double w = constraints.maxWidth;

      final String minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
      final String seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');

      // Estilo digital refinado con doble sombra para efecto de iluminación neón real.
      TextStyle digitalStyle(double size, Color color) => TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: "monospace",
            height: 1.0,
            letterSpacing: -2,
            shadows: [
              Shadow(color: color.withOpacity(0.8), blurRadius: size * 0.1),
              Shadow(color: color.withOpacity(0.4), blurRadius: size * 0.3),
            ],
          );

      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF050505), // Negro profundo mate para look profesional
        ),
        child: Column(
          children: [
            // ================= SECCIÓN 1: RELOJ Y FLECHAS (Alto 40%) =================
            // Usamos un Row con anchos relativos (25% - 50% - 25%) para que las flechas
            // siempre orbiten cerca del reloj independientemente del ancho de pantalla.
            SizedBox(
              height: h * 0.40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lado Izquierdo: Posesión A (Alineada a la derecha de su espacio)
                  SizedBox(
                    width: w * 0.25,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: w * 0.00),
                        child: _buildPossessionIndicator(isActive: state.possession == 'A', h: h, isLeft: true),
                      ),
                    ),
                  ),

                  // Centro: Cronómetro (Ancho contenido al 50% para simetría)
                  SizedBox(
                    width: w * 0.50,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text("$minutes:$seconds",
                            style: digitalStyle(h * 0.40, 
                                state.isRunning ? const Color(0xFFFF3131) : Colors.red.shade900)),
                      ),
                    ),
                  ),

                  // Lado Derecho: Posesión B (Alineada a la izquierda de su espacio)
                  SizedBox(
                    width: w * 0.25,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(right: w * 0.00),
                        child: _buildPossessionIndicator(isActive: state.possession == 'B', h: h, isLeft: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= SECCIÓN 2: CINTA DE NOMBRES Y PERIODO (Alto 12%) =================
            SizedBox(
              height: h * 0.12,
              child: Row(
                children: [
                  _buildTeamBanner(teamAName, const Color(0xFF0066FF), true), // Azul Pro
                  
                  // Caja de Periodo Estilo Broadcast
                  Container(
                    width: w * 0.15,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("PERIOD", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: h * 0.022, letterSpacing: 1)),
                        Text("${state.currentPeriod}", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: h * 0.05)),
                      ],
                    ),
                  ),

                  _buildTeamBanner(teamBName, const Color(0xFFD81B60), false), // Rosa Pro
                ],
              ),
            ),

            // ================= SECCIÓN 3: SCORE Y STATS (Resto del alto) =================
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: h * 0.02, bottom: h * 0.05),
                child: Row(
                  children: [
                    // Columna Equipo A
                    _buildScoreColumn(state.scoreA, teamAFouls, state.teamATimeouts1, state.teamATimeouts2, state.teamAOTTimeouts, const Color(0xFF00D4FF), state.currentPeriod, h, digitalStyle),
                    
                    // Divisor de cristal sutil
                    Container(width: 1, height: h * 0.25, color: Colors.white12),

                    // Columna Equipo B
                    _buildScoreColumn(state.scoreB, teamBFouls, state.teamBTimeouts1, state.teamBTimeouts2, state.teamBOTTimeouts, const Color(0xFFFF1E63), state.currentPeriod, h, digitalStyle),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- MÉTODOS DE COMPONENTES MODIFICABLES ---

  /// INDICADOR DE POSESIÓN (FLECHAS)
  /// Para cambiar el tamaño, modifica el multiplicador h * 0.55
  Widget _buildPossessionIndicator({required bool isActive, required double h, required bool isLeft}) {
    const Color activeColor = Color(0xFFCCFF00); // Verde Neón
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.05,
      child: Icon(
        isLeft ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
        size: h * 0.55, 
        color: activeColor,
        shadows: [if (isActive) Shadow(color: activeColor.withOpacity(0.9), blurRadius: 30)],
      ),
    );
  }

  /// BANNER DE EQUIPO (NOMBRES)
  /// Tiene un gradiente moderno y un borde inferior estilizado.
  Widget _buildTeamBanner(String name, Color color, bool isLeft) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.6)],
            begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          ),
          border: Border(bottom: BorderSide(color: color.withOpacity(0.4), width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 60, letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }

  /// COLUMNA DE SCORE Y STATS
  /// Organiza los puntos y los indicadores inferiores.
  Widget _buildScoreColumn(int score, int fouls, List<String> t1, List<String> t2, List<String> tOT, Color color, int period, double h, Function style) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(score.toString().padLeft(2, '0'), style: style(h * 0.40, color)),
            ),
          ),
          _buildStatsBadge(fouls, t1, t2, tOT, color, period, h),
        ],
      ),
    );
  }

  /// BADGE DE STATS (FALTAS Y T.O.)
  /// Agrupa las faltas en una caja y los Tiempos Fuera en círculos.
  Widget _buildStatsBadge(int fouls, List<String> t1, List<String> t2, List<String> tOT, Color color, int period, double h) {
    final List<bool> activeStatus = (period >= 5)
        ? List.generate(3, (i) => i < tOT.length)
        : [...List.generate(2, (i) => i < t1.length), ...List.generate(3, (i) => i < t2.length)];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("F", style: TextStyle(color: Colors.white38, fontSize: h * 0.02, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text("$fouls", style: TextStyle(color: fouls >= 5 ? Colors.redAccent : color, fontSize: h * 0.045, fontWeight: FontWeight.w900)),
          SizedBox(width: h * 0.04),
          Text("T.O.", style: TextStyle(color: Colors.white38, fontSize: h * 0.02, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          ...activeStatus.map((active) => Container(
                width: h * 0.028,
                height: h * 0.028,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? color : Colors.black45,
                    border: Border.all(color: active ? Colors.white30 : Colors.white10, width: 1.5)),
              )),
        ],
      ),
    );
  }
}