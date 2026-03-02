import 'package:flutter/material.dart';
import '../../logic/match_game_controller.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size;
        double h = size.height;

        final minutes = state.timeLeft.inMinutes.toString().padLeft(2, '0');
        final seconds = (state.timeLeft.inSeconds % 60).toString().padLeft(2, '0');
        
        final double scoreFontSize = h * 0.45;
        final double timeFontSize = scoreFontSize; 
        final double nameFontSize = h * 0.08;
        final double arrowSize = h * 0.25; 
        final double periodFontSize = h * 0.05; 

        TextStyle scoreStyleA = TextStyle(fontSize: scoreFontSize, fontWeight: FontWeight.w900, color: Colors.blueAccent, fontFamily: "monospace", height: 1.0, shadows: [Shadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)]);
        TextStyle scoreStyleB = TextStyle(fontSize: scoreFontSize, fontWeight: FontWeight.w900, color: Colors.redAccent, fontFamily: "monospace", height: 1.0, shadows: [Shadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 20)]);
        TextStyle nameStyle = TextStyle(fontSize: nameFontSize, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4.0);

        Widget periodWidget = Container(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 4), borderRadius: BorderRadius.circular(16), color: Colors.amberAccent.withOpacity(0.1)),
          child: Text(
            state.currentPeriod <= 4 ? "PERIODO ${state.currentPeriod}" : "EXTRA ${state.currentPeriod - 4}",
            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: periodFontSize),
          ),
        );

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          color: Colors.black, // Fondo negro absoluto para monitores
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: h * 0.05),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(teamAName.toUpperCase(), style: nameStyle)),
                        SizedBox(height: h * 0.02),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreA.toString().padLeft(2, '0'), style: scoreStyleA)),
                        SizedBox(height: h * 0.02),
                        _buildTimeoutDots(state.teamATimeouts1, state.teamATimeouts2, state.teamAOTTimeouts, Colors.blueAccent, state.currentPeriod, h),
                        const SizedBox(height: 8),
                        Text("T. FUERA", style: TextStyle(color: Colors.white54, fontSize: h * 0.03, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        SizedBox(height: h * 0.03),
                        _buildCompactFouls(teamAFouls, Colors.blueAccent, h),
                      ],
                    ),
                  ),
                  Expanded(flex: 4, child: const SizedBox.shrink()),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: h * 0.05),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(teamBName.toUpperCase(), style: nameStyle)),
                        SizedBox(height: h * 0.02),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(state.scoreB.toString().padLeft(2, '0'), style: scoreStyleB)),
                        SizedBox(height: h * 0.02),
                        _buildTimeoutDots(state.teamBTimeouts1, state.teamBTimeouts2, state.teamBOTTimeouts, Colors.redAccent, state.currentPeriod, h),
                        const SizedBox(height: 8),
                        Text("T. FUERA", style: TextStyle(color: Colors.white54, fontSize: h * 0.03, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        SizedBox(height: h * 0.03),
                        _buildCompactFouls(teamBFouls, Colors.redAccent, h),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: h * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      periodWidget, 
                      SizedBox(height: h * 0.05),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: state.isRunning ? Colors.greenAccent : Colors.amber, width: 6),
                          boxShadow: [BoxShadow(color: state.isRunning ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3), blurRadius: 30)]
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "$minutes:$seconds", 
                            style: TextStyle(fontSize: timeFontSize, fontWeight: FontWeight.w900, fontFamily: "monospace", color: state.isRunning ? Colors.greenAccent : Colors.amber, height: 1.0, shadows: [Shadow(color: state.isRunning ? Colors.green : Colors.orange, blurRadius: 10)])
                          ),
                        ),
                      ),
                      if (!state.isRunning)
                        Padding(
                          padding: const EdgeInsets.only(top: 10), 
                          child: Text(isFinished ? "FINALIZADO" : "RELOJ DETENIDO", style: TextStyle(color: Colors.white54, fontSize: h * 0.03, fontWeight: FontWeight.w900, letterSpacing: 4), textAlign: TextAlign.center,)
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: h * 0.05, left: 40,
                child: _buildLargePossessionArrow(isActive: state.possession == 'A', color: Colors.limeAccent, icon: Icons.arrow_back_ios_new_rounded, size: arrowSize),
              ),
              Positioned(
                bottom: h * 0.05, right: 40,
                child: _buildLargePossessionArrow(isActive: state.possession == 'B', color: Colors.limeAccent, icon: Icons.arrow_forward_ios_rounded, size: arrowSize),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildLargePossessionArrow({required bool isActive, required Color color, required IconData icon, required double size}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18), 
      decoration: BoxDecoration(color: isActive ? color.withOpacity(0.15) : Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? color : Colors.white10, width: 6), boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)] : []),
      child: Icon(icon, color: isActive ? color : Colors.white24, size: size),
    );
  }

  Widget _buildTimeoutDots(List<String> t1, List<String> t2, List<String> tOT, Color activeColor, int currentPeriod, double h) {
    double dotSize = h * 0.04;
    double spacing = 16;
    if (currentPeriod >= 5) {
       return Wrap(alignment: WrapAlignment.center, spacing: spacing, runSpacing: spacing, children: [for(int i = 0; i < 3; i++) Container(width: dotSize, height: dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: i < tOT.length ? activeColor : Colors.white24, boxShadow: i < tOT.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: 15)] : null))]);
    }
    return Wrap(alignment: WrapAlignment.center, spacing: spacing, runSpacing: spacing, children: [
        for(int i=0; i<2; i++) Container(width: dotSize, height: dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: i < t1.length ? activeColor : Colors.white24, boxShadow: i < t1.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: 15)] : null)),
        const SizedBox(width: 30),
        for(int i=0; i<3; i++) Container(width: dotSize, height: dotSize, decoration: BoxDecoration(shape: BoxShape.circle, color: i < t2.length ? activeColor : Colors.white24, boxShadow: i < t2.length ? [BoxShadow(color: activeColor.withOpacity(0.8), blurRadius: 15)] : null)),
    ]);
  }

  Widget _buildCompactFouls(int fouls, Color color, double h) {
    bool isPenalty = fouls >= 5;
    int displayFouls = fouls > 4 ? 4 : fouls;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(color: isPenalty ? Colors.redAccent.withOpacity(0.3) : Colors.white10, border: Border.all(color: isPenalty ? Colors.redAccent : Colors.white24, width: 4), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Text("FALTAS: ", style: TextStyle(color: Colors.white70, fontSize: h * 0.03, fontWeight: FontWeight.w900)),
          Text("$displayFouls", style: TextStyle(color: isPenalty ? Colors.redAccent : Colors.white, fontSize: h * 0.07, fontWeight: FontWeight.w900, fontFamily: "monospace")),
        ]
      ),
    );
  }
}