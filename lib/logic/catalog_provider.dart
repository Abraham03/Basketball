// lib/logic/catalog_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../core/models/catalog_models.dart' as model;
import '../core/models/catalog_models.dart';
import '../core/service/api_service.dart';
import '../logic/tournament_provider.dart';

// Provider que instancia el servicio API
final apiServiceProvider = Provider((ref) => ApiService());

// FutureProvider que descarga los datos al iniciar la pantalla
final catalogProvider = FutureProvider.family<CatalogData, String>((ref,tournamentId) async {
  final api = ref.read(apiServiceProvider);
  return api.fetchCatalogs(tournamentId);
});

final tournamentDataByIdProvider = StreamProvider.family<model.CatalogData, String>((ref, tournamentId) async* {
  final db = ref.read(databaseProvider);
  
  // TRUCO: Escuchamos la tabla PLAYERS y TEAMS para que recargue si hay cambios.
  final stream = db.select(db.teams).watch(); 
  
  // Iniciamos con los datos actuales
  yield* stream.asyncMap((_) async {
    // 1. Equipos
    final teamsQuery = db.select(db.teams).join([
      innerJoin(db.tournamentTeams, db.tournamentTeams.teamId.equalsExp(db.teams.id))
    ]);
    teamsQuery.where(db.tournamentTeams.tournamentId.equals(tournamentId));
    final resultRows = await teamsQuery.get();
    
    final localTeams = resultRows.map((row) {
        final teamRow = row.readTable(db.teams);
        return model.Team(
            id: int.parse(teamRow.id), 
            name: teamRow.name, 
            shortName: teamRow.shortName ?? '', 
            coachName: teamRow.coachName ?? '',
            logoUrl: teamRow.logoUrl // <--- ¡AQUÍ ESTÁ LA MAGIA!
        );
    }).toList();

    // 2. Canchas
    final localVenues = await db.select(db.venues).get();

    // 3. Jugadores
    final localPlayers = await db.select(db.players).get();

    return model.CatalogData(
      tournaments: [],
      relationships: [], 
      venues: localVenues.map((v) => model.Venue(id: int.parse(v.id), name: v.name, address: v.address ?? '')).toList(),
      teams: localTeams,
      players: localPlayers.map((p) => model.Player(
        id: int.parse(p.id), 
        teamId: p.teamId, 
        name: p.name, 
        defaultNumber: p.defaultNumber
      )).toList(),
    );
  });
});