import 'package:drift/drift.dart';
import 'base_table.dart';

// Tabla de Partidos
@DataClassName('BasketballMatch')
class Matches extends Table with BaseTable {
  TextColumn get tournamentId => text().nullable()();
  TextColumn get teamAName => text()();
  TextColumn get teamBName => text()();
  DateTimeColumn get scheduledDate => dateTime()();

  // Estado del partido (Pending, InProgress, Finished)
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  IntColumn get scoreA => integer().withDefault(const Constant(0))();
  IntColumn get scoreB => integer().withDefault(const Constant(0))();
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
}

// Tabla de Jugadores (Catálogo Global)
class Players extends Table with BaseTable {
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  TextColumn get photoPath => text().nullable()(); // Ruta local
  TextColumn get teamNameReference => text().nullable()();
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
}
