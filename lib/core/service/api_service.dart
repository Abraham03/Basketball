// lib/core/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart'; 
import '../models/catalog_models.dart';

class ApiService {
  
  static const String _baseUrl = 'https://basket.techsolutions.management/api.php';

  Future<bool> saveTournamentRules({
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
        "action": "save_tournament_rules",
        "tournament_id": tournamentId,
        "config": {
          "matchups_per_pair": vueltas,
          "points_win": ptsVictoria,
          "points_draw": ptsEmpate,
          "points_loss": ptsDerrota,
          "points_forfeit_win": ptsForfeitWin,
          "points_forfeit_loss": ptsForfeitLoss
        }
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // --- FUNCIONES PARA SEDES (VENUES) ---
  // ==========================================
  Future<int> createVenue(String name, String address) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=create_venue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "address": address,
        }),
      );
      
      _checkResponse(response);
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['data'] != null && jsonResponse['data']['newId'] != null) {
        return int.parse(jsonResponse['data']['newId'].toString()); 
      }
      throw Exception("ID de sede no recibido.");
    } catch (e) {
      throw Exception('Error creando sede: $e');
    }
  }

  Future<bool> updateVenue({
    required String id,
    required String name,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=update_venue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": id,
          "name": name,
          "address": address,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- NUEVO: OBTENER LISTA DE TORNEOS DESDE LA NUBE ---
  Future<List<Map<String, dynamic>>> fetchCloudTournaments() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=get_tournaments_list'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> generateFixture({
    required String tournamentId,
  }) async {
    try {
      final payload = {
        "action": "generate_fixture",
        "tournament_id": tournamentId,
        // Ya no enviamos "config" aquí porque lo enviaremos por separado
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateFixtureTeams({
    required int fixtureId,
    required int newTeamAId,
    required int newTeamBId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=update_fixture_teams'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "fixture_id": fixtureId,
          "new_team_a_id": newTeamAId,
          "new_team_b_id": newTeamBId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncManualFixtures({
    required String tournamentId,
    required List<Map<String, dynamic>> fixtures,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=sync_manual_fixtures'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "tournament_id": tournamentId,
          "fixtures": fixtures,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<CatalogData> fetchTournamentData(String tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_tournament_data&tournament_id=$tournamentId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];

          return CatalogData(
            tournaments: [], 
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
            officials: [],    
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

      if (response.statusCode == 200 || response.statusCode == 201) {
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
            fixturesRaw: data['fixtures'] ?? [],
            officials: data['officials'] != null 
                ? (data['officials'] as List).map((e) => Official.fromJson(e)).toList() 
                : [],    
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

  Future<int> createOfficial(String name, String role, String? signature) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=create_official'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "role": role,
          "signature": signature,
        }),
      );
      
      _checkResponse(response);
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['data'] != null && jsonResponse['data']['id'] != null) {
        return int.parse(jsonResponse['data']['id'].toString()); 
      }
      throw Exception("ID de oficial no recibido.");
    } catch (e) {
      throw Exception('Error creando oficial: $e');
    }
  }

  Future<bool> deleteVenue(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=delete_venue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"id": id}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteOfficial(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=delete_official'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"id": id}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOfficial({
    required String id,
    required String name,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=update_official'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": id,
          "name": name,
          "role": role,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchFixture(String tournamentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_fixture&tournament_id=$tournamentId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; 
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

      if (tournamentId != null && 
          tournamentId.isNotEmpty && 
          tournamentId != "true" && 
          tournamentId != "false") {
          bodyData["tournament_id"] = tournamentId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?action=create_team'),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode(bodyData),
      );
      
      _checkResponse(response);
      final body = jsonDecode(response.body);
      
      if (body['data'] != null && body['data']['newId'] != null) {
        return int.parse(body['data']['newId'].toString()); 
      } else if (body['newId'] != null) {
        return int.parse(body['newId'].toString()); 
      } else {
        throw Exception("ID no recibido del servidor.");
      }

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
      
      _checkResponse(response); 
      
      final body = jsonDecode(response.body);
      
      if (body['data'] != null && body['data']['newId'] != null) {
        return int.parse(body['data']['newId'].toString()); 
      } else if (body['newId'] != null) {
        return int.parse(body['newId'].toString()); 
      } else {
        throw Exception("ID de jugador no recibido del servidor.");
      }
      
    } catch (e) {
      throw Exception('Error agregando jugador: $e');
    }
  }

  Future<bool> updateTeam({
    required String id,
    required String name,
    required String shortName,
    required String coachName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=update_team'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": id,
          "name": name,
          "shortName": shortName,
          "coachName": coachName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> createTournament(String name, String category) async {
    final response = await http.post(
      Uri.parse('$_baseUrl?action=create_tournament'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"name": name, "category": category}),
    );
    
    _checkResponse(response);
    
    final jsonResponse = jsonDecode(response.body);
    
    if (jsonResponse['status'] == 'success') {
       if (jsonResponse['data'] != null && jsonResponse['data']['newId'] != null) {
         return jsonResponse['data']['newId'].toString();
       } 
       else if (jsonResponse['newId'] != null) {
         return jsonResponse['newId'].toString();
       }
    }
    
    throw Exception("No se recibió el ID del torneo creado");
  }

  // Obtiene los equipos y su estatus para el constructor manual
  Future<List<Map<String, dynamic>>> fetchTeamsSchedulingStatus(String tournamentId, int roundId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_team_scheduling_status&tournament_id=$tournamentId&round_id=$roundId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return List<Map<String, dynamic>>.from(jsonResponse['data']); 
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addManualFixture({
    required String tournamentId,
    required int roundOrder,
    required int teamAId,
    required int teamBId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=add_manual_fixture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "tournament_id": tournamentId,
          "round_order": roundOrder,
          "team_a_id": teamAId,
          "team_b_id": teamBId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSingleFixture(int fixtureId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=delete_single_fixture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "fixture_id": fixtureId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Ahora aceptamos 200 (OK) y 201 (Created) como exitosos
  void _checkResponse(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body['status'] != 'success') {
      throw Exception(body['message']);
    }
  }
  
  Future<bool> syncMatchData(Map<String, dynamic> matchPayload) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?action=sync_match'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(matchPayload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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

      request.fields['data'] = jsonEncode(matchData);

      if (pdfBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'pdf_report', 
            pdfBytes,
            filename: 'match_report.pdf',
            contentType: MediaType('application', 'pdf'), 
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
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