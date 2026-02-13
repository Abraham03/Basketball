import 'package:drift/drift.dart';
import 'base_table.dart';

// Tabla de Partidos
@DataClassName('BasketballMatch')
class Matches extends Table with BaseTable {
  TextColumn get tournamentId => text().nullable()();
  TextColumn get venueId => text().nullable()();
  TextColumn get teamAName => text()();
  TextColumn get teamBName => text()();

  // Estado del partido (Pending, InProgress, Finished)
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  IntColumn get scoreA => integer().withDefault(const Constant(0))();
  IntColumn get scoreB => integer().withDefault(const Constant(0))();
  IntColumn get teamAId => integer().nullable()();
  IntColumn get teamBId => integer().nullable()();
  TextColumn get mainReferee => text().nullable()();
  TextColumn get auxReferee => text().nullable()();
  TextColumn get scorekeeper => text().nullable()();
  TextColumn get signatureData => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DataClassName('Team')
class Teams extends Table with BaseTable {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get shortName => text().nullable()();
  TextColumn get coachName => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DataClassName('Tournament')
class Tournaments extends Table with BaseTable {
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get category => text().nullable()();
  // Estado: ACTIVE, FINISHED
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  
  // Fechas opcionales
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// Tabla de Jugadores (Catálogo Global)
class Players extends Table with BaseTable {
  // Reemplazamos 'fullName' por 'name' si quieres coincidir exacto, o lo mapeamos.
  // En tu DB real es 'name', así que usaremos 'name' para ser consistentes.
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  // Columnas nuevas que coinciden con tu DB real
  IntColumn get teamId => integer().references(Teams, #id, onDelete: KeyAction.cascade)();
  IntColumn get defaultNumber => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  
  // Opcional: Foto si la usas en la app, aunque no esté en el SQL que me pasaste
  //TextColumn get photoPath => text().nullable()(); 
}

@DataClassName('Venue')
class Venues extends Table with BaseTable {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get address => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

// Tabla Intermedia (Roster) - Jugador en un Partido específico
@DataClassName('RosterEntry') // Nombre de la clase Dart generada
class MatchRosters extends Table with BaseTable {
  // Foreign Keys con acciones en cascada
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get playerId =>
      text().references(Players, #id, onDelete: KeyAction.cascade)();

  TextColumn get teamSide => text()(); // 'A' o 'B'
  IntColumn get jerseyNumber => integer()(); // El número de HOY
  BoolColumn get isCaptain => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  // Índice para búsquedas rápidas: "Dame el roster del partido X"
  @override
  List<Set<Column>> get uniqueKeys => [
    {
      matchId,
      playerId,
    }, // Un jugador no puede estar 2 veces en el mismo partido
  ];
}

// Tabla de Eventos (Puntos y Faltas)
class GameEvents extends Table with BaseTable {
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get playerId => text().nullable().references(
    Players,
    #id,
  )(); // Nullable porque un Timeout no tiene jugador

  // Tipos: 'POINT_1', 'POINT_2', 'POINT_3', 'FOUL', 'TIMEOUT'
  TextColumn get type => text()();

  IntColumn get period => integer()(); // 1, 2, 3, 4
  TextColumn get clockTime => text()(); // "04:59"
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  
}

@DataClassName('TournamentTeam')
class TournamentTeams extends Table with BaseTable {
  // Referencias a las otras tablas (Foreign Keys)
  TextColumn get tournamentId => text().references(Tournaments, #id, onDelete: KeyAction.cascade)();
  TextColumn get teamId => text().references(Teams, #id, onDelete: KeyAction.cascade)();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  // Clave compuesta para evitar duplicados (Un equipo no puede estar 2 veces en el mismo torneo)
  @override
  List<Set<Column>> get uniqueKeys => [{tournamentId, teamId}];
}
