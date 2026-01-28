import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/match_game_controller.dart';

/// ==============================================================
/// 📐 CONFIGURACIÓN DE COORDENADAS (LAYOUT)
/// ==============================================================
class PdfCoords {
  // --- 1. ENCABEZADO (Datos del Partido) ---
  static const double headerY = 90.0;
  
  static const double competitionX = 390.0;
  static const double dateX = 195.0;
  static const double timeX = 270.0;
  static const double placeX = 180.0;
  static const double placeY = 105.0;
  static const double gameNoX = 100.0;

  // --- 2. ENCABEZADOS DE EQUIPOS (SUPERIOR) ---
  static const double teamANameX = 115.0;
  static const double teamANameY = 123.0; 
  
  static const double teamBNameX = 115.0;
  static const double teamBNameY = 405.0;

  // --- 2.1. ENCABEZADOS DE EQUIPOS (Encabezado) ---
  static const double teamAName2X = 130.0; 
  static const double teamAName2Y = 55.0; 
  
  static const double teamBName2X = 390.0;
  static const double teamBName2Y = 55.0; 

  // --- 3. TABLA DE JUGADORES (EQUIPO A) ---
  static const double teamAListStartY = 310.0;
  static const double teamAColNumX = 22.5;
  static const double teamAColNameX = 50.0;
  static const double teamAColFoulsX = 235.0;

  // --- 4. TABLA DE JUGADORES (EQUIPO B) ---
  static const double teamBListStartY = 594.7;
  static const double teamBColNumX = 22.5;
  static const double teamBColNameX = 50.0;
  static const double teamBColFoulsX = 235.0;

  // --- 5. CONFIGURACIÓN GENERAL DE TABLAS ---
  static const double rowHeight = 13.0;
  static const double foulBoxWidth = 12.0;

  // --- 6. MARCADOR FINAL (Pie de página) ---
  static const double scoreBoxY = 772.0;
  static const double scoreAX = 450.0;
  static const double scoreBX = 535.0;
  static const double scoreFontSize = 20.0;

  // --- 7. PUNTUACIÓN POR PERIODOS (COORDENADAS INDEPENDIENTES) ---
  // Ajusta X e Y para mover cada periodo individualmente a donde quieras
  
  // Periodo 1
  static const double period1AX = 446.0; // Puntos Equipo A (P1)
  static const double period1BX = 532.0; // Puntos Equipo B (P1)
  static const double period1Y  = 692.0; // Altura P1

  // Periodo 2
  static const double period2AX = 446.0; 
  static const double period2BX = 532.0;
  static const double period2Y  = 707.0;

  // Periodo 3
  static const double period3AX = 446.0;
  static const double period3BX = 532.0;
  static const double period3Y  = 723.0;

  // Periodo 4
  static const double period4AX = 446.0;
  static const double period4BX = 532.0;
  static const double period4Y  = 740.0;

  // Tiempo Extra (Total acumulado)
  static const double overtimeAX = 446.0;
  static const double overtimeBX = 532.0;
  static const double overtimeY  = 755.0;
}

/// ==============================================================
/// 🖨️ GENERADOR DE PDF
/// ==============================================================
class PdfGenerator {
  
  static Future<void> generateAndPreview(
    MatchState state,
    String teamAName,
    String teamBName,
  ) async {
    final pdf = await _buildDocument(state, teamAName, teamBName);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> generateAndShare(
    MatchState state,
    String teamAName,
    String teamBName,
  ) async {
    final pdf = await _buildDocument(state, teamAName, teamBName);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Acta_${teamAName}_vs_$teamBName.pdf',
    );
  }

  // --- LÓGICA DE CONSTRUCCIÓN ---

