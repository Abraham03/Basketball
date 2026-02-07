import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/utils/pdf_generator.dart';
import '../logic/match_game_controller.dart'; // Importa para tener acceso a MatchState

class PdfPreviewScreen extends StatelessWidget {
  final MatchState state;
  final String teamAName;
  final String teamBName;
  final String tournamentName;
  final String venueName;
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;

  const PdfPreviewScreen({
    super.key,
    required this.state,
    required this.teamAName,
    required this.teamBName,
    required this.tournamentName,
    required this.venueName,
    required this.mainReferee,
    required this.auxReferee,
    required this.scorekeeper,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista Previa del Acta"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        // Esta función construye el PDF al vuelo
        build: (format) => PdfGenerator.generateBytes(
          state,
          teamAName,
          teamBName,
          tournamentName: tournamentName,
          venueName: venueName,
          mainReferee: mainReferee,
          auxReferee: auxReferee,
          scorekeeper: scorekeeper,
        ),
        // Opcional: Configura qué acciones permites
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false, // Bloquea cambio de tamaño de hoja si solo usas A4
        canDebug: false,
      ),
    );
  }
}