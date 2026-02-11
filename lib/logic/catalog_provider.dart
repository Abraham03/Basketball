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

final tournamentDataByIdProvider = FutureProvider.family<model.CatalogData, String>((ref, tournamentId) async {
  final db = ref.read(databaseProvider);
  
  // 1. Equipos filtrados (Ya lo tienes bien)
  final teamsQuery = db.select(db.teams).join([
    innerJoin(
      db.tournamentTeams, 
      db.tournamentTeams.teamId.equalsExp(db.teams.id)
    )
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

  // 2. Canchas (Ya lo tienes bien)
  final localVenues = await db.select(db.venues).get();

  // 3. JUGADORES (ESTO ES LO NUEVO QUE FALTABA)
  // Como ya filtramos los equipos, podemos traer los jugadores de esos equipos.
  // O simplemente traer todos los jugadores locales y que la UI los filtre (más fácil si no son miles).
  final localPlayers = await db.select(db.players).get();

  return model.CatalogData(
    tournaments: [],
    relationships: [], 
    venues: localVenues.map((v) => model.Venue(
      id: int.parse(v.id), 
      name: v.name, 
      address: v.address ?? ''
    )).toList(),
    teams: localTeams,
    // AHORA MAPEAMOS LOS JUGADORES
    players: localPlayers.map((p) => model.Player(
      id: int.parse(p.id), 
      teamId: p.teamId, // Ahora es directo, sin parsear strings raros
      name: p.name,     // Usamos la columna 'name'
      defaultNumber: p.defaultNumber 
    )).toList(),
  );
});