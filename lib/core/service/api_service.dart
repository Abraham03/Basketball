// lib/core/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/catalog_models.dart';

class ApiService {
  // ⚠️ CAMBIA ESTO POR TU URL REAL DE HOSTINGER
  static const String _baseUrl = 'https://techsolutions.management/api.php';

  // Nuevo método para traer datos filtrados por torneo
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

  Future<CatalogData> fetchCatalogs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=get_data'));

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

Future<int> createTeam(String name, String shortName, String coach, {String? tournamentId}) async {
    try {
      final bodyData = {
        "name": name,
        "shortName": shortName,
        "coachName": coach,
        if (tournamentId != null) "tournament_id": tournamentId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?action=create_team'),
        headers: {'Content-Type': 'application/json'}, // IMPORTANTE HEADER
        body: jsonEncode(bodyData),
      );
      
      if (response.statusCode != 200) throw Exception('HTTP Error: ${response.statusCode}');
      final body = jsonDecode(response.body);
      if (body['status'] != 'success') throw Exception(body['message']);
      
      // Devolvemos el ID nuevo que viene del PHP
      return body['newId']; 

    } catch (e) {
      throw Exception('Error creando equipo: $e');
    }
  }

Future<int> addPlayer(int teamId, String name, int number) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=add_player'),
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
  // Crear Torneo
  Future<void> createTournament(String name, String category) async {
    final response = await http.post(
      Uri.parse('$_baseUrl?action=create_tournament'),
      body: jsonEncode({"name": name, "category": category}),
    );
    _checkResponse(response);
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
}