import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/match_game_controller.dart';

/// ==============================================================
///   CONFIGURACIÓN DE COORDENADAS (LAYOUT)
/// ==============================================================
/// Modifica estos valores para ajustar la posición de los textos
/// según la imagen de fondo que estés utilizando.
/// Coordenadas: (0,0) es la esquina inferior izquierda por defecto en PDF,
/// pero 'pdf' package con Stack suele usar Top-Left visualmente.
/// Ajusta a prueba y error si se ve invertido.
class PdfCoords {
  // --- 1. ENCABEZADO (Datos del Partido) ---
  static const double headerY = 90.0; // Altura general del encabezado
  
  static const double competitionX = 350.0; // Liga
  static const double dateX = 195.0;  // Fecha
  static const double timeX = 270.0;  // Hora
  static const double placeX = 180.0; // Derecha
  static const double placeY = 105.0; // Arriba
  static const double gameNoX = 100.0;  // Numero de partido

  // --- 2. ENCABEZADOS DE EQUIPOS ---
  // Nombre del Equipo A (Izquierda/Arriba)
  static const double teamANameX = 100.0;
  static const double teamANameY = 123.0; 
  
  // Nombre del Equipo B (Derecha/Abajo según formato, aquí asumimos simétrico)
  static const double teamBNameX = 100.0;
  static const double teamBNameY = 405.0;

  // --- 3. TABLA DE JUGADORES (EQUIPO A) ---
  static const double teamAListStartY = 310.0; // Altura del primer jugador
  static const double teamAColNumX = 22.5;     // Columna "#"
  static const double teamAColNameX = 50.0;    // Columna "Nombre"
  static const double teamAColFoulsX = 235.0;  // Inicio casillas de faltas (1 a 5)

  // --- 4. TABLA DE JUGADORES (EQUIPO B) ---
  static const double teamBListStartY = 594.7; // Altura del primer jugador
  static const double teamBColNumX = 22.5;    // Columna "#"
  static const double teamBColNameX = 50.0;  // Columna "Nombre"
  static const double teamBColFoulsX = 235.0; // Inicio casillas de faltas (1 a 5)

  // --- 5. CONFIGURACIÓN GENERAL DE TABLAS ---
  static const double rowHeight = 13.0;      // Espacio vertical entre jugadores
  static const double foulBoxWidth = 12.0;   // Ancho de cada casilla de falta pequeña

  // --- 6. MARCADOR FINAL (Pie de página) ---
  static const double scoreBoxY = 772.0;     // Altura del cuadro de score final
  static const double scoreAX = 450.0;
  static const double scoreBX = 535.0;
  static const double scoreFontSize = 20.0;
}

/// ==============================================================
/// 🖨️ GENERADOR DE PDF
/// ==============================================================
class PdfGenerator {
  
  /// Genera y muestra la vista previa del PDF
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

  /// Genera y comparte el PDF directamente (WhatsApp, etc.)
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
      // 1. Cargar imagen de fondo
      // Asegúrate de que este archivo exista en assets/images/
      final imageBytes = await rootBundle.load('assets/images/hoja_anotacion.png');
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      // 2. Crear página
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // Margen cero para fondo completo
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

                // --- NOMBRES DE EQUIPOS ---
                _drawText(teamAName.toUpperCase(), x: PdfCoords.teamANameX, y: PdfCoords.teamANameY, isBold: true),
                _drawText(teamBName.toUpperCase(), x: PdfCoords.teamBNameX, y: PdfCoords.teamBNameY, isBold: true),

                // --- LISTA DE JUGADORES EQUIPO A ---
                ..._buildRosterList(
                  players: state.teamAOnCourt + state.teamABench, // Lista completa
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

                // --- MARCADOR FINAL ---
                _drawText(
                  "${state.scoreA}",
                  x: PdfCoords.scoreAX,
                  y: PdfCoords.scoreBoxY,
                  fontSize: PdfCoords.scoreFontSize,
                  isBold: true,
                  color: PdfColors.blue900, // Color distintivo para el score
                ),
                _drawText(
                  "${state.scoreB}",
                  x: PdfCoords.scoreBX,
                  y: PdfCoords.scoreBoxY,
                  fontSize: PdfCoords.scoreFontSize,
                  isBold: true,
                  color: PdfColors.blue900,
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      // Aquí manejas la excepción particular de PDF y la lanzas como una de tu dominio
      throw Exception('Error al generar PDF: $e');
    }

    return pdf;
  }

  // --- HELPERS DE DIBUJO ---

  /// Construye la lista visual de jugadores (Filas con Número, Nombre y Faltas)
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

    // Solo dibujamos hasta 12 jugadores (límite estándar de hoja)
    int limit = players.length > 12 ? 12 : players.length;

    for (var i = 0; i < limit; i++) {
      final playerName = players[i];
      final stat = stats[playerName] ?? const PlayerStats();
      final dorsal = "${i + 4}"; // Simulación de dorsal (4, 5, 6...)

      // 1. Número
      widgets.add(_drawText(dorsal, x: startXNum, y: currentY, fontSize: 10));

      // 2. Nombre (Recortar si es muy largo)
      String displayName = playerName.length > 18 
          ? "${playerName.substring(0, 16)}..." 
          : playerName;
      widgets.add(_drawText(displayName, x: startXName, y: currentY, fontSize: 10));

      // 3. Faltas (Dibujar 'X' o 'P' en cada casilla)
      for (int f = 0; f < stat.fouls; f++) {
        if (f >= 5) break; // Máximo 5 faltas visuales
        
        // Calculamos la posición X de la falta actual
        // (Posición inicial + (número de falta * ancho de casilla))
        double foulX = startXFouls + (f * PdfCoords.foulBoxWidth);
        
        // Dibujamos la marca. Si es la 5ta, la ponemos roja (opcional)
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

      // Bajamos al siguiente renglón
      currentY -= PdfCoords.rowHeight; 
    }
    return widgets;
  }

  /// Dibuja texto simple en una posición absoluta (X, Y)
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