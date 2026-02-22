import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/utils/pdf_generator.dart';
import '../logic/match_game_controller.dart'; 

class PdfPreviewScreen extends StatelessWidget {
  final MatchState state;
  final String teamAName;
  final String teamBName;
  final String tournamentName;
  final String venueName;
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;
  final Uint8List? protestSignature; 
  final String coachA;
  final String coachB;
  final int? captainAId;
  final int? captainBId;
  final DateTime? matchDate;

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
    this.protestSignature,
    this.coachA = "",
    this.coachB = "",
    this.captainAId,
    this.captainBId,
    this.matchDate
  });

  void _sharePdf(BuildContext context) async {
    try {
      await PdfGenerator.generateAndShare(
         state,
         teamAName,
         teamBName,
         tournamentName: tournamentName,
         venueName: venueName,
         mainReferee: mainReferee,
         auxReferee: auxReferee,
         scorekeeper: scorekeeper,
         protestSignature: protestSignature,
         coachA: coachA,
         coachB: coachB,
         captainAId: captainAId,
         captainBId: captainBId,
         matchDate: matchDate,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
      }
    }
  }

  // Función renombrada y adaptada para "Descargar"
  void _downloadPdf(BuildContext context) async {
    try {
      // Usamos el método share porque nativamente en Android/iOS es la forma 
      // de abrir el diálogo de "Guardar en Archivos" o "Descargar"
      await PdfGenerator.generateAndPreview(
         state,
         teamAName,
         teamBName,
         tournamentName: tournamentName,
         venueName: venueName,
         mainReferee: mainReferee,
         auxReferee: auxReferee,
         scorekeeper: scorekeeper,
         protestSignature: protestSignature,
         coachA: coachA,
         coachB: coachB,
         captainAId: captainAId,
         captainBId: captainBId,
         matchDate: matchDate,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al descargar: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista Previa del Acta", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1F2B), // Combinando con tu modo oscuro de la app
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, size: 28), // Ícono de descarga
            tooltip: "Compartir PDF",
            onPressed: () => _downloadPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 28), // Ícono de descarga
            tooltip: "Descargar PDF",
            onPressed: () => _sharePdf(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfGenerator.generateBytes(
          state,
          teamAName,
          teamBName,
          tournamentName: tournamentName,
          venueName: venueName,
          mainReferee: mainReferee,
          auxReferee: auxReferee,
          scorekeeper: scorekeeper,
          protestSignature: protestSignature,
          coachA: coachA,
          coachB: coachB,
          captainAId: captainAId,
          captainBId: captainBId,
          matchDate: matchDate,
        ),
        
        // --- AQUÍ ESTÁ LA MAGIA PARA OCULTAR LOS BOTONES DEFAULT ---
        useActions: false, // Desactiva la barra inferior por defecto por completo
        
        canChangePageFormat: false, 
        canDebug: false,
      ),
    );
  }
}