import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/match_game_controller.dart'; // Importa tu MatchState

class PdfGenerator {
  /// Función principal que genera el PDF
  static Future<void> generateAndPreview(
    MatchState state,
    String teamAName,
    String teamBName,
  ) async {
    final pdf = pw.Document();

    // 1. Cargar la imagen de fondo (La hoja de anotación)
    // Asegúrate de que el nombre coincida con pubspec.yaml
    final imageBytes = await rootBundle.load(
      'assets/images/hoja_anotacion.png',
    );
    final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

    // 2. Crear la página PDF (Formato A4 o Letter según tu imagen)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        // margins: pw.EdgeInsets.zero es CRÍTICO para que la imagen ocupe todo
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // A. La Imagen de Fondo (Full Screen)
              pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),

              // B. Los Datos Superpuestos (Aquí es donde ajustarás las X,Y)

              // --- EJEMPLO: ENCABEZADO ---
              _drawText(teamAName, x: 150, y: 750, fontSize: 10), // Equipo A
              _drawText(teamBName, x: 400, y: 750, fontSize: 10), // Equipo B
              _drawText("Cancha 1", x: 60, y: 780, fontSize: 8), // Lugar
              // --- EJEMPLO: MARCADOR FINAL ---
              _drawText(
                "${state.scoreA}",
                x: 200,
                y: 700,
                fontSize: 20,
                isBold: true,
              ),
              _drawText(
                "${state.scoreB}",
                x: 450,
                y: 700,
                fontSize: 20,
                isBold: true,
              ),

              // --- EJEMPLO: LISTA DE JUGADORES (Iterativa) ---
              // Equipo A
              ..._generatePlayerList(
                state.teamA_OnCourt + state.teamA_Bench,
                state.playerStats,
                startX: 50,
                startY: 600,
              ),

              // Equipo B (Más a la derecha)
              ..._generatePlayerList(
                state.teamB_OnCourt + state.teamB_Bench,
                state.playerStats,
                startX: 300,
                startY: 600,
              ),
            ],
          );
        },
      ),
    );

    // 3. Mostrar Vista Previa (Share/Print)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Helper para dibujar texto en coordenada absoluta (X, Y son puntos PDF)
  /// Nota: En PDF, el eje Y=0 suele estar ABAJO. Pero 'pdf' package lo maneja desde arriba
  /// si usas Positioned dentro de Stack a veces varía. Ajusta a prueba y error.
  static pw.Widget _drawText(
    String text, {
    required double x,
    required double y,
    double fontSize = 12,
    bool isBold = false,
  }) {
    return pw.Positioned(
      left: x,
      top: y, // Ajusta 'top' o 'bottom' según como salga tu imagen
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black, // Color del texto (simula pluma negra)
        ),
      ),
    );
  }

  /// Genera la lista visual de jugadores hacia abajo
  static List<pw.Widget> _generatePlayerList(
    List<String> players,
    Map<String, PlayerStats> stats, {
    required double startX,
    required double startY,
  }) {
    List<pw.Widget> widgets = [];
    double currentY = startY;
    double rowHeight = 15.0; // Espacio entre renglones de la hoja

    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      final stat = stats[player] ?? const PlayerStats();

      // Nombre
      widgets.add(_drawText(player, x: startX, y: currentY, fontSize: 9));

      // Número (Dorsal dummy)
      widgets.add(
        _drawText("${i + 4}", x: startX + 100, y: currentY, fontSize: 9),
      );

      // Faltas (P, P1, P2...)
      String foulsStr = "";
      for (int f = 0; f < stat.fouls; f++) foulsStr += "X "; // Marcamos con X
      widgets.add(
        _drawText(foulsStr, x: startX + 130, y: currentY, fontSize: 9),
      );

      currentY += rowHeight; // Bajamos al siguiente renglón
    }
    return widgets;
  }
}
