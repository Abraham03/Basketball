import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/match_game_controller.dart';
import 'dart:typed_data';

class PdfCoords {
  // --- 1. HEADER ---
  static const double headerY = 90.0;
  static const double competitionX = 390.0;
  static const double dateX = 188.0;
  static const double timeX = 270.0;
  static const double placeX = 180.0;
  static const double placeY = 105.0;
  static const double gameNoX = 100.0;

  // --- REFEREES ---
  static const double referee1X = 365.0;
  static const double referee1Y = 105.0;
  static const double referee2X = 495.0;
  static const double referee2Y = 105.0;

  // --- FOOTER ---
  static const double footerY = 795.0;
  static const double footerReferee1X = 72.0;
  static const double footerReferee2X = 210.0;
  static const double footerScorekeeperY = 695.0;
  static const double footerScorekeeperX = 140.0;
  static const double winningTeamX = 400.0;
  static const double winningTeamY = 810.0;

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
  static const double teamAListStartY = 367.0;
  static const double teamAColNumX = 195.5;
  static const double teamAColNameX = 50.0;
  static const double teamAColCaptainX = 20.0; // "C" 
  static const double teamAColFoulsX = 232.5;
  static const double teamAColEntryX = 215.5;

  static const double teamBListStartY = 650.0;
  static const double teamBColNumX = 195.5;
  static const double teamBColNameX = 50.0;
  static const double teamBColCaptainX = 20.0;
  static const double teamBColFoulsX = 232.5;
  static const double teamBColEntryX = 215.5;

  static const double rowHeight = 13.5;
  static const double foulBoxWidth = 12.0;

  // --- COACHES  ---
  // Ubicados debajo de la lista de jugadores
  static const double coachAX = 50.0;
  static const double coachAY = 380.0; // Debajo de teamAListStartY
  static const double coachAFoulsX = 232.5;

  static const double coachBX = 50.0;
  static const double coachBY = 664.0; // Debajo de teamBListStartY
  static const double coachBFoulsX = 232.5;

  // --- 4. TIMEOUTS  ---
  // Ajustadas para estar debajo del nombre y antes de la lista
  // Equipo A
  static const double teamATimeoutsX = 28.0;
  static const double teamATimeoutsY1 = 153.0; // 1a Mitad (Fila superior)
  static const double teamATimeoutsY2 = 168.0; // 2a Mitad (Fila inferior)

  // Equipo B
  static const double teamBTimeoutsX = 28.0;
  static const double teamBTimeoutsY1 = 433.0;
  static const double teamBTimeoutsY2 = 450.0;

  static const double timeoutBoxStep =12.0; // Espacio entre cuadros de tiempo fuera

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

  // --- 10. TEAM FOULS ---
  static const double teamAFoulsX = 156.0;
  static const double teamAFoulsPeriod1Y = 150.0;
  static const double teamAFoulsPeriod2Y = 165.0;
  static const double teamAFoulsPeriod2Offset = 60.0;
  static const double teamAFoulsPeriod3Y = 168.0;
  static const double teamAFoulsPeriod4Y = 168.0;

  static const double teamBFoulsX = 156.0;
  static const double teamBFoulsPeriod1Y = 434.0;
  static const double teamBFoulsPeriod3Y = 450.0;

  static const double teamFoulBoxStep = 12.8;

  static const double protestSignatureX = 175.0;
  static const double protestSignatureY = 17.0;
}

class PdfGenerator {
  static String _createFileName(String teamA, String teamB) {
    final sanitizedA = teamA.replaceAll(" ", "_");
    final sanitizedB = teamB.replaceAll(" ", "_");
    return "Acta_${sanitizedA}_vs_$sanitizedB.pdf";
  }

  static Future<Uint8List> generateBytes(
    MatchState state,
    String teamAName,
    String teamBName, {
    String tournamentName = "",
    String venueName = "",
    String mainReferee = "",
    String auxReferee = "",
    String scorekeeper = "",
    required String coachA,
    required String coachB,
    int? captainAId,
    int? captainBId,
    Uint8List? protestSignature,
    DateTime? matchDate,
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
      coachA,
      coachB,
      captainAId,
      captainBId,
      protestSignature,
      matchDate,
    );
    return pdf.save();
  }

