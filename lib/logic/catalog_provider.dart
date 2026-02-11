import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../core/models/catalog_models.dart' as model;
import '../core/models/catalog_models.dart';
import '../core/service/api_service.dart';
import '../logic/tournament_provider.dart';



// Provider que instancia el servicio API
final apiServiceProvider = Provider((ref) => ApiService());

// FutureProvider que descarga los datos al iniciar la pantalla
final catalogProvider = FutureProvider<CatalogData>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.fetchCatalogs();
});

final tournamentDataByIdProvider = StreamProvider.family<model.CatalogData, String>((ref, tournamentId) async* {
  final db = ref.read(databaseProvider);
  
  // TRUCO: Escuchamos la tabla PLAYERS.
  // Así, cuando agregues un jugador, este stream emitirá un evento y se recargará todo.
  // Si también agregas equipos frecuentemente, podrías necesitar combinarlos, 
  // pero para tu caso de "Agregar Jugador", esto es suficiente.
  final stream = db.select(db.players).watch(); 
  
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
            coachName: teamRow.coachName ?? ''
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