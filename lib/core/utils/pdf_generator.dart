import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/match_game_controller.dart';

class PdfCoords {
  // --- 1. HEADER (ENCABEZADO) ---
  static const double headerY = 90.0;
  static const double competitionX = 390.0;
  static const double dateX = 195.0;
  static const double timeX = 270.0;
  static const double placeX = 180.0;
  static const double placeY = 105.0;
  static const double gameNoX = 100.0;

  // --- REFEREES & OFFICIALS (EN EL HEADER) ---
  static const double referee1X = 370.0;
  static const double referee1Y = 105.0;
  static const double referee2X = 510.0;
  static const double referee2Y = 105.0;

  // Lo ponemos a la derecha de los árbitros o abajo.
  //static const double scorekeeperX = 370.0; 
  //static const double scorekeeperY = 115.0;

  // --- FOOTER (FIRMAS AL FINAL DE LA HOJA) ---
  // Coordenada para los Arbitros en la parte inferior
  static const double footerY = 795.0; 
  static const double footerReferee1X = 80.0;   // Árbitro Principal
  static const double footerReferee2X = 215.0;   // Árbitro Auxiliar

  // Coordenada para firma del Anotador al final
  static const double footerScorekeeperY = 150.0;
  static const double footerScorekeeperX = 772.0;


  // Coordenada para el Equipo Ganador
  static const double winningTeamX = 400.0;
  static const double winningTeamY = 810.0; // Misma altura que score final aprox

  // --- 2. TEAM HEADERS ---
  static const double teamANameX = 115.0;
  static const double teamANameY = 123.0;
  static const double teamBNameX = 115.0;
  static const double teamBNameY = 405.0;

  static const double teamAName2X = 130.0;
  static const double teamAName2Y = 55.0;
  static const double teamBName2X = 390.0;
  static const double teamBName2Y = 55.0;

  // --- 3. ROSTER TABLES ---
  static const double teamAListStartY = 312.0;
  static const double teamAColNumX = 199.0;
  static const double teamAColNameX = 50.0;
  static const double teamAColFoulsX = 235.0;
  static const double teamAColEntryX = 215.5; // Ajustado a la columna de entrada

  static const double teamBListStartY = 594.9;
  static const double teamBColNumX = 199.0;
  static const double teamBColNameX = 50.0;
  static const double teamBColFoulsX = 235.0;
  static const double teamBColEntryX = 215.5; // Ajustado a la columna de entrada

  static const double rowHeight = 13.5;
  static const double foulBoxWidth = 12.0;

  // --- 6. FINAL SCORE ---
  static const double scoreBoxY = 772.0;
  static const double scoreAX = 450.0;
  static const double scoreBX = 535.0;
  static const double scoreFontSize = 20.0;

  // --- 7. PERIOD SCORES ---
  static const double period1AX = 446.0;
  static const double period1BX = 532.0;
  static const double period1Y = 692.0;

  static const double period2AX = 446.0;
  static const double period2BX = 532.0;
  static const double period2Y = 707.0;

  static const double period3AX = 446.0;
  static const double period3BX = 532.0;
  static const double period3Y = 723.0;

  static const double period4AX = 446.0;
  static const double period4BX = 532.0;
  static const double period4Y = 740.0;

  static const double overtimeAX = 446.0;
  static const double overtimeBX = 532.0;
  static const double overtimeY = 755.0;

  // --- 9. RUNNING SCORE ---
  static const double runScoreCol1X = 335.0;
  static const double runScoreTeamSpacing = 10.0;
  static const double runScoreBlockSpacing = 68.0;
  static const double playerNumOffsetX = -18.0;
  static const double runScoreStartY = 157.0;
  static const double runScoreEndY = 680.0;
}