  static Future<void> generateAndPreview(
    MatchState state,
    String teamAName,
    String teamBName, {
    String tournamentName = "",
    String venueName = "",
    String mainReferee = "",
    String auxReferee = "",
    String scorekeeper = "",
    required String coachA,
    required String coachB,
    int? captainAId,
    int? captainBId,
    Uint8List? protestSignature,
    DateTime? matchDate,
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
      coachA,
      coachB,
      captainAId,
      captainBId,
      protestSignature,
      matchDate,
    );
    final fileName = _createFileName(teamAName, teamBName);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: fileName,
    );
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
    required String coachA,
    required String coachB,
    int? captainAId,
    int? captainBId,
    Uint8List? protestSignature,
    DateTime? matchDate,
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
      coachA,
      coachB,
      captainAId,
      captainBId,
      protestSignature,
      matchDate,
    );
    final fileName = _createFileName(teamAName, teamBName);
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
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
    String coachA,
    String coachB,
    int? captainAId,
    int? captainBId,
    Uint8List? protestSignature,
    DateTime? matchDate,
  ) async {
    final pdf = pw.Document();

    String winningTeam = "---";
    if (state.scoreA > state.scoreB) {
      winningTeam = teamAName.toUpperCase();
    } else if (state.scoreB > state.scoreA) {
      winningTeam = teamBName.toUpperCase();
    } else {
      winningTeam = "EMPATE";
    }

    // FORMATO DE FECHA Y HORA
    final dateStr = matchDate != null
        ? "${matchDate.day.toString().padLeft(2, '0')}/${matchDate.month.toString().padLeft(2, '0')}/${matchDate.year}"
        : "";
    final timeStr = matchDate != null
        ? "${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}"
        : "";

    try {
      final imageBytes = await rootBundle.load(
        'assets/images/hoja_anotacion.png',
      );
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),

                _drawText(
                  tournamentName,
                  x: PdfCoords.competitionX,
                  y: PdfCoords.headerY,
                  fontSize: 9,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  "001",
                  x: PdfCoords.gameNoX,
                  y: PdfCoords.placeY,
                  fontSize: 9,
                ),
                _drawText(
                  dateStr,
                  x: PdfCoords.dateX,
                  y: PdfCoords.headerY,
                  fontSize: 9,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  timeStr,
                  x: PdfCoords.timeX,
                  y: PdfCoords.headerY,
                  fontSize: 9,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  venueName,
                  x: PdfCoords.placeX,
                  y: PdfCoords.placeY,
                  fontSize: 9,
                  color: PdfColors.blue900,
                ),

                if (protestSignature != null)
                  pw.Positioned(
                    left: PdfCoords.protestSignatureX,
                    bottom: PdfCoords.protestSignatureY,
                    child: pw.Column(
                      children: [
                        pw.Image(
                          pw.MemoryImage(protestSignature),
                          width: 55,
                          height: 30,
                        ),
                      ],
                    ),
                  ),

                if (mainReferee.isNotEmpty)
                  _drawText(
                    mainReferee,
                    x: PdfCoords.referee1X,
                    y: PdfCoords.referee1Y,
                    fontSize: 8,
                    color: PdfColors.blue900,
                  ),
                if (auxReferee.isNotEmpty)
                  _drawText(
                    auxReferee,
                    x: PdfCoords.referee2X,
                    y: PdfCoords.referee2Y,
                    fontSize: 8,
                    color: PdfColors.blue900,
                  ),

                if (mainReferee.isNotEmpty)
                  _drawText(
                    mainReferee,
                    x: PdfCoords.footerReferee1X,
                    y: PdfCoords.footerY,
                    fontSize: 9,
                    color: PdfColors.blue900,
                  ),
                if (auxReferee.isNotEmpty)
                  _drawText(
                    auxReferee,
                    x: PdfCoords.footerReferee2X,
                    y: PdfCoords.footerY,
                    fontSize: 9,
                    color: PdfColors.blue900,
                  ),
                if (scorekeeper.isNotEmpty)
                  _drawText(
                    scorekeeper,
                    x: PdfCoords.footerScorekeeperX,
                    y: PdfCoords.footerScorekeeperY,
                    fontSize: 9,
                    isBold: true,
                    color: PdfColors.blue900,
                  ),

                _drawText(
                  winningTeam,
                  x: PdfCoords.winningTeamX,
                  y: PdfCoords.winningTeamY,
                  fontSize: 10,
                  isBold: true,
                  color: PdfColors.blue900,
                ),

                _drawText(
                  teamAName.toUpperCase(),
                  x: PdfCoords.teamANameX,
                  y: PdfCoords.teamANameY,
                  isBold: true,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  teamBName.toUpperCase(),
                  x: PdfCoords.teamBNameX,
                  y: PdfCoords.teamBNameY,
                  isBold: true,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  teamAName.toUpperCase(),
                  x: PdfCoords.teamAName2X,
                  y: PdfCoords.teamAName2Y,
                  isBold: true,
                  fontSize: 10,
                  color: PdfColors.blue900,
                ),
                _drawText(
                  teamBName.toUpperCase(),
                  x: PdfCoords.teamBName2X,
                  y: PdfCoords.teamBName2Y,
                  isBold: true,
                  fontSize: 10,
                  color: PdfColors.blue900,
                ),
              
                // --- COACH A ---
                if (coachA.isNotEmpty)
                  _drawText(coachA, x: PdfCoords.coachAX, y: PdfCoords.coachAY, fontSize: 10, isBold: true, color: PdfColors.blue900)
                else
                  _drawHorizontalLine(PdfCoords.coachAX, PdfCoords.coachAY, 150),
                
                // --- AQUI LLAMAMOS A LA NUEVA FUNCION PARA FALTAS DE COACH A ---
                ..._drawCoachFoulsMarks(state, 'A', PdfCoords.coachAFoulsX, PdfCoords.coachAY),


                // --- COACH B ---
                if (coachB.isNotEmpty)
                  _drawText(coachB, x: PdfCoords.coachBX, y: PdfCoords.coachBY, fontSize: 10, isBold: true, color: PdfColors.blue900)
                else
                  _drawHorizontalLine(PdfCoords.coachBX, PdfCoords.coachBY, 150),

                // --- AQUI LLAMAMOS A LA NUEVA FUNCION PARA FALTAS DE COACH B ---
                ..._drawCoachFoulsMarks(state, 'B', PdfCoords.coachBFoulsX, PdfCoords.coachBY),

                ..._drawTeamFoulsSection(state),

                ..._drawTimeouts(state),

                ..._buildRosterList(
                  players: _getSortedRoster(
                    state.teamAOnCourt,
                    state.teamABench,
                    state.playerStats,
                  ),
                  stats: state.playerStats,
                  startXNum: PdfCoords.teamAColNumX,
                  startXName: PdfCoords.teamAColNameX,
                  startXCaptain: PdfCoords.teamAColCaptainX,
                  startXFouls: PdfCoords.teamAColFoulsX,
                  startY: PdfCoords.teamAListStartY,
                  entryX: PdfCoords.teamAColEntryX,
                  captainId: captainAId,
                ),
                ..._buildRosterList(
                  players: _getSortedRoster(
                    state.teamBOnCourt,
                    state.teamBBench,
                    state.playerStats,
                  ),
                  stats: state.playerStats,
                  startXNum: PdfCoords.teamBColNumX,
                  startXName: PdfCoords.teamBColNameX,
                  startXCaptain: PdfCoords.teamBColCaptainX, // Nueva coordenada
                  startXFouls: PdfCoords.teamBColFoulsX,
                  startY: PdfCoords.teamBListStartY,
                  entryX: PdfCoords.teamBColEntryX,
                  captainId: captainBId,
                ),

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

                _drawPeriodScore(
                  state,
                  1,
                  PdfCoords.period1AX,
                  PdfCoords.period1BX,
                  PdfCoords.period1Y,
                ),
                _drawPeriodScore(
                  state,
                  2,
                  PdfCoords.period2AX,
                  PdfCoords.period2BX,
                  PdfCoords.period2Y,
                ),
                _drawPeriodScore(
                  state,
                  3,
                  PdfCoords.period3AX,
                  PdfCoords.period3BX,
                  PdfCoords.period3Y,
                ),
                _drawPeriodScore(
                  state,
                  4,
                  PdfCoords.period4AX,
                  PdfCoords.period4BX,
                  PdfCoords.period4Y,
                ),
                if (state.periodScores.containsKey(5))
                  _drawOvertimeScore(
                    state,
                    PdfCoords.overtimeAX,
                    PdfCoords.overtimeBX,
                    PdfCoords.overtimeY,
                  ),

                ..._drawRunningScore(state.scoreLog, state.periodScores),
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

  // Función para dibujar los tiempos fuera ---
  static List<pw.Widget> _drawTimeouts(MatchState state) {
    List<pw.Widget> widgets = [];

    // EQUIPO A
    widgets.addAll(
      _drawTimeoutRow(
        timeouts: state.teamATimeouts1,
        maxBoxes: 2,
        startX: PdfCoords.teamATimeoutsX,
        y: PdfCoords.teamATimeoutsY1,
      ),
    );
    widgets.addAll(
      _drawTimeoutRow(
        timeouts: state.teamATimeouts2,
        maxBoxes: 3,
        startX: PdfCoords.teamATimeoutsX,
        y: PdfCoords.teamATimeoutsY2,
      ),
    );

    // EQUIPO B
    widgets.addAll(
      _drawTimeoutRow(
        timeouts: state.teamBTimeouts1,
        maxBoxes: 2,
        startX: PdfCoords.teamBTimeoutsX,
        y: PdfCoords.teamBTimeoutsY1,
      ),
    );
    widgets.addAll(
      _drawTimeoutRow(
        timeouts: state.teamBTimeouts2,
        maxBoxes: 3,
        startX: PdfCoords.teamBTimeoutsX,
        y: PdfCoords.teamBTimeoutsY2,
      ),
    );

    return widgets;
  }

  // Helper para fila de tiempos fuera
  static List<pw.Widget> _drawTimeoutRow({
    required List<String> timeouts,
    required int maxBoxes,
    required double startX,
    required double y,
  }) {
    List<pw.Widget> rowWidgets = [];
    for (int i = 0; i < maxBoxes; i++) {
      double x = startX + (i * PdfCoords.timeoutBoxStep);
      String text = (i < timeouts.length) ? timeouts[i] : "";
      if (text.isNotEmpty) {
        rowWidgets.add(_drawText(text, x: x, y: y, fontSize: 9, isBold: true));
      }else{
        rowWidgets.add(_drawBlueHorizontalMark(x, y));
      }
    }
    return rowWidgets;
  }

  static List<pw.Widget> _drawCoachFoulsMarks(MatchState state, String teamId, double startX, double y) {
      List<pw.Widget> widgets = [];
      
      // Filtramos eventos que sean faltas de coach (C) o banca (B) para este equipo
      final coachEvents = state.scoreLog.where((e) {
         return e.teamId == teamId && (e.type == 'C' || e.type == 'B');
      }).toList();

      // Dibujamos hasta 3 casillas (estándar)
      for (int i = 0; i < 5; i++) {
         double x = startX + (i * PdfCoords.foulBoxWidth);
         
         if (i < coachEvents.length) {
            // Dibuja la letra C o B
            String code = coachEvents[i].type;
            widgets.add(_drawText(code, x: x, y: y, fontSize: 8, isBold: true, color: PdfColors.red));
         } else {
            // Dibuja raya horizontal
            widgets.add(_drawBlueHorizontalMark(x, y));
         }
      }
      return widgets;
  }

  // --- Dibuja líneas azules en casillas vacías y filas vacías ---
  static List<pw.Widget> _buildRosterList({
    required List<String> players,
    required Map<String, PlayerStats> stats,
    required double startXNum,
    required double startXName,
    required double startXCaptain,
    required double startXFouls,
    required double startY,
    required double entryX,
    int? captainId,
  }) {
    List<pw.Widget> widgets = [];
    int limit = 12; // Siempre 12 filas en la hoja

    // 'startY' es la coordenada inferior (312).
    // Para empezar desde arriba, restamos la altura de las 11 filas previas.
    // Así 'currentY' empieza en la primera línea superior visualmente.
    double currentY = startY - (11 * PdfCoords.rowHeight);

    for (var i = 0; i < limit; i++) {
      if (i < players.length) {
        // --- JUGADOR EXISTENTE ---
        final playerName = players[i];
        final stat = stats[playerName] ?? const PlayerStats();
        final dorsal = stat.playerNumber.isNotEmpty ? stat.playerNumber : "";

        widgets.add(_drawText(dorsal, x: startXNum, y: currentY, fontSize: 10));

        // DIBUJAR CAPITÁN (C) A LA IZQUIERDA
        if (captainId != null && stat.dbId == captainId) {
           widgets.add(_drawText("C", x: startXCaptain, y: currentY, fontSize: 9, isBold: true));
        }

        String displayName = playerName;
        if (captainId != null && stat.dbId == captainId) {
          displayName += " C";
        }
        displayName = playerName.length > 18
            ? "${playerName.substring(0, 16)}..."
            : playerName;
        widgets.add(
          _drawText(displayName, x: startXName, y: currentY, fontSize: 10),
        );

        if (stat.isStarter) {
          widgets.add(_drawStarterMark(x: entryX, y: currentY));
        } else if (stat.points > 0 || stat.fouls > 0 || stat.isOnCourt) {
          widgets.add(_drawText("X", x: entryX, y: currentY, fontSize: 10));
        }

        // Dibujar faltas (código) o línea azul si está vacía
        for (int f = 0; f < 5; f++) {
          double foulX = startXFouls + (f * PdfCoords.foulBoxWidth);
          if (f < stat.foulDetails.length) {
            String foulCode = stat.foulDetails[f];
            PdfColor color = (f == 4 || foulCode == 'D')
                ? PdfColors.red
                : PdfColors.black;
            widgets.add(
              _drawText(
                foulCode,
                x: foulX,
                y: currentY,
                fontSize: 8,
                isBold: true,
                color: color,
              ),
            );
          } else {
            // SIN FALTA: Línea horizontal azul
            widgets.add(_drawBlueHorizontalMark(foulX, currentY));
          }
        }
      } else {
        // --- FILA VACÍA (SIN JUGADOR) ---
        // Tachamos el nombre
        widgets.add(
          _drawHorizontalLine(startXName, currentY, 130),
        ); // Ajusta ancho según columna
        // Tachamos el número
        widgets.add(_drawHorizontalLine(startXNum, currentY, 20));
        // Tachamos las 5 casillas de faltas
        for (int f = 0; f < 5; f++) {
          double foulX = startXFouls + (f * PdfCoords.foulBoxWidth);
          widgets.add(_drawHorizontalLine(foulX, currentY, 10));
        }
      }
      currentY += PdfCoords.rowHeight;
    }
    return widgets;
  }

  // Línea azul en casillas de faltas de equipo no usadas ---
  static List<pw.Widget> _drawFoulMarks({
    required int count,
    required double startX,
    required double startY,
  }) {
    List<pw.Widget> marks = [];
    int limit = 4; // Siempre 4 casillas
    for (int i = 0; i < limit; i++) {
      double currentX = startX + (i * PdfCoords.teamFoulBoxStep);
      if (i < count) {
        marks.add(
          _drawText(
            "X",
            x: currentX,
            y: startY,
            fontSize: 10,
            isBold: true,
            color: PdfColors.blue900,
          ),
        );
      } else {
        // SIN FALTA: Línea horizontal azul
        marks.add(_drawBlueHorizontalMark(currentX, startY));
      }
    }
    return marks;
  }

  // --- HELPER: Línea horizontal azul para casillas pequeñas (Faltas) ---
  static pw.Widget _drawBlueHorizontalMark(double x, double y) {
    return pw.Positioned(
      left: x, // Pequeño margen izquierdo
      top: y + 4, // Centrado verticalmente (aprox mitad de fuente 10)
      child: pw.Container(
        width: 10, // Ancho de la casilla
        height: 1.0,
        color: PdfColors.blue900,
      ),
    );
  }

  // --- HELPER: Línea horizontal azul larga para tachar filas ---
  static pw.Widget _drawHorizontalLine(double x, double y, double width) {
    return pw.Positioned(
      left: x - 3,
      top: y + 4,
      child: pw.Container(width: width, height: 1.0, color: PdfColors.blue900),
    );
  }

  static List<String> _getSortedRoster(
    List<String> court,
    List<String> bench,
    Map<String, PlayerStats> stats,
  ) {
    List<String> allPlayers = [...court, ...bench];
    allPlayers.sort((a, b) {
      String numA = stats[a]?.playerNumber ?? "0";
      String numB = stats[b]?.playerNumber ?? "0";
      int intA = int.tryParse(numA) ?? 999;
      int intB = int.tryParse(numB) ?? 999;
      int comparison = intA.compareTo(intB);
      if (comparison != 0) return comparison;
      return a.compareTo(b);
    });
    return allPlayers;
  }

  static List<pw.Widget> _drawTeamFoulsSection(MatchState state) {
    List<pw.Widget> widgets = [];
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'A', 1),
        startX: PdfCoords.teamAFoulsX,
        startY: PdfCoords.teamAFoulsPeriod1Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'A', 2),
        startX: PdfCoords.teamAFoulsX + 80.0,
        startY: PdfCoords.teamAFoulsPeriod1Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'A', 3),
        startX: PdfCoords.teamAFoulsX,
        startY: PdfCoords.teamAFoulsPeriod3Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'A', 4),
        startX: PdfCoords.teamAFoulsX + 80.0,
        startY: PdfCoords.teamAFoulsPeriod3Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'B', 1),
        startX: PdfCoords.teamBFoulsX,
        startY: PdfCoords.teamBFoulsPeriod1Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'B', 2),
        startX: PdfCoords.teamBFoulsX + 80.0,
        startY: PdfCoords.teamBFoulsPeriod1Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'B', 3),
        startX: PdfCoords.teamBFoulsX,
        startY: PdfCoords.teamBFoulsPeriod3Y,
      ),
    );
    widgets.addAll(
      _drawFoulMarks(
        count: _countTeamFouls(state, 'B', 4),
        startX: PdfCoords.teamBFoulsX + 80.0,
        startY: PdfCoords.teamBFoulsPeriod3Y,
      ),
    );
    return widgets;
  }

  static int _countTeamFouls(MatchState state, String teamId, int period) {
    return state.scoreLog.where((event) {
      bool isMatch = event.teamId == teamId && event.period == period;
      bool isFoul = event.points == 0;
      return isMatch && isFoul;
    }).length;
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

  static List<pw.Widget> _drawRunningScore(
    List<ScoreEvent> log,
    Map<int, List<int>> periodScores,
  ) {
    List<pw.Widget> widgets = [];
    const double totalHeight =
        PdfCoords.runScoreEndY - PdfCoords.runScoreStartY;
    const double stepY = totalHeight / 39.0;

    for (var event in log) {
      if (event.points == 0) continue;
      final PdfColor inkColor = (event.period % 2 != 0)
          ? PdfColors.red
          : PdfColors.blue900;
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

    int runningA = 0;
    int runningB = 0;
    final sortedPeriods = periodScores.keys.toList()..sort();
    for (int p in sortedPeriods) {
      final scores = periodScores[p];
      if (scores == null) continue;
      int pointsAInPeriod = scores.isNotEmpty ? scores[0] : 0;
      int pointsBInPeriod = scores.length > 1 ? scores[1] : 0;
      runningA += pointsAInPeriod;
      runningB += pointsBInPeriod;
      final PdfColor periodColor = (p % 2 != 0)
          ? PdfColors.red
          : PdfColors.blue900;
      if (runningA > 0 && runningA <= 160) {
        widgets.add(_drawPeriodEndLine(runningA, 'A', stepY, periodColor));
      }
      if (runningB > 0 && runningB <= 160) {
        widgets.add(_drawPeriodEndLine(runningB, 'B', stepY, periodColor));
      }
    }
    return widgets;
  }

  static pw.Widget _drawPeriodEndLine(
    int score,
    String teamId,
    double stepY,
    PdfColor color,
  ) {
    int blockIndex = (score - 1) ~/ 40;
    int rowInBlock = (score - 1) % 40;
    double blockX =
        PdfCoords.runScoreCol1X + (blockIndex * PdfCoords.runScoreBlockSpacing);
    double finalX = (teamId == 'A')
        ? blockX
        : blockX + PdfCoords.runScoreTeamSpacing;
    double y = PdfCoords.runScoreStartY + (rowInBlock * stepY) + 10;
    double lineX = (teamId == 'A') ? finalX - 25 : finalX - 5;
    return pw.Positioned(
      left: lineX,
      top: y,
      child: pw.Container(width: 35, height: 3.0, color: color),
    );
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
