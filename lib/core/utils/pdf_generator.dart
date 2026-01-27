import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/match_game_controller.dart';

class PdfGenerator {
  // ==================================================================
  // 🔧 ZONA DE CALIBRACIÓN (Ajusta estos números para mover el texto)
  // ==================================================================

  // Encabezados
  static const double headerTeamAX = 150.0;
  static const double headerTeamAY = 750.0;
  static const double headerTeamBX = 400.0;
  static const double headerTeamBY = 750.0;

  // Marcador Grande
  static const double scoreAX = 200.0;
  static const double scoreAY = 700.0;
  static const double scoreBX = 450.0;
  static const double scoreBY = 700.0;

  // Listas de Jugadores (Inicio de la lista)
  static const double listTeamAX = 50.0;
  static const double listTeamAY = 600.0;
  static const double listTeamBX = 300.0; // Más a la derecha
  static const double listTeamBY = 600.0;

  // Espacio entre renglones de jugadores
  static const double rowHeight = 15.0;

  // ==================================================================

  /// 1. Ver en Pantalla (Imprimir)
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

  /// 2. Compartir Directamente (WhatsApp, etc.)
  static Future<void> generateAndShare(
    MatchState state,
    String teamAName,
    String teamBName,
  ) async {
    final pdf = await _buildDocument(state, teamAName, teamBName);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'acta_${teamAName}_vs_$teamBName.pdf',
    );
  }

  /// 🛠️ Método privado que construye el PDF (Reutilizable)
  static Future<pw.Document> _buildDocument(
    MatchState state,
    String teamAName,
    String teamBName,
  ) async {
    final pdf = pw.Document();

    // Cargar imagen .png
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
              // Fondo
              pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),

              // --- USAMOS LAS VARIABLES DE ARRIBA ---

              // Encabezados
              _drawText(
                teamAName,
                x: headerTeamAX,
                y: headerTeamAY,
                fontSize: 10,
              ),
              _drawText(
                teamBName,
                x: headerTeamBX,
                y: headerTeamBY,
                fontSize: 10,
              ),

              // Marcadores
              _drawText(
                "${state.scoreA}",
                x: scoreAX,
                y: scoreAY,
                fontSize: 24,
                isBold: true,
              ),
              _drawText(
                "${state.scoreB}",
                x: scoreBX,
                y: scoreBY,
                fontSize: 24,
                isBold: true,
              ),

              // Lista Equipo A
              ..._generatePlayerList(
                state.teamA_OnCourt + state.teamA_Bench,
                state.playerStats,
                startX: listTeamAX,
                startY: listTeamAY,
              ),

              // Lista Equipo B
              ..._generatePlayerList(
                state.teamB_OnCourt + state.teamB_Bench,
                state.playerStats,
                startX: listTeamBX,
                startY: listTeamBY,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _drawText(
    String text, {
    required double x,
    required double y,
    double fontSize = 12,
    bool isBold = false,
  }) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static List<pw.Widget> _generatePlayerList(
    List<String> players,
    Map<String, PlayerStats> stats, {
    required double startX,
    required double startY,
  }) {
    List<pw.Widget> widgets = [];
    double currentY = startY;

    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      final stat = stats[player] ?? const PlayerStats();

      // Nombre
      widgets.add(_drawText(player, x: startX, y: currentY, fontSize: 9));
      // Dorsal (Simulado)
      widgets.add(
        _drawText("${i + 4}", x: startX + 100, y: currentY, fontSize: 9),
      );
      // Faltas
      String foulsStr = "";
      for (int f = 0; f < stat.fouls; f++) foulsStr += "X ";
      widgets.add(
        _drawText(foulsStr, x: startX + 130, y: currentY, fontSize: 9),
      );

      // Mover hacia abajo usando la constante
      currentY -= rowHeight;
    }
    return widgets;
  }
}
