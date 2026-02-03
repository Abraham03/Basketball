// lib/core/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/catalog_models.dart';

class ApiService {
  // ⚠️ CAMBIA ESTO POR TU URL REAL DE HOSTINGER
  static const String _baseUrl = 'https://techsolutions.management/api.php';

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

  Future<void> createTeam(String name, String shortName, String coach) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=create_team'),
        body: jsonEncode({
          "name": name,
          "shortName": shortName,
          "coachName": coach,
        }),
      );
      _checkResponse(response);
    } catch (e) {
      throw Exception('Error creando equipo: $e');
    }
  }

  Future<void> addPlayer(int teamId, String name, int number) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=add_player'),
        body: jsonEncode({
          "teamId": teamId,
          "name": name,
          "number": number,
        }),
      );
      _checkResponse(response);
    } catch (e) {
      throw Exception('Error agregando jugador: $e');
    }
  }

  // Helper para validar respuestas genéricas
  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) throw Exception('HTTP Error: ${response.statusCode}');
    final body = jsonDecode(response.body);
    if (body['status'] != 'success') throw Exception(body['message']);
  }
  
  // Aquí agregaremos luego el método syncMatch para subir datos
}