class PdfGenerator {
  static Future<void> generateAndPreview(
    MatchState state,
    String teamAName,
    String teamBName, {
    String tournamentName = "",
    String venueName = "",
    String mainReferee = "",
    String auxReferee = "",
    String scorekeeper = "",
  }) async {
    final pdf = await _buildDocument(
      state,
      teamAName,
      teamBName,
      tournamentName,
      venueName,
      mainReferee,
      auxReferee,
      scorekeeper,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> generateAndShare(
    MatchState state,
    String teamAName,
    String teamBName, {
    String tournamentName = "",
    String venueName = "",
    String mainReferee = "",
    String auxReferee = "",
    String scorekeeper = "",
  }) async {
    final pdf = await _buildDocument(
      state,
      teamAName,
      teamBName,
      tournamentName,
      venueName,
      mainReferee,
      auxReferee,
      scorekeeper,
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Acta_de_juego_${teamAName}_vs_$teamBName.pdf',
    );
  }

  static Future<pw.Document> _buildDocument(
    MatchState state,
    String teamAName,
    String teamBName,
    String tournamentName,
    String venueName,
    String mainReferee,
    String auxReferee,
    String scorekeeper,
  ) async {
    final pdf = pw.Document();

    // LÓGICA PARA DETERMINAR EL GANADOR
    String winningTeam = "---";
    if (state.scoreA > state.scoreB) {
      winningTeam = teamAName.toUpperCase();
    } else if (state.scoreB > state.scoreA) {
      winningTeam = teamBName.toUpperCase();
    } else {
      winningTeam = "EMPATE";
    }

    try {
      final imageBytes = await rootBundle.load('assets/images/hoja_anotacion.png');
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),

                // --- HEADER INFO ---
                _drawText(
                  tournamentName,
                  x: PdfCoords.competitionX,
                  y: PdfCoords.headerY,
                  fontSize: 9,
                ),
                _drawText(
                  "001",
                  x: PdfCoords.gameNoX,
                  y: PdfCoords.placeY,
                  fontSize: 9,
                ),
                _drawText(
                  "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  x: PdfCoords.dateX,
                  y: PdfCoords.headerY,
                  fontSize: 9,
                ),
                _drawText(
                  "12:00",
                  x: PdfCoords.timeX,
                  y: PdfCoords.headerY,
                  fontSize: 9,
                ),
                _drawText(
                  venueName,
                  x: PdfCoords.placeX,
                  y: PdfCoords.placeY,
                  fontSize: 9,
                ),

                // --- OFFICIALS (HEADER) ---
                if (mainReferee.isNotEmpty) // Dibuja el arbitro principal
                  _drawText(
                    mainReferee,
                    x: PdfCoords.referee1X,
                    y: PdfCoords.referee1Y,
                    fontSize: 8,
                  ),
                if (auxReferee.isNotEmpty) // Dibuja el segundo arbitro
                  _drawText(
                    auxReferee,
                    x: PdfCoords.referee2X,
                    y: PdfCoords.referee2Y,
                    fontSize: 8,
                  ),

                // --- OFFICIALS (FOOTER - AL FINAL) ---
                if (mainReferee.isNotEmpty) // Dibuja el arbitro principal al final
                  _drawText(
                    mainReferee,
                    x: PdfCoords.footerReferee1X,
                    y: PdfCoords.footerY,
                    fontSize: 9,
                  ),
                if (auxReferee.isNotEmpty) // Dibuja el segundo arbitro al final
                  _drawText(
                    auxReferee,
                    x: PdfCoords.footerReferee2X,
                    y: PdfCoords.footerY,
                    fontSize: 9,
                  ),
                  // DIBUJA ANOTADOR (FOOTER)
                if (scorekeeper.isNotEmpty)
                  _drawText(
                    scorekeeper, 
                    x: PdfCoords.footerScorekeeperX, 
                    y: PdfCoords.footerScorekeeperY, 
                    fontSize: 9,
                    isBold: true
                    ),
                // DIBUJA EQUIPO GANADOR
                _drawText(
                  winningTeam, 
                  x: PdfCoords.winningTeamX, 
                  y: PdfCoords.winningTeamY, 
                  fontSize: 10, 
                  isBold: true
                  ),
                // --- TEAM NAMES ---
                _drawText(
                  teamAName.toUpperCase(),
                  x: PdfCoords.teamANameX,
                  y: PdfCoords.teamANameY,
                  isBold: true,
                ),
                _drawText(
                  teamBName.toUpperCase(),
                  x: PdfCoords.teamBNameX,
                  y: PdfCoords.teamBNameY,
                  isBold: true,
                ),
                _drawText(
                  teamAName.toUpperCase(),
                  x: PdfCoords.teamAName2X,
                  y: PdfCoords.teamAName2Y,
                  isBold: true,
                  fontSize: 10,
                ),
                _drawText(
                  teamBName.toUpperCase(),
                  x: PdfCoords.teamBName2X,
                  y: PdfCoords.teamBName2Y,
                  isBold: true,
                  fontSize: 10,
                ),

                // --- ROSTERS ---
                ..._buildRosterList(
                  players: state.teamAOnCourt + state.teamABench,
                  stats: state.playerStats,
                  startXNum: PdfCoords.teamAColNumX,
                  startXName: PdfCoords.teamAColNameX,
                  startXFouls: PdfCoords.teamAColFoulsX,
                  startY: PdfCoords.teamAListStartY,
                  entryX: PdfCoords.teamAColEntryX,
                ),
                ..._buildRosterList(
                  players: state.teamBOnCourt + state.teamBBench,
                  stats: state.playerStats,
                  startXNum: PdfCoords.teamBColNumX,
                  startXName: PdfCoords.teamBColNameX,
                  startXFouls: PdfCoords.teamBColFoulsX,
                  startY: PdfCoords.teamBListStartY,
                  entryX: PdfCoords.teamBColEntryX,
                ),

                // --- SCORES ---
                _drawText(
                  "${state.scoreA}",
                  x: PdfCoords.scoreAX,
                  y: PdfCoords.scoreBoxY,
                  fontSize: PdfCoords.scoreFontSize,
                  isBold: true,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  "${state.scoreB}",
                  x: PdfCoords.scoreBX,
                  y: PdfCoords.scoreBoxY,
                  fontSize: PdfCoords.scoreFontSize,
                  isBold: true,
                  color: PdfColors.blue900,
                ),

                _drawPeriodScore(state, 1, PdfCoords.period1AX, PdfCoords.period1BX, PdfCoords.period1Y),
                _drawPeriodScore(state, 2, PdfCoords.period2AX, PdfCoords.period2BX, PdfCoords.period2Y),
                _drawPeriodScore(state, 3, PdfCoords.period3AX, PdfCoords.period3BX, PdfCoords.period3Y),
                _drawPeriodScore(state, 4, PdfCoords.period4AX, PdfCoords.period4BX, PdfCoords.period4Y),
                if (state.periodScores.containsKey(5))
                  _drawOvertimeScore(state, PdfCoords.overtimeAX, PdfCoords.overtimeBX, PdfCoords.overtimeY),

                ..._drawRunningScore(state.scoreLog),
              ],
            );
          },
        ),
      );
    } catch (e) {
      throw Exception('Error al generar PDF: $e');
    }
    return pdf;
  }

  static List<pw.Widget> _buildRosterList({
    required List<String> players,
    required Map<String, PlayerStats> stats,
    required double startXNum,
    required double startXName,
    required double startXFouls,
    required double startY,
    required double entryX,
  }) {
    List<pw.Widget> widgets = [];
    double currentY = startY;
    int limit = players.length > 12 ? 12 : players.length;

    for (var i = 0; i < limit; i++) {
      final playerName = players[i];
      final stat = stats[playerName] ?? const PlayerStats();
      final dorsal = stat.playerNumber.isNotEmpty ? stat.playerNumber : "";

      widgets.add(_drawText(dorsal, x: startXNum, y: currentY, fontSize: 10));
      String displayName = playerName.length > 18
          ? "${playerName.substring(0, 16)}..."
          : playerName;
      widgets.add(
        _drawText(displayName, x: startXName, y: currentY, fontSize: 10),
      );

      if (stat.isOnCourt) {
        widgets.add(_drawStarterMark(x: entryX, y: currentY));
      } else if (stat.points > 0 || stat.fouls > 0 || stat.isOnCourt) {
        widgets.add(_drawText("X", x: entryX, y: currentY, fontSize: 10));
      }

      for (int f = 0; f < stat.fouls; f++) {
        if (f >= 5) break;
        double foulX = startXFouls + (f * PdfCoords.foulBoxWidth);
        widgets.add(
          _drawText(
            "X",
            x: foulX,
            y: currentY,
            fontSize: 10,
            isBold: true,
            color: f == 4 ? PdfColors.red : PdfColors.black,
          ),
        );
      }
      currentY -= PdfCoords.rowHeight;
    }
    return widgets;
  }

  static pw.Widget _drawStarterMark({required double x, required double y}) {
    return pw.Positioned(
      left: x - 1,
      top: y + 1,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Container(
            width: 11,
            height: 11,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Text("x", style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static List<pw.Widget> _drawRunningScore(List<ScoreEvent> log) {
    List<pw.Widget> widgets = [];
    const double totalHeight =
        PdfCoords.runScoreEndY - PdfCoords.runScoreStartY;
    const double stepY = totalHeight / 39.0;

    for (var event in log) {
      final PdfColor inkColor = (event.period <= 2)
          ? PdfColors.blue900
          : PdfColors.red;
      int score = event.scoreAfter;
      if (score > 160) score = 160;

      int blockIndex = (score - 1) ~/ 40;
      int rowInBlock = (score - 1) % 40;

      double blockX =
          PdfCoords.runScoreCol1X +
          (blockIndex * PdfCoords.runScoreBlockSpacing);
      double finalX = (event.teamId == 'A')
          ? blockX
          : blockX + PdfCoords.runScoreTeamSpacing;
      double finalY = PdfCoords.runScoreStartY + (rowInBlock * stepY);
      double playerNumX = (event.teamId == 'A')
          ? finalX + PdfCoords.playerNumOffsetX
          : finalX - PdfCoords.playerNumOffsetX + 5;

      widgets.add(
        _drawText(
          event.playerNumber,
          x: playerNumX,
          y: finalY,
          fontSize: 7,
          color: inkColor,
        ),
      );

      if (event.points == 1) {
        widgets.add(_drawFilledDot(finalX, finalY, inkColor));
      } else {
        widgets.add(_drawDiagonalSlash(finalX, finalY, inkColor));
        if (event.points == 3) {
          widgets.add(_drawCircleAroundNumber(playerNumX, finalY, inkColor));
        }
      }
    }
    return widgets;
  }

  static pw.Widget _drawFilledDot(double x, double y, PdfColor color) {
    return pw.Positioned(
      left: x + 3,
      top: y + 4,
      child: pw.Container(
        width: 4,
        height: 4,
        decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      ),
    );
  }

  static pw.Widget _drawDiagonalSlash(double x, double y, PdfColor color) {
    return pw.Positioned(
      left: x,
      top: y - 1,
      child: pw.CustomPaint(
        size: const PdfPoint(10, 10),
        painter: (canvas, size) {
          canvas.setColor(color);
          canvas.setLineWidth(1.5);
          canvas.drawLine(0, 10, 10, 0);
          canvas.strokePath();
        },
      ),
    );
  }

  static pw.Widget _drawCircleAroundNumber(double x, double y, PdfColor color) {
    return pw.Positioned(
      left: x - 1,
      top: y - 1,
      child: pw.Container(
        width: 12,
        height: 12,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          shape: pw.BoxShape.circle,
        ),
      ),
    );
  }

  static pw.Widget _drawPeriodScore(
    MatchState state,
    int period,
    double xA,
    double xB,
    double y,
  ) {
    final scoreA =
        (state.periodScores[period] != null &&
            state.periodScores[period]!.isNotEmpty)
        ? state.periodScores[period]![0]
        : 0;
    final scoreB =
        (state.periodScores[period] != null &&
            state.periodScores[period]!.length > 1)
        ? state.periodScores[period]![1]
        : 0;
    return pw.Stack(
      children: [
        _drawText("$scoreA", x: xA, y: y, fontSize: 10, isBold: true),
        _drawText("$scoreB", x: xB, y: y, fontSize: 10, isBold: true),
      ],
    );
  }

  static pw.Widget _drawOvertimeScore(
    MatchState state,
    double xA,
    double xB,
    double y,
  ) {
    int totalA = _calculateOvertimeTotal(state, 0);
    int totalB = _calculateOvertimeTotal(state, 1);
    return pw.Stack(
      children: [
        _drawText("$totalA", x: xA, y: y, fontSize: 10, isBold: true),
        _drawText("$totalB", x: xB, y: y, fontSize: 10, isBold: true),
      ],
    );
  }

  static int _calculateOvertimeTotal(MatchState state, int teamIndex) {
    int total = 0;
    state.periodScores.forEach((period, scores) {
      if (period >= 5 && scores.length > teamIndex) total += scores[teamIndex];
    });
    return total;
  }

  static pw.Widget _drawText(
    String text, {
    required double x,
    required double y,
    double fontSize = 12,
    bool isBold = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}