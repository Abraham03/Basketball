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
  final bool isWideScreen;
  final bool isLandscape;
  final bool isReadOnly; 
  final bool isFinished;
  final bool isFullScreen; 
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
    required this.isWideScreen,
    required this.isLandscape,
    this.isReadOnly = false,
    this.isFinished = false,
    this.isFullScreen = false, 
    this.onPeriodTap,
    this.onTimeLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        
        // Calculamos la altura disponible
        double h = isFullScreen ? size.height : constraints.maxHeight;
        if (h == double.infinity || h == 0) h = size.height;

        final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
        final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');
        
        // RELOJ DEL MISMO TAMAÑO QUE EL SCORE
        final double scoreFontSize = isFullScreen ? h * 0.40 : (isWideScreen ? (isLandscape ? 70 : 90) : 55);
        final double timeFontSize = scoreFontSize; // <--- IGUALADO AL SCORE
        final double nameFontSize = isFullScreen ? h * 0.08 : (isWideScreen ? (isLandscape ? 14 : 18) : 14);
        
        // FLECHA DE POSESIÓN MÁS GRANDE
        final double arrowSize = isFullScreen ? h * 0.25 : (isWideScreen ? (isLandscape ? 65 : 75) : 50); 
        final double periodFontSize = isFullScreen ? h * 0.04 : (isWideScreen ? 12 : 10); 

        // COLORES AZUL Y ROJO CON FUENTE ULTRA GRUESA
        TextStyle scoreStyleA = TextStyle(fontSize: scoreFontSize, fontWeight: FontWeight.w900, color: Colors.blueAccent, fontFamily: "monospace", height: 1.0, shadows: [Shadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)]);
        TextStyle scoreStyleB = TextStyle(fontSize: scoreFontSize, fontWeight: FontWeight.w900, color: Colors.redAccent, fontFamily: "monospace", height: 1.0, shadows: [Shadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 20)]);
        TextStyle nameStyle = TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: isFullScreen ? 4.0 : (isWideScreen ? 2.0 : 1.0));

        // Widget del Periodo
        Widget periodWidget = GestureDetector(
          onTap: (isReadOnly || isFinished) ? null : onPeriodTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isFullScreen ? 30 : 16, vertical: isFullScreen ? 8 : 4),
            decoration: BoxDecoration(border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2), borderRadius: BorderRadius.circular(8), color: Colors.amberAccent.withOpacity(0.1)),
            child: Text(
              state.currentPeriod <= 4 ? "PERIODO ${state.currentPeriod}" : "EXTRA ${state.currentPeriod - 4}",
              style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: periodFontSize),
            ),
          ),
        );

        Widget mainContent = Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alineado arriba
          children: [
            // ================= TEAM A (AZUL) =================
            Expanded(
              flex: isFullScreen ? 3 : (isWideScreen ? 1 : 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: isFullScreen ? h * 0.05 : 10), // Margen superior
                  FittedBox(fit: BoxFit.scaleDown, child: Text(teamAName.toUpperCase(), style: nameStyle, textAlign: TextAlign.center)),
                  SizedBox(height: isFullScreen ? h * 0.02 : 4),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreA.toString().padLeft(2, '0'), style: scoreStyleA)),
                  SizedBox(height: isFullScreen ? h * 0.02 : 8),
                  
                  // Puntos de Tiempos Fuera + Etiqueta
                  _buildTimeoutDots(state.teamATimeouts1, state.teamATimeouts2, state.teamAOTTimeouts, Colors.blueAccent, isWideScreen, state.currentPeriod, isFullScreen, h),
                  SizedBox(height: 4),
                  Text("T. FUERA", style: TextStyle(color: Colors.white54, fontSize: isFullScreen ? h * 0.025 : 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  
                  SizedBox(height: isFullScreen ? h * 0.02 : 8),
                  _buildCompactFouls(teamAFouls, Colors.blueAccent, isWideScreen, isFullScreen, h),
                ],
              ),
            ),
            
            // ================= COLUMNA CENTRAL (RELOJ + POSESIÓN) =================
            Expanded(
              flex: isFullScreen ? 4 : (isWideScreen ? 1 : (isLandscape ? 2 : 3)), 
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isFullScreen ? 20 : (isLandscape ? 4 : 8)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // <-- RELOJ EN EL MEDIO
                  children: [
                    periodWidget, 
                    SizedBox(height: isFullScreen ? h * 0.05 : 15), // Espacio extra para bajar el reloj
                    
                    // Reloj Gigante (Mismo font que el score)
                    GestureDetector(
                      onTap: (isReadOnly || isFinished) ? null : controller?.toggleTimer,
                      onLongPress: (isReadOnly || isFinished || state.isRunning) ? null : onTimeLongPress,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isFullScreen ? 20 : 10, vertical: isFullScreen ? 5 : 5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: state.isRunning ? Colors.greenAccent : Colors.amber, width: isFullScreen ? 6 : 3),
                          boxShadow: [BoxShadow(color: state.isRunning ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3), blurRadius: isFullScreen ? 30 : 20)]
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "$minutes:$seconds", 
                            style: TextStyle(
                              fontSize: timeFontSize, 
                              fontWeight: FontWeight.w900, 
                              fontFamily: "monospace", 
                              color: state.isRunning ? Colors.greenAccent : Colors.amber, 
                              height: 1.0,
                              shadows: [Shadow(color: state.isRunning ? Colors.green : Colors.orange, blurRadius: 10)]
                            )
                          ),
                        ),
                      ),
                    ),
                    if (!state.isRunning)
                      Padding(
                        padding: const EdgeInsets.only(top: 6), 
                        child: Text(isFinished ? "FINALIZADO" : "RELOJ DETENIDO", style: TextStyle(color: Colors.white54, fontSize: isFullScreen ? h * 0.03 : 9, fontWeight: FontWeight.w900, letterSpacing: 2), textAlign: TextAlign.center,)
                      ),
                      
                    // Posesión gigante, separada y sin texto "POSS"
                    SizedBox(height: isFullScreen ? h * 0.10 : 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Empuja las flechas a los extremos
                      children: [
                        _buildLargePossessionArrow(isActive: state.possession == 'A', color: Colors.limeAccent, icon: Icons.arrow_back_ios_new_rounded, size: arrowSize, isFullScreen: isFullScreen, onTap: (isReadOnly || isFinished) ? null : () => controller?.setPossession('A')),
                        // El contenedor del texto "POSS" fue eliminado completamente
                        const Spacer(), 
                        _buildLargePossessionArrow(isActive: state.possession == 'B', color: Colors.limeAccent, icon: Icons.arrow_forward_ios_rounded, size: arrowSize, isFullScreen: isFullScreen, onTap: (isReadOnly || isFinished) ? null : () => controller?.setPossession('B')),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // ================= TEAM B (ROJO) =================
            Expanded(
              flex: isFullScreen ? 3 : (isWideScreen ? 1 : 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: isFullScreen ? h * 0.05 : 10), // Margen superior
                  FittedBox(fit: BoxFit.scaleDown, child: Text(teamBName.toUpperCase(), style: nameStyle, textAlign: TextAlign.center)),
                  SizedBox(height: isFullScreen ? h * 0.02 : 4),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreB.toString().padLeft(2, '0'), style: scoreStyleB)),
                  SizedBox(height: isFullScreen ? h * 0.02 : 8),
                  
                  // Puntos de Tiempos Fuera + Etiqueta
                  _buildTimeoutDots(state.teamBTimeouts1, state.teamBTimeouts2, state.teamBOTTimeouts, Colors.redAccent, isWideScreen, state.currentPeriod, isFullScreen, h),
                  SizedBox(height: 4),
                  Text("T. FUERA", style: TextStyle(color: Colors.white54, fontSize: isFullScreen ? h * 0.025 : 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  
                  SizedBox(height: isFullScreen ? h * 0.02 : 8),
                  _buildCompactFouls(teamBFouls, Colors.redAccent, isWideScreen, isFullScreen, h),
                ],
              ),
            ),
          ],
        );

        return ClipRRect(
          borderRadius: isLandscape && !isFullScreen ? BorderRadius.circular(20) : (isFullScreen ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(30))),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
            child: Container(
              width: isFullScreen ? double.infinity : null,
              height: isFullScreen ? double.infinity : null,
              margin: isLandscape && !isFullScreen ? const EdgeInsets.only(left: 8, top: 8, bottom: 8) : EdgeInsets.zero,
              padding: EdgeInsets.fromLTRB(16, isFullScreen ? 20 : 8, 16, isFullScreen ? 20 : 16),
              decoration: BoxDecoration(
                color: isFullScreen ? Colors.black : Colors.black.withOpacity(0.5), 
                border: isFullScreen ? null : Border.all(color: Colors.white24, width: 2), 
                borderRadius: isLandscape && !isFullScreen ? BorderRadius.circular(20) : null,
              ),
              child: mainContent,
            ),
          ),
        );
      }
    );
  }

  Widget _buildLargePossessionArrow({required bool isActive, required Color color, required IconData icon, required double size, required bool isFullScreen, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        // Aumentamos el padding para que el cuadro sea más grande
        padding: EdgeInsets.all(isFullScreen ? 18 : 8), 
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.black26, 
          borderRadius: BorderRadius.circular(isFullScreen ? 20 : 12), 
          border: Border.all(color: isActive ? color : Colors.white10, width: isFullScreen ? 6 : 2), 
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: isFullScreen ? 30 : 15, spreadRadius: isFullScreen ? 5 : 2)] : []
        ),
        child: Icon(icon, color: isActive ? color : Colors.white24, size: size),
      ),
    );
  }

  Widget _buildTimeoutDots(List<String> t1, List<String> t2, List<String> tOT, Color activeColor, bool isWideScreen, int currentPeriod, bool isFullScreen, double h) {
    double dotSize = isFullScreen ? h * 0.04 : (isWideScreen ? 14 : 10);
    double spacing = isFullScreen ? 16 : (isWideScreen ? 6 : 4);
    
    if (currentPeriod >= 5) {
       return Wrap(alignment: WrapAlignment.center, spacing: spacing, runSpacing: spacing, children: [
            for(int i = 0; i < 3; i++) Container(width: dotSize, height: dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: i < tOT.length ? activeColor : Colors.white24, boxShadow: i < tOT.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: isFullScreen ? 15 : 8)] : null)),
       ]);
    }
    return Wrap(alignment: WrapAlignment.center, spacing: spacing, runSpacing: spacing, children: [
        for(int i=0; i<2; i++) Container(width: dotSize, height: dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: i < t1.length ? activeColor : Colors.white24, boxShadow: i < t1.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: isFullScreen ? 15 : 8)] : null)),
        SizedBox(width: isFullScreen ? 30 : (isWideScreen ? 10 : 6)),
        for(int i=0; i<3; i++) Container(width: dotSize, height: dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: i < t2.length ? activeColor : Colors.white24, boxShadow: i < t2.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: isFullScreen ? 15 : 8)] : null)),
    ]);
  }

  Widget _buildCompactFouls(int fouls, Color color, bool isWideScreen, bool isFullScreen, double h) {
    bool isPenalty = fouls >= 5;
    int displayFouls = fouls > 4 ? 4 : fouls;
    
    double fontSize = isFullScreen ? h * 0.07 : (isWideScreen ? 18 : 14);
    double labelSize = isFullScreen ? h * 0.03 : (isWideScreen ? 12 : 10);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isFullScreen ? 30 : (isWideScreen ? 16 : 8), vertical: isFullScreen ? 10 : 4),
      decoration: BoxDecoration(color: isPenalty ? Colors.redAccent.withOpacity(0.3) : Colors.white10, border: Border.all(color: isPenalty ? Colors.redAccent : Colors.white24, width: isFullScreen ? 4 : 2), borderRadius: BorderRadius.circular(isFullScreen ? 16 : 8)),
      child: FittedBox(
        fit: BoxFit.scaleDown, 
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text("FALTAS: ", style: TextStyle(color: Colors.white70, fontSize: labelSize, fontWeight: FontWeight.w900)),
            Text("$displayFouls", style: TextStyle(color: isPenalty ? Colors.redAccent : Colors.white, fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: "monospace")),
          ]
        )
      ),
    );
  }
}