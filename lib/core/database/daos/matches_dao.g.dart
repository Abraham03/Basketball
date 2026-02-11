// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_dao.dart';

// ignore_for_file: type=lint
mixin _$MatchesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MatchesTable get matches => attachedDatabase.matches;
  $TeamsTable get teams => attachedDatabase.teams;
  $PlayersTable get players => attachedDatabase.players;
  $MatchRostersTable get matchRosters => attachedDatabase.matchRosters;
  $GameEventsTable get gameEvents => attachedDatabase.gameEvents;
  MatchesDaoManager get managers => MatchesDaoManager(this);
}

class MatchesDaoManager {
  final _$MatchesDaoMixin _db;
  MatchesDaoManager(this._db);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db.attachedDatabase, _db.matches);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$MatchRostersTableTableManager get matchRosters =>
      $$MatchRostersTableTableManager(_db.attachedDatabase, _db.matchRosters);
  $$GameEventsTableTableManager get gameEvents =>
      $$GameEventsTableTableManager(_db.attachedDatabase, _db.gameEvents);
}
