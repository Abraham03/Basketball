// lib/core/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../models/catalog_models.dart';

class ApiService {
  
  static const String _baseUrl = 'https://basket.techsolutions.management/api.php';

// Llamar al backend para que genere el fixture automáticamente
  Future<bool> generateFixture({
    required String tournamentId,
    required int vueltas,
    required int ptsVictoria,
    required int ptsDerrota,
    required int ptsEmpate,
    required int ptsForfeitWin,
    required int ptsForfeitLoss,
  }) async {
    try {
      final payload = {
        "action": "generate_fixture",
        "tournament_id": tournamentId,
        "config": {
          "vueltas": vueltas,
          "pts_victoria": ptsVictoria,
          "pts_derrota": ptsDerrota,
          "pts_empate": ptsEmpate,
          "pts_forfeit_win": ptsForfeitWin,
          "pts_forfeit_loss": ptsForfeitLoss
        }
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      print("Error generando fixture: $e");
      return false;
    }
  }

  // Método para traer datos filtrados por torneo
  Future<CatalogData> fetchTournamentData(String tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_tournament_data&tournament_id=$tournamentId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];

          // Nota: Como tu backend getTournamentData no devuelve 'venues', 
          // usaremos una lista vacía o deberás ajustar tu PHP si quieres venues específicas.
          // Aquí asumimos que los Venues son globales y quizá quieras obtenerlos aparte,
          // pero para evitar errores, pasamos lista vacía o lo que venga.
          return CatalogData(
            tournaments: [], // Ya sabemos en qué torneo estamos
            venues: (data['venues'] as List)
                .map((e) => Venue.fromJson(e))
                .toList(),      // Ya devuelve la lista global
            teams: (data['teams'] as List)
                .map((e) => Team.fromJson(e))
                .toList(),
            players: (data['players'] as List)
                .map((e) => Player.fromJson(e))
                .toList(),
            relationships: (data['tournament_teams'] as List)
                .map((e) => TournamentTeamRelation.fromJson(e))
                .toList(),
          );
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error cargando datos del torneo: $e');
    }
  }

  Future<CatalogData> fetchCatalogs(String tournamentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=get_sync_data&tournament_id=$tournamentId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];

          return CatalogData(
            tournaments: (data['tournaments'] as List)
                .map((e) => Tournament.fromJson(e))
                .toList(),
            venues: (data['venues'] as List)
                .map((e) => Venue.fromJson(e))
                .toList(),
            teams: (data['teams'] as List)
                .map((e) => Team.fromJson(e))
                .toList(),
            players: (data['players'] as List)
                .map((e) => Player.fromJson(e))
                .toList(),
            relationships: (data['tournament_teams'] as List)
                .map((e) => TournamentTeamRelation.fromJson(e))
                .toList(),
          );
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error conectando al servidor: $e');
    }
  }

  // Obtener el Fixture (Calendario)
  Future<Map<String, dynamic>> fetchFixture(String tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_fixture&tournament_id=$tournamentId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; // Retorna { "tournament_name": "...", "rounds": {...} }
        }
      }
      return {};
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

Future<int> createTeam(String name, String shortName, String coach, {String? tournamentId}) async {
    try {
      final bodyData = {
        "name": name,
        "shortName": shortName,
        "coachName": coach,
      };

      // Asegurarse de no mandar null ni true
      if (tournamentId != null && 
          tournamentId.isNotEmpty && 
          tournamentId != "true" && 
          tournamentId != "false") {
          bodyData["tournament_id"] = tournamentId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?action=create_team'),
        headers: {'Content-Type': 'application/json'}, // IMPORTANTE HEADER
        body: jsonEncode(bodyData),
      );
      
      if (response.statusCode != 200) throw Exception('HTTP Error: ${response.statusCode}');
      final body = jsonDecode(response.body);
      if (body['status'] != 'success') throw Exception(body['message']);
      
      // Devolvemos el ID nuevo que viene del PHP
      return int.parse(body['newId'].toString()); 

    } catch (e) {
      throw Exception('Error creando equipo: $e');
    }
  }

Future<int> addPlayer(int teamId, String name, int number) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=add_player'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "teamId": teamId,
          "name": name,
          "number": number,
        }),
      );
      
      _checkResponse(response); // Tu helper verifica status success
      
      final body = jsonDecode(response.body);
      return body['newId']; // Devolvemos el ID
      
    } catch (e) {
      throw Exception('Error agregando jugador: $e');
    }
  }

  Future<bool> updatePlayer(String id, int teamId ,String name, int number) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl?action=update_player'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id": id,
        "teamId": teamId,
        "name": name,
        "number": number,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['status'] == 'success';
    }
    return false;
  } catch (e) {
    
    print("Error editando jugador en nube: $e");
    return false;
  }
}


// AHORA DEVUELVE UN Future<String> (El ID real que genera PHP)
  Future<String> createTournament(String name, String category) async {
    final response = await http.post(
      Uri.parse('$_baseUrl?action=create_tournament'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"name": name, "category": category}),
    );
    
    _checkResponse(response);
    
    final jsonResponse = jsonDecode(response.body);
    // Tu PHP devuelve 'newId', lo capturamos aquí
    if (jsonResponse['status'] == 'success' && jsonResponse['newId'] != null) {
      return jsonResponse['newId'].toString(); // Retorna el número como String (ej. "15")
    } else {
      throw Exception("No se recibió el ID del torneo creado");
    }
  }

  // Helper para validar respuestas genéricas
  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) throw Exception('HTTP Error: ${response.statusCode}');
    final body = jsonDecode(response.body);
    if (body['status'] != 'success') throw Exception(body['message']);
  }
  

  // Método para sincronizar el partido completo
  Future<bool> syncMatchData(Map<String, dynamic> matchPayload) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=sync_match'), // Asegúrate que tu PHP acepte este action
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(matchPayload),
      );

      if (response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

 Future<bool> syncMatchDataMultipart({
    required Map<String, dynamic> matchData,
    required Uint8List? pdfBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl?action=sync_match'),
      );

      // 1. Enviamos el JSON como un campo de texto stringificado
      // En PHP lo recibirás como: $data = json_decode($_POST['data'], true);
      request.fields['data'] = jsonEncode(matchData);

      // 2. Adjuntamos el PDF si existe
      if (pdfBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'pdf_report', // Nombre del campo en PHP ($_FILES['pdf_report'])
            pdfBytes,
            filename: 'match_report.pdf',
            contentType: MediaType('application', 'pdf'), // Opcional, requiere package:http_parser
          ),
        );
      }

      // 3. Enviar y leer respuesta
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      } else {
        // Puedes loguear response.body aquí para ver errores de PHP
        return false;
      }
    } catch (e) {
      return false;
    }
  } 
}