  static Future<pw.Document> _buildDocument(
    MatchState state,
    String teamAName,
    String teamBName,
  ) async {
    final pdf = pw.Document();

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
                // FONDO
                pw.Positioned.fill(
                  child: pw.Image(image, fit: pw.BoxFit.fill),
                ),

                // --- DATOS DEL PARTIDO ---
                _drawText("Liga Local", x: PdfCoords.competitionX, y: PdfCoords.headerY, fontSize: 9),
                _drawText("001", x: PdfCoords.gameNoX, y: PdfCoords.placeY, fontSize: 9),
                _drawText(
                  "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  x: PdfCoords.dateX, y: PdfCoords.headerY, fontSize: 9
                ),
                _drawText("12:00", x: PdfCoords.timeX, y: PdfCoords.headerY, fontSize: 9),
                _drawText("Cancha Central", x: PdfCoords.placeX, y: PdfCoords.placeY, fontSize: 9),

                // --- NOMBRES DE EQUIPOS (ARRIBA) ---
                _drawText(teamAName.toUpperCase(), x: PdfCoords.teamANameX, y: PdfCoords.teamANameY, isBold: false),
                _drawText(teamBName.toUpperCase(), x: PdfCoords.teamBNameX, y: PdfCoords.teamBNameY, isBold: false),

                // --- NOMBRES DE EQUIPOS (DUPLICADOS/ABAJO) ---
                _drawText(teamAName.toUpperCase(), x: PdfCoords.teamAName2X, y: PdfCoords.teamAName2Y, isBold: true, fontSize: 10),
                _drawText(teamBName.toUpperCase(), x: PdfCoords.teamBName2X, y: PdfCoords.teamBName2Y, isBold: true, fontSize: 10),

                // --- LISTA DE JUGADORES EQUIPO A ---
                ..._buildRosterList(
                  players: state.teamAOnCourt + state.teamABench,
                  stats: state.playerStats,
                  startXNum: PdfCoords.teamAColNumX,
                  startXName: PdfCoords.teamAColNameX,
                  startXFouls: PdfCoords.teamAColFoulsX,
                  startY: PdfCoords.teamAListStartY,
                ),

                // --- LISTA DE JUGADORES EQUIPO B ---
                ..._buildRosterList(
                  players: state.teamBOnCourt + state.teamBBench,
                  stats: state.playerStats,
                  startXNum: PdfCoords.teamBColNumX,
                  startXName: PdfCoords.teamBColNameX,
                  startXFouls: PdfCoords.teamBColFoulsX,
                  startY: PdfCoords.teamBListStartY,
                ),

                // --- MARCADOR FINAL (TOTAL) ---
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

                // --- ✅ PUNTUACIÓN POR PERIODOS (INDEPENDIENTES) ---
                // Periodo 1
                _drawPeriodScore(state, 1, PdfCoords.period1AX, PdfCoords.period1BX, PdfCoords.period1Y),
                
                // Periodo 2
                _drawPeriodScore(state, 2, PdfCoords.period2AX, PdfCoords.period2BX, PdfCoords.period2Y),
                
                // Periodo 3
                _drawPeriodScore(state, 3, PdfCoords.period3AX, PdfCoords.period3BX, PdfCoords.period3Y),
                
                // Periodo 4
                _drawPeriodScore(state, 4, PdfCoords.period4AX, PdfCoords.period4BX, PdfCoords.period4Y),

                // Tiempo Extra (Solo si hubo)
                if (state.periodScores.containsKey(5))
                  _drawOvertimeScore(state, PdfCoords.overtimeAX, PdfCoords.overtimeBX, PdfCoords.overtimeY),
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

  // --- HELPERS DE DIBUJO ---

  /// ✅ NUEVO: Dibuja el score de un periodo específico en sus propias coordenadas
  static pw.Widget _drawPeriodScore(MatchState state, int period, double xA, double xB, double y) {
    // Obtenemos los puntos del periodo (o 0 si no existe)
    final scoreA = (state.periodScores[period] != null && state.periodScores[period]!.isNotEmpty) 
        ? state.periodScores[period]![0] 
        : 0;
    
    final scoreB = (state.periodScores[period] != null && state.periodScores[period]!.length > 1) 
        ? state.periodScores[period]![1] 
        : 0;

    // Retornamos un Stack pequeño con los dos números
    return pw.Stack(
      children: [
        _drawText("$scoreA", x: xA, y: y, fontSize: 10, isBold: true),
        _drawText("$scoreB", x: xB, y: y, fontSize: 10, isBold: true),
      ]
    );
  }

  /// ✅ NUEVO: Dibuja el score acumulado de todos los tiempos extra
  static pw.Widget _drawOvertimeScore(MatchState state, double xA, double xB, double y) {
    int totalA = _calculateOvertimeTotal(state, 0);
    int totalB = _calculateOvertimeTotal(state, 1);

    return pw.Stack(
      children: [
        _drawText("$totalA", x: xA, y: y, fontSize: 10, isBold: true),
        _drawText("$totalB", x: xB, y: y, fontSize: 10, isBold: true),
      ]
    );
  }

  static int _calculateOvertimeTotal(MatchState state, int teamIndex) {
    int total = 0;
    state.periodScores.forEach((period, scores) {
      if (period >= 5 && scores.length > teamIndex) {
        total += scores[teamIndex];
      }
    });
    return total;
  }

  static List<pw.Widget> _buildRosterList({
    required List<String> players,
    required Map<String, PlayerStats> stats,
    required double startXNum,
    required double startXName,
    required double startXFouls,
    required double startY,
  }) {
    List<pw.Widget> widgets = [];
    double currentY = startY;

    int limit = players.length > 12 ? 12 : players.length;

    for (var i = 0; i < limit; i++) {
      final playerName = players[i];
      final stat = stats[playerName] ?? const PlayerStats();
      final dorsal = "${i + 4}"; 

      widgets.add(_drawText(dorsal, x: startXNum, y: currentY, fontSize: 10));

      String displayName = playerName.length > 18 
          ? "${playerName.substring(0, 16)}..." 
          : playerName;
      widgets.add(_drawText(displayName, x: startXName, y: currentY, fontSize: 10));

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
            color: f == 4 ? PdfColors.red : PdfColors.black
          )
        );
      }
      currentY -= PdfCoords.rowHeight; 
    }
    return widgets;
  }

  /// Helper genérico con el arreglo del fontSize
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
          fontSize: fontSize, // ✅ AHORA SÍ ESTÁ DENTRO DE TEXTSTYLE
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}