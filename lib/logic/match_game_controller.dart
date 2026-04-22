import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/matches_dao.dart';
import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart' as models;
import '../core/service/api_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScoreEvent {
  final int period;
  final String teamId;
  final String playerId;
  final int dbPlayerId;
  final String playerNumber;
  final int points;
  final int scoreAfter;
  final String type;

  const ScoreEvent({
    required this.period,
    required this.teamId,
    required this.playerId,
    this.dbPlayerId = 0,
    required this.playerNumber,
    required this.points,
    required this.scoreAfter,
    this.type = "POINT",
  });
}

class PlayerStats {
  final int dbId;
  final String playerName;
  final int points;
  final int fouls;
  final bool isOnCourt;
  final bool isStarter;
  final bool hasPlayed;
  final String playerNumber;
  final List<String> foulDetails;

  const PlayerStats({
    this.dbId = 0,
    this.playerName = "",
    this.points = 0,
    this.fouls = 0,
    this.isOnCourt = false,
    this.isStarter = false,
    this.hasPlayed = false,
    this.playerNumber = "00",
    this.foulDetails = const [],
  });

  PlayerStats copyWith({
    int? dbId,
    String? playerName,
    int? points,
    int? fouls,
    bool? isOnCourt,
    bool? isStarter,
    bool? hasPlayed,
    String? playerNumber,
    List<String>? foulDetails,
  }) {
    return PlayerStats(
      dbId: dbId ?? this.dbId,
      playerName: playerName ?? this.playerName,
      points: points ?? this.points,
      fouls: fouls ?? this.fouls,
      isOnCourt: isOnCourt ?? this.isOnCourt,
      isStarter: isStarter ?? this.isStarter,
      hasPlayed: hasPlayed ?? this.hasPlayed,
      playerNumber: playerNumber ?? this.playerNumber,
      foulDetails: foulDetails ?? this.foulDetails,
    );
  }
}

class MatchState {
  final String matchId;
  final String? fixtureId;
  final int scoreA;
  final int scoreB;
  final Duration timeLeft;
  final bool isRunning;
  final int currentPeriod;
  final String possession;
  final Map<int, List<int>> periodScores;
  final List<ScoreEvent> scoreLog;
  final int? tournamentId;
  final int? venueId;
  final int? teamAId;
  final int? teamBId;
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;
  final String forfeitStatus;
  final String observaciones;

  final List<String> teamAOnCourt;
  final List<String> teamABench;
  final List<String> teamBOnCourt;
  final List<String> teamBBench;

  final List<String> teamATimeouts1;
  final List<String> teamATimeouts2;
  final List<String> teamAOTTimeouts;

  final List<String> teamBTimeouts1;
  final List<String> teamBTimeouts2;
  final List<String> teamBOTTimeouts;

  final Map<String, PlayerStats> playerStats;

  const MatchState({
    this.matchId = '',
    this.fixtureId,
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeLeft = const Duration(minutes: 10),
    this.isRunning = false,
    this.currentPeriod = 1,
    this.possession = '',
    this.periodScores = const {
      1: [0, 0],
    },
    this.scoreLog = const [],
    this.teamAOnCourt = const [],
    this.teamABench = const [],
    this.teamBOnCourt = const [],
    this.teamBBench = const [],
    this.playerStats = const {},
    this.tournamentId,
    this.venueId,
    this.teamAId,
    this.teamBId,
    this.mainReferee = '',
    this.auxReferee = '',
    this.scorekeeper = '',
    this.forfeitStatus = 'NONE',
    this.observaciones = 'Sin novedad',
    this.teamATimeouts1 = const [],
    this.teamATimeouts2 = const [],
    this.teamAOTTimeouts = const [],
    this.teamBTimeouts1 = const [],
    this.teamBTimeouts2 = const [],
    this.teamBOTTimeouts = const [],
  });

  MatchState copyWith({
    String? matchId,
    String? fixtureId,
    int? scoreA,
    int? scoreB,
    Duration? timeLeft,
    bool? isRunning,
    int? currentPeriod,
    String? possession,
    Map<int, List<int>>? periodScores,
    List<ScoreEvent>? scoreLog,
    List<String>? teamAOnCourt,
    List<String>? teamABench,
    List<String>? teamBOnCourt,
    List<String>? teamBBench,
    Map<String, PlayerStats>? playerStats,
    int? tournamentId,
    int? venueId,
    int? teamAId,
    int? teamBId,
    String? mainReferee,
    String? auxReferee,
    String? scorekeeper,
    String? forfeitStatus,
    String? observaciones,
    List<String>? teamATimeouts1,
    List<String>? teamATimeouts2,
    List<String>? teamAOTTimeouts,
    List<String>? teamBTimeouts1,
    List<String>? teamBTimeouts2,
    List<String>? teamBOTTimeouts,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      fixtureId: fixtureId ?? this.fixtureId,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      timeLeft: timeLeft ?? this.timeLeft,
      isRunning: isRunning ?? this.isRunning,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      possession: possession ?? this.possession,
      periodScores: periodScores ?? this.periodScores,
      scoreLog: scoreLog ?? this.scoreLog,
      teamAOnCourt: teamAOnCourt ?? this.teamAOnCourt,
      teamABench: teamABench ?? this.teamABench,
      teamBOnCourt: teamBOnCourt ?? this.teamBOnCourt,
      teamBBench: teamBBench ?? this.teamBBench,
      playerStats: playerStats ?? this.playerStats,
      tournamentId: tournamentId ?? this.tournamentId,
      venueId: venueId ?? this.venueId,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      mainReferee: mainReferee ?? this.mainReferee,
      auxReferee: auxReferee ?? this.auxReferee,
      scorekeeper: scorekeeper ?? this.scorekeeper,
      forfeitStatus: forfeitStatus ?? this.forfeitStatus,
      observaciones: observaciones ?? this.observaciones,
      teamATimeouts1: teamATimeouts1 ?? this.teamATimeouts1,
      teamATimeouts2: teamATimeouts2 ?? this.teamATimeouts2,
      teamAOTTimeouts: teamAOTTimeouts ?? this.teamAOTTimeouts,
      teamBTimeouts1: teamBTimeouts1 ?? this.teamBTimeouts1,
      teamBTimeouts2: teamBTimeouts2 ?? this.teamBTimeouts2,
      teamBOTTimeouts: teamBOTTimeouts ?? this.teamBOTTimeouts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scoreA': scoreA,
      'scoreB': scoreB,
      'timeLeft': timeLeft.inSeconds,
      'isRunning': isRunning,
      'currentPeriod': currentPeriod,
      'possession': possession,
      'teamATimeouts1': teamATimeouts1,
      'teamATimeouts2': teamATimeouts2,
      'teamAOTTimeouts': teamAOTTimeouts,
      'teamBTimeouts1': teamBTimeouts1,
      'teamBTimeouts2': teamBTimeouts2,
      'teamBOTTimeouts': teamBOTTimeouts,
      'forfeitStatus': forfeitStatus,
      'observaciones': observaciones,
    };
  }

  factory MatchState.fromJson(Map<String, dynamic> json) {
    return MatchState(
      scoreA: json['scoreA'] ?? 0,
      scoreB: json['scoreB'] ?? 0,
      timeLeft: Duration(seconds: json['timeLeft'] ?? 0),
      isRunning: json['isRunning'] ?? false,
      currentPeriod: json['currentPeriod'] ?? 1,
      possession: json['possession'] ?? '',
      teamATimeouts1: List<String>.from(json['teamATimeouts1'] ?? []),
      teamATimeouts2: List<String>.from(json['teamATimeouts2'] ?? []),
      teamAOTTimeouts: List<String>.from(json['teamAOTTimeouts'] ?? []),
      teamBTimeouts1: List<String>.from(json['teamBTimeouts1'] ?? []),
      teamBTimeouts2: List<String>.from(json['teamBTimeouts2'] ?? []),
      teamBOTTimeouts: List<String>.from(json['teamBOTTimeouts'] ?? []),
      forfeitStatus: json['forfeitStatus'] ?? 'NONE',
      observaciones: json['observaciones'] ?? 'Sin novedad',
    );
  }
}

class MatchGameController extends StateNotifier<MatchState> {
  final MatchesDao _dao;
  Timer? _timer;
  final List<MatchState> _history = [];

  MatchGameController(this._dao) : super(const MatchState());

  int getTeamFouls(String teamId) {
    return state.scoreLog.where((e) {
      // Retorna true solo si:
      // 1. Es del equipo actual y del periodo actual.
      // 2. Tiene 0 puntos (es una falta).
      // 3. NO es un cambio (SUB). <--- ESTA ES LA CORRECCIÓN
      // 4. NO es una falta de Coach (C) ni de Banca (B) según tus reglas previas.
      return e.teamId == teamId &&
          e.period == state.currentPeriod &&
          e.points == 0 &&
          e.type != 'SUB' && // <--- IGNORAR CAMBIOS
          !e.type.startsWith('C') &&
          !e.type.startsWith('B');
    }).length;
  }

Future<void> restoreFromDatabase({
  required String matchId,
  String? fixtureId,
  required List<models.Player> rosterA,
  required List<models.Player> rosterB,
  required Set<int> startersA, // <--- Estos son los que el usuario eligió originalmente
  required Set<int> startersB,
  required int tournamentId,
  required int venueId,
  required int teamAId,
  required int teamBId,
  required String mainReferee,
  required String auxReferee,
  required String scorekeeper,
}) async {
  
  // 1. Inicializar usando los starters que vienen del widget (los que elegiste en la pantalla de selección)
  // Si startersA viene vacío desde el calendario, entonces el problema está en el paso de datos del FixtureList.
  initializeNewMatch(
    matchId: matchId,
    fixtureId: fixtureId,
    rosterA: rosterA,
    rosterB: rosterB,
    startersA: startersA, 
    startersB: startersB,
    tournamentId: tournamentId,
    venueId: venueId,
    teamAId: teamAId,
    teamBId: teamBId,
    mainReferee: mainReferee,
    auxReferee: auxReferee,
    scorekeeper: scorekeeper,
  );

  // 2. RECUPERAR CAPITANES Y MARCAR "HAS PLAYED"
  final dbRosters = await (_dao.db.select(_dao.db.matchRosters)
        ..where((tbl) => tbl.matchId.equals(matchId))).get();

  Map<String, PlayerStats> statsWithCaptains = Map.from(state.playerStats);
  for (var row in dbRosters) {
    if (row.isCaptain) {
      statsWithCaptains.forEach((name, pStat) {
        if (pStat.dbId.toString() == row.playerId) {
          statsWithCaptains[name] = pStat.copyWith(hasPlayed: true);
        }
      });
    }
  }
  state = state.copyWith(playerStats: statsWithCaptains);

  // 3. PROCESAR EVENTOS (Aquí es donde los jugadores "suben" a cancha si hubo cambios o puntos)
  final events = await (_dao.db.select(_dao.db.gameEvents)
        ..where((tbl) => tbl.matchId.equals(matchId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
      .get();

  // 4. Procesar eventos acumulativamente
  for (var event in events) {
    String teamId = 'A';
    String? pName;
    String pNumber = "00";
    int dbId = 0;

    if (event.playerId != null && event.playerId != "-1") {
      final pA = rosterA.where((p) => p.id.toString() == event.playerId).firstOrNull;
      final pB = rosterB.where((p) => p.id.toString() == event.playerId).firstOrNull;
      if (pB != null) { teamId = 'B'; pName = pB.name; pNumber = pB.defaultNumber.toString(); dbId = pB.id; }
      else if (pA != null) { pName = pA.name; pNumber = pA.defaultNumber.toString(); dbId = pA.id; }
    } else if (event.type.endsWith('_B')) { 
      teamId = 'B'; 
    }

    int pts = 0;
    if (event.type == 'POINT_1') pts = 1;
    else if (event.type == 'POINT_2') pts = 2;
    else if (event.type == 'POINT_3') pts = 3;

    int fls = (pts == 0 && (event.type.contains('FOUL') || event.type.length <= 2) && !event.type.contains('TIMEOUT')) ? 1 : 0;

    _applyRestoreEvent(
      teamId: teamId,
      playerName: pName ?? (event.type.contains('TIMEOUT') ? "TIMEOUT" : "OTROS"),
      points: pts,
      fouls: fls,
      type: event.type,
      period: event.period,
      pNumber: pNumber,
      dbPlayerId: dbId,
      clockTime: event.clockTime,
    );
  }
}

// Método auxiliar necesario para el restore (sin llaves según tu estilo previo, 
// pero agregadas donde el linter lo exigía)
void _applyRestoreEvent({
  required String teamId,
  required String playerName,
  required int points,
  required int fouls,
  required String type,
  required int period,
  required String pNumber,
  required int dbPlayerId,
  String clockTime = "0:00",
}) {
  final currentStats = state.playerStats[playerName] ?? const PlayerStats();
  final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);

  List<String> newFoulDetails = List.from(currentStats.foulDetails);
  if (fouls > 0) {
    newFoulDetails.add(type);
  }

  newPlayerStatsMap[playerName] = currentStats.copyWith(
    points: currentStats.points + points,
    fouls: currentStats.fouls + fouls,
    foulDetails: newFoulDetails,
    hasPlayed: true,
  );

  int newScoreA = state.scoreA + (teamId == 'A' ? points : 0);
  int newScoreB = state.scoreB + (teamId == 'B' ? points : 0);

  final newScoreLog = List<ScoreEvent>.from(state.scoreLog);
  newScoreLog.add(ScoreEvent(
    period: period, teamId: teamId, playerId: playerName, dbPlayerId: dbPlayerId,
    playerNumber: pNumber, points: points, scoreAfter: teamId == 'A' ? newScoreA : newScoreB, type: type,
  ));

  final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
  if (!newPeriodScores.containsKey(period)) {
    newPeriodScores[period] = [0, 0];
  }
  newPeriodScores[period]![teamId == 'A' ? 0 : 1] += points;

  state = state.copyWith(
    playerStats: newPlayerStatsMap,
    scoreA: newScoreA,
    scoreB: newScoreB,
    scoreLog: newScoreLog,
    periodScores: newPeriodScores,
    currentPeriod: period,
  );
}

  void setObservaciones(String text) {
    state = state.copyWith(observaciones: text);
    _saveToDatabase();
  }

  Future<bool> finalizeAndSync(
    ApiService api,
    Uint8List? signatureBytes,
    Uint8List? pdfBytes,
    String teamAName,
    String teamBName,
  ) async {
    String? signatureBase64;
    if (signatureBytes != null) {
      signatureBase64 = base64Encode(signatureBytes);
      await _dao.saveSignature(state.matchId, signatureBase64);
    }

    // RECUPERAR FIRMAS DE OFICIALES ---
    final database = _dao.db;
    final mainRefObj = await (database.select(database.officials)
      ..where((t) => t.name.equals(state.mainReferee))
      ..where((t) => t.role.equals('ARBITRO_PRINCIPAL')))
      .get().then((list) => list.firstOrNull);

    final auxRefObj = await (database.select(database.officials)
      ..where((t) => t.name.equals(state.auxReferee))
      ..where((t) => t.role.equals('ARBITRO_AUXILIAR')))
      .get().then((list) => list.firstOrNull);

    // ignore: unused_local_variable
    Uint8List? mainRefSignature;
    // ignore: unused_local_variable
    Uint8List? auxRefSignature;

    if (mainRefObj?.signatureData != null) {
      mainRefSignature = base64Decode(mainRefObj!.signatureData!);
    }
    if (auxRefObj?.signatureData != null) {
      auxRefSignature = base64Decode(auxRefObj!.signatureData!);
    }
    // --------------------------------------------

    String? localPdfPath;
    if (pdfBytes != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/match_${state.matchId}.pdf');
        await file.writeAsBytes(pdfBytes);
        localPdfPath = file.path;

        await (_dao.update(
          _dao.db.matches,
        )..where((tbl) => tbl.id.equals(state.matchId))).write(
          MatchesCompanion(matchReportPath: drift.Value(localPdfPath)),
        );
      } catch (e) {
        // Silencio en release
      }
    }

    final eventsList = state.scoreLog.map((e) {
      final currentStats = state.playerStats[e.playerId];
      final updatedNumber = currentStats?.playerNumber ?? e.playerNumber;
      String? parsedPlayerId = (e.dbPlayerId == 0 || e.dbPlayerId == -1)
          ? null
          : e.dbPlayerId.toString();

      // OBTENEMOS EL NOMBRE REAL DEL JUGADOR
      // Si currentStats existe, usamos su playerName (ej. "ABRAHAM CHVEZ")
      // Si no existe (caso raro), caemos al e.playerId original.
      final realPlayerName = currentStats != null && currentStats.playerName.isNotEmpty 
          ? currentStats.playerName 
          : e.playerId;

      return {
        "period": e.period,
        "team_side": e.teamId,
        "player_name": realPlayerName,
        "player_id": parsedPlayerId,
        "player_number": updatedNumber,
        "points_scored": e.points,
        "score_after": e.scoreAfter,
        "type": e.type,
      };
    }).toList();

    final rosterRows = await (_dao.db.select(
      _dao.db.matchRosters,
    )..where((r) => r.matchId.equals(state.matchId))).get();

    final rostersList = rosterRows.map((r) {
      final pStats = state.playerStats.values
          .where((p) => p.dbId.toString() == r.playerId)
          .firstOrNull;

      bool hasPlayed = false;
      if (pStats != null) {
        if (pStats.isStarter ||
            pStats.isOnCourt ||
            pStats.points > 0 ||
            pStats.fouls > 0) {
          hasPlayed = true;
        }
      }

      return {
        "player_id": int.tryParse(r.playerId) ?? 0,
        "team_side": r.teamSide,
        "jersey_number": r.jerseyNumber,
        "is_captain": r.isCaptain ? 1 : 0,
        "played": hasPlayed ? 1 : 0,
      };
    }).toList();

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final payload = {
      "match_id": state.matchId,
      "fixture_id": state.fixtureId,
      "tournament_id": state.tournamentId,
      "venue_id": state.venueId,
      "team_a_id": state.teamAId,
      "team_b_id": state.teamBId,
      "team_a_name": teamAName,
      "team_b_name": teamBName,
      "score_a": state.scoreA,
      "score_b": state.scoreB,
      "current_period": state.currentPeriod,
      "time_left":
          "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
      "main_referee": state.mainReferee,
      "aux_referee": state.auxReferee,
      "scorekeeper": state.scorekeeper,
      "forfeit_status": state.forfeitStatus,
      "observaciones": state.observaciones,
      "match_date": formattedDate,
      "signature_base64": signatureBase64,
      "events": eventsList,
      "rosters": rostersList,
    };

    try {
      final success = await api.syncMatchDataMultipart(
        matchData: payload,
        pdfBytes: pdfBytes,
      );
      if (success) {
        await _dao.markAsSynced(state.matchId);
        if (localPdfPath != null) File(localPdfPath).delete();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // función para el Default
  void declareForfeit(String defaultingTeam) {
    // defaultingTeam puede ser 'A', 'B' o 'BOTH'
    int newScoreA = 0;
    int newScoreB = 0;

    if (defaultingTeam == 'A') {
      newScoreB = 20; // Pierde A por default 0-20
    } else if (defaultingTeam == 'B') {
      newScoreA = 20; // Pierde B por default 20-0
    }

    state = state.copyWith(
      scoreA: newScoreA,
      scoreB: newScoreB,
      forfeitStatus: defaultingTeam == 'A'
          ? 'TEAM_A'
          : (defaultingTeam == 'B' ? 'TEAM_B' : 'BOTH'),
      timeLeft: const Duration(seconds: 0),
    );

    _pause();
    _saveToDatabase();
  }

  void addTimeout(String teamId) {
    _saveToHistory();

    int minutesLeft = (state.timeLeft.inSeconds / 60).floor();
    if (state.timeLeft.inSeconds % 60 > 0 && minutesLeft == 10) minutesLeft = 9;
    if (minutesLeft == 0 && state.timeLeft.inSeconds > 0) {
      minutesLeft = 1;
    } else if (state.timeLeft.inSeconds == 0) {
      minutesLeft = 0;
    }

    String minStr = minutesLeft.toString();
    bool isClutchTime =
        state.currentPeriod == 4 && state.timeLeft.inSeconds <= 120;

    _processTimeoutWithRules(teamId, minStr, state.currentPeriod, isClutchTime);
    _logEventToDb(null, 0, 0, 'TIMEOUT_$teamId');
  }

  void addTeamFoul(String teamId, String type) {
    _saveToHistory();
    String specialName = type == 'C' ? "Entrenador" : "Banca";

    List<ScoreEvent> newScoreLog = List.from(state.scoreLog);
    newScoreLog.add(
      ScoreEvent(
        period: state.currentPeriod,
        teamId: teamId,
        playerId: specialName,
        dbPlayerId: 0,
        playerNumber: "",
        points: 0,
        scoreAfter: (teamId == 'A' ? state.scoreA : state.scoreB),
        type: type,
      ),
    );

    state = state.copyWith(scoreLog: newScoreLog);
    _saveToDatabase();
    _logEventToDb(null, 0, 1, '${type}_$teamId');
  }

  void _processTimeoutWithRules(
    String teamId,
    String minStr,
    int period,
    bool isClutchTime,
  ) {
    List<String> currentList;

    if (period <= 2) {
      currentList = List.from(
        teamId == 'A' ? state.teamATimeouts1 : state.teamBTimeouts1,
      );
      if (currentList.length < 2) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 1, currentList);
      }
    } else if (period == 3 || period == 4) {
      currentList = List.from(
        teamId == 'A' ? state.teamATimeouts2 : state.teamBTimeouts2,
      );
      if (isClutchTime && currentList.isEmpty) currentList.add("X");

      if (currentList.length < 3) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 2, currentList);
      }
    } else {
      currentList = List.from(
        teamId == 'A' ? state.teamAOTTimeouts : state.teamBOTTimeouts,
      );
      int currentOtCount = period - 4;
      if (currentList.length < currentOtCount && currentList.length < 3) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 3, currentList);
      }
    }
  }

  void _updateTimeoutList(String teamId, int section, List<String> newList) {
    if (teamId == 'A') {
      if (section == 1) {
        state = state.copyWith(teamATimeouts1: newList);
      } else if (section == 2) {
        state = state.copyWith(teamATimeouts2: newList);
      } else {
        state = state.copyWith(teamAOTTimeouts: newList);
      }
    } else {
      if (section == 1) {
        state = state.copyWith(teamBTimeouts1: newList);
      } else if (section == 2) {
        state = state.copyWith(teamBTimeouts2: newList);
      } else {
        state = state.copyWith(teamBOTTimeouts: newList);
      }
    }
    _saveToDatabase();
  }

  void _start() {
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft.inSeconds > 0) {
        final newTime = state.timeLeft - const Duration(seconds: 1);
        bool triggerAutoBurn =
            state.currentPeriod == 4 && newTime.inSeconds == 120;

        state = state.copyWith(timeLeft: newTime);
        if (triggerAutoBurn) _applyAutoBurn();
      } else {
        _pause();
      }
    });
  }

  void _applyAutoBurn() {
    bool changed = false;
    List<String> listA = List.from(state.teamATimeouts2);
    List<String> listB = List.from(state.teamBTimeouts2);

    if (listA.isEmpty) {
      listA.add("X");
      changed = true;
    }
    if (listB.isEmpty) {
      listB.add("X");
      changed = true;
    }

    if (changed) {
      _saveToHistory();
      state = state.copyWith(teamATimeouts2: listA, teamBTimeouts2: listB);
      _saveToDatabase();
    }
  }

  void initializeNewMatch({
    required String matchId,
    String? fixtureId,
    required List<models.Player> rosterA,
    required List<models.Player> rosterB,
    required Set<int> startersA,
    required Set<int> startersB,
    required int tournamentId,
    required int venueId,
    required int teamAId,
    required int teamBId,
    required String mainReferee,
    required String auxReferee,
    required String scorekeeper,
  }) {
    _timer?.cancel();
    _timer = null;
    _dao.updateMatchMetadata(
      matchId,
      fixtureId,
      teamAId,
      teamBId,
      mainReferee,
      auxReferee,
      scorekeeper,
    );
    final Map<String, PlayerStats> initialStats = {};
    final List<String> courtA = [];
    final List<String> benchA = [];
    final List<String> courtB = [];
    final List<String> benchB = [];

    // Para equipo A
    for (var player in rosterA) {
      final isStarter = startersA.contains(player.id);
      // USAMOS player.id.toString() como LLAVE en lugar de player.name
      initialStats[player.id.toString()] = PlayerStats(
        dbId: player.id,
        playerName: player.name,
        isOnCourt: isStarter,
        isStarter: isStarter,
        hasPlayed: isStarter,
        playerNumber: player.defaultNumber.toString(),
      );
      if (isStarter) {
        courtA.add(player.id.toString()); // Guardamos ID, no nombre
      } else {
        benchA.add(player.id.toString());
      }
    }

    for (var player in rosterB) {
      final isStarter = startersB.contains(player.id);
      initialStats[player.id.toString()] = PlayerStats(
        dbId: player.id,
        playerName: player.name,
        isOnCourt: isStarter,
        isStarter: isStarter,
        hasPlayed: isStarter,
        playerNumber: player.defaultNumber.toString(),
      );
      if (isStarter) {
        courtB.add(player.id.toString());
      } else {
        benchB.add(player.id.toString());
      }
    }

    state = state.copyWith(
      matchId: matchId,
      fixtureId: fixtureId,
      playerStats: initialStats,
      teamAOnCourt: courtA,
      teamABench: benchA,
      teamBOnCourt: courtB,
      teamBBench: benchB,
      scoreA: 0,
      scoreB: 0,
      currentPeriod: 1,
      possession: '',
      timeLeft: const Duration(minutes: 10),
      scoreLog: [],
      periodScores: {
        1: [0, 0],
      },
      tournamentId: tournamentId,
      venueId: venueId,
      teamAId: teamAId,
      teamBId: teamBId,
      mainReferee: mainReferee,
      auxReferee: auxReferee,
      scorekeeper: scorekeeper,
      teamATimeouts1: [],
      teamATimeouts2: [],
      teamAOTTimeouts: [],
      teamBTimeouts1: [],
      teamBTimeouts2: [],
      teamBOTTimeouts: [],
      forfeitStatus: 'NONE',         
      observaciones: 'Sin novedad',
    );
  }

  void setPossession(String team) {
    _saveToHistory();
    if (state.possession == team) {
      state = state.copyWith(possession: '');
    } else {
      state = state.copyWith(possession: team);
    }
  }

  void initMatch(String matchId) {}

  void _saveToHistory() {
    if (_history.length > 50) _history.removeAt(0);
    _history.add(state);
  }

  void undo() {
    if (_history.isNotEmpty) {
      final previousState = _history.removeLast();
      state = previousState.copyWith(
        timeLeft: state.timeLeft,
        isRunning: state.isRunning,
      );
      _saveToDatabase();
    }
  }

  void setTime(Duration newTime) {
    state = state.copyWith(timeLeft: newTime);
  }

  void adjustTime(int seconds) {
    final newSeconds = state.timeLeft.inSeconds + seconds;
    if (newSeconds < 0) return;
    state = state.copyWith(timeLeft: Duration(seconds: newSeconds));
  }

  void nextPeriod() {
    _saveToHistory();
    int nextPeriodIdx = state.currentPeriod + 1;
    Duration newDuration = (nextPeriodIdx > 4)
        ? const Duration(minutes: 5)
        : const Duration(minutes: 10);

    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    if (!newPeriodScores.containsKey(nextPeriodIdx)) {
      newPeriodScores[nextPeriodIdx] = [0, 0];
    }

    state = state.copyWith(
      currentPeriod: nextPeriodIdx,
      timeLeft: newDuration,
      isRunning: false,
      periodScores: newPeriodScores,
    );
    _saveToDatabase();
  }

  void setPeriod(int period) {
    _saveToHistory();
    Duration newDuration = (period > 4)
        ? const Duration(minutes: 5)
        : const Duration(minutes: 10);

    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    if (!newPeriodScores.containsKey(period)) newPeriodScores[period] = [0, 0];

    state = state.copyWith(
      currentPeriod: period,
      timeLeft: newDuration,
      isRunning: false,
      periodScores: newPeriodScores,
    );
    _saveToDatabase();
  }

  void toggleTimer() {
    if (state.isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
    _saveToDatabase();
  }

  void updateStats(
  String teamId,
  String playerId, {
  int points = 0,
  int fouls = 0,
  String? foulType,
}) {
  // 1. Obtener las estadísticas actuales del jugador usando su ID único
  final currentStats = state.playerStats[playerId];
  if (currentStats == null) return;

  // 2. VALIDACIÓN DE PERTENENCIA: 
  // Verificamos que el jugador pertenezca al equipo solicitado, ya sea que esté en cancha o en banca.
  final bool isLocal = state.teamAOnCourt.contains(playerId) || state.teamABench.contains(playerId);
  final bool isVisit = state.teamBOnCourt.contains(playerId) || state.teamBBench.contains(playerId);

  if (teamId == 'A' && !isLocal) return;
  if (teamId == 'B' && !isVisit) return;

  // 3. REGLA DE DESCALIFICACIÓN:
  // Si el jugador ya tiene 5 o más faltas, no permitimos sumar más puntos o faltas.
  if (currentStats.fouls >= 5 && (points > 0 || fouls > 0)) return;

  // Guardamos el estado actual en el historial para permitir "Undo"
  _saveToHistory();

  // 4. CÁLCULO DE NUEVOS MARCADORES GLOBALES
  int newScoreA = state.scoreA + (teamId == 'A' ? points : 0);
  int newScoreB = state.scoreB + (teamId == 'B' ? points : 0);

  // Determinar el puntaje acumulado del equipo correspondiente después de esta acción
  int scoreAfter = (teamId == 'A' ? newScoreA : newScoreB);

  // 5. ACTUALIZACIÓN DE PUNTUACIÓN POR PERIODO
  final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
  List<int> currentPeriodScore = List.from(newPeriodScores[state.currentPeriod] ?? [0, 0]);
  
  if (points > 0) {
    if (teamId == 'A') {
      currentPeriodScore[0] += points;
    } else {
      currentPeriodScore[1] += points;
    }
  }
  newPeriodScores[state.currentPeriod] = currentPeriodScore;

  // 6. ACTUALIZACIÓN DE ESTADÍSTICAS DEL JUGADOR (Cancha o Banca)
  List<String> newFoulDetails = List.from(currentStats.foulDetails);
  if (fouls > 0) {
    newFoulDetails.add(foulType ?? "P");
  }

  final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
  newPlayerStatsMap[playerId] = currentStats.copyWith(
    points: currentStats.points + points,
    fouls: currentStats.fouls + fouls,
    foulDetails: newFoulDetails,
    hasPlayed: true, // Si se le registra una acción, se marca que participó en el juego
  );

  // 7. REGISTRO EN EL LOG DE EVENTOS (Indispensable para el Acta PDF y el Undo selectivo)
  final newScoreLog = List<ScoreEvent>.from(state.scoreLog);
  if (points > 0 || fouls > 0) {
    String dorsal = currentStats.playerNumber;
    String eventType = "UNKNOWN";
    
    if (points > 0) eventType = "POINT_$points"; // O simplemente "POINT"
    if (fouls > 0) eventType = foulType ?? "FOUL";

    newScoreLog.add(
      ScoreEvent(
        period: state.currentPeriod,
        teamId: teamId,
        playerId: playerId,
        dbPlayerId: currentStats.dbId,
        playerNumber: dorsal,
        points: points,
        scoreAfter: scoreAfter,
        type: eventType,
      ),
    );
  }

  // 8. EMISIÓN DEL NUEVO ESTADO
  state = state.copyWith(
    scoreA: newScoreA,
    scoreB: newScoreB,
    periodScores: newPeriodScores,
    playerStats: newPlayerStatsMap,
    scoreLog: newScoreLog,
  );

  // Persistencia y logs externos
  _saveToDatabase();
  _logEventToDb(currentStats.dbId.toString(), points, fouls, foulType);
}

  void substitutePlayer(String teamId, String playerOutId, String playerInId) {
    _saveToHistory();
    final newStats = Map<String, PlayerStats>.from(state.playerStats);

    if (newStats.containsKey(playerOutId)) {
      newStats[playerOutId] = newStats[playerOutId]!.copyWith(isOnCourt: false);
    }

    if (newStats.containsKey(playerInId)) {
      newStats[playerInId] = newStats[playerInId]!.copyWith(
        isOnCourt: true,
        hasPlayed: true,
      );
    }

    if (teamId == 'A') {
      final newOnCourt = List<String>.from(state.teamAOnCourt)
        ..remove(playerOutId)
        ..add(playerInId);
      final newBench = List<String>.from(state.teamABench)
        ..remove(playerInId)
        ..add(playerOutId);
      state = state.copyWith(
        teamAOnCourt: newOnCourt,
        teamABench: newBench,
        playerStats: newStats,
      );
    } else {
      final newOnCourt = List<String>.from(state.teamBOnCourt)
        ..remove(playerOutId)
        ..add(playerInId);
      final newBench = List<String>.from(state.teamBBench)
        ..remove(playerInId)
        ..add(playerOutId);
      state = state.copyWith(
        teamBOnCourt: newOnCourt,
        teamBBench: newBench,
        playerStats: newStats,
      );
    }
    _saveToDatabase();


    // Registramos un evento especial en el ScoreLog para poder deshacerlo selectivamente
  final newScoreLog = List<ScoreEvent>.from(state.scoreLog);
  newScoreLog.add(ScoreEvent(
    period: state.currentPeriod,
    teamId: teamId,
    playerId: playerOutId, // Quién salió
    playerNumber: playerInId, // Quién entró (usamos este campo para guardar el ID del entrante)
    points: 0,
    scoreAfter: 0,
    type: 'SUB', // Tipo especial
  ));

    state = state.copyWith(scoreLog: newScoreLog); 
    _logEventToDb(null, 0, 0, 'SUB_${teamId}_OUT_${playerOutId}_IN_$playerInId');
  }

  // --- LÓGICA DE UNDO SELECTIVO ---


// Añade el undo de Tiempo Fuera (Opcional pero recomendado)
void undoLastTimeout() {
  // 1. Buscar el último tiempo fuera en el log
  final lastTO = state.scoreLog.where((e) => e.type.contains('TIMEOUT')).lastOrNull;
  if (lastTO == null) return;
  
  _saveToHistory();

  // 2. Identificar qué lista de la memoria RAM debemos limpiar
  List<String> to1A = List.from(state.teamATimeouts1);
  List<String> to2A = List.from(state.teamATimeouts2);
  List<String> toOTA = List.from(state.teamAOTTimeouts);
  
  List<String> to1B = List.from(state.teamBTimeouts1);
  List<String> to2B = List.from(state.teamBTimeouts2);
  List<String> toOTB = List.from(state.teamBOTTimeouts);

  if (lastTO.teamId == 'A') {
    if (lastTO.period <= 2) {
      if (to1A.isNotEmpty) to1A.removeLast();
    } else if (lastTO.period <= 4) {
      if (to2A.isNotEmpty) to2A.removeLast();
    } else {
      if (toOTA.isNotEmpty) toOTA.removeLast();
    }
  } else {
    if (lastTO.period <= 2) {
      if (to1B.isNotEmpty) to1B.removeLast();
    } else if (lastTO.period <= 4) {
      if (to2B.isNotEmpty) to2B.removeLast();
    } else {
      if (toOTB.isNotEmpty) toOTB.removeLast();
    }
  }

  // 3. Actualizar el estado: Limpiar la lista del equipo y remover del log
  state = state.copyWith(
    teamATimeouts1: to1A,
    teamATimeouts2: to2A,
    teamAOTTimeouts: toOTA,
    teamBTimeouts1: to1B,
    teamBTimeouts2: to2B,
    teamBOTTimeouts: toOTB,
    scoreLog: state.scoreLog.where((e) => e != lastTO).toList(),
  );

  _saveToDatabase();
}

void undoLastPoint() {
  final lastPoint = state.scoreLog.where((e) => e.points > 0).lastOrNull;
  if (lastPoint == null) return;
  _saveToHistory();

  final currentStats = state.playerStats[lastPoint.playerId]!;
  
  // 1. Revertir puntos del jugador
  final newStats = currentStats.copyWith(
    points: currentStats.points - lastPoint.points,
  );

  // 2. Revertir marcador global y de periodo
  final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
  newPeriodScores[lastPoint.period]![lastPoint.teamId == 'A' ? 0 : 1] -= lastPoint.points;

  state = state.copyWith(
    scoreA: lastPoint.teamId == 'A' ? state.scoreA - lastPoint.points : state.scoreA,
    scoreB: lastPoint.teamId == 'B' ? state.scoreB - lastPoint.points : state.scoreB,
    playerStats: {...state.playerStats, lastPoint.playerId: newStats},
    scoreLog: state.scoreLog.where((e) => e != lastPoint).toList(), // Eliminar del log
    periodScores: newPeriodScores,
  );
  _saveToDatabase();
}

void undoLastFoul() {
  final lastFoul = state.scoreLog.where((e) => e.type.contains("FOUL") || e.type.length <= 2).lastOrNull;
  if (lastFoul == null) return;
  _saveToHistory();

  final currentStats = state.playerStats[lastFoul.playerId]!;
  List<String> newFoulDetails = List.from(currentStats.foulDetails)..remove(lastFoul.type);

  state = state.copyWith(
    playerStats: {
      ...state.playerStats,
      lastFoul.playerId: currentStats.copyWith(
        fouls: currentStats.fouls - 1,
        foulDetails: newFoulDetails,
      )
    },
    scoreLog: state.scoreLog.where((e) => e != lastFoul).toList(),
  );
  _saveToDatabase();
}

void undoLastSubstitution() {
  final lastSub = state.scoreLog.where((e) => e.type == 'SUB').lastOrNull;
  if (lastSub == null) return;

  // El truco aquí es simplemente llamar a substitutePlayer pero al revés
  // lastSub.playerId es el que salió, lastSub.playerNumber es el que entró
  substitutePlayer(lastSub.teamId, lastSub.playerNumber, lastSub.playerId);
  
  // Limpiamos los dos eventos de sustitución (el original y el de reversión) del log
  // para que no ensucien el acta PDF final
  state = state.copyWith(
    scoreLog: state.scoreLog.where((e) => e.type != 'SUB').toList()
  );
}

  Future<void> _saveToDatabase() async {
    if (state.matchId.isEmpty) return;
    final timeStr =
        "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";
    await _dao.updateMatchStatus(
      state.matchId,
      state.scoreA,
      state.scoreB,
      timeStr,
      "IN_PROGRESS",
    );
  }

  Future<void> _logEventToDb(
    String? playeridDb,
    int points,
    int fouls,
    String? customType,
  ) async {
    if (state.matchId.isEmpty) return;
    String type = "UNKNOWN";
    if (points == 1) {
      type = "POINT_1";
    } else if (points == 2) {
      type = "POINT_2";
    } else if (points == 3) {
      type = "POINT_3";
    } else if (customType != null) {
      type = customType;
    } else if (fouls > 0) {
      type = "FOUL";
    }

    final timeStr =
        "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";

    await _dao.insertEvent(
      GameEventsCompanion.insert(
        matchId: state.matchId,
        playerId: drift.Value(playeridDb),
        type: type,
        period: state.currentPeriod,
        clockTime: timeStr,
        isSynced: const drift.Value(false),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateMatchPlayerInfo(String playerId, {String? newNumber}) {
    if (!state.playerStats.containsKey(playerId)) return;
    final currentStats = state.playerStats[playerId]!;
    final newStats = currentStats.copyWith(
      playerNumber: newNumber ?? currentStats.playerNumber,
    );
    final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStatsMap[playerId] = newStats;
    state = state.copyWith(playerStats: newPlayerStatsMap);
  }


  // =========================================================================
  // --- AÑADIR JUGADOR MID-GAME (ONLINE ONLY) ---
  // =========================================================================
  
  Future<void> addNewPlayerToMatch({
    required String teamSide, // 'A' o 'B'
    required String name,
    required int number,
    required ApiService api,
  }) async {
    // 1. Validar que tengamos el ID real del equipo en el estado actual
    final teamId = teamSide == 'A' ? state.teamAId : state.teamBId;
    if (teamId == null) {
      throw Exception("Error crítico: ID del equipo no encontrado en el partido.");
    }

    // 2. Validación DRY (Don't Repeat Yourself) local: 
    // Verificamos en memoria si el número ya está ocupado en este equipo para evitar viajes inútiles a la API.
    final isNumberTaken = state.playerStats.values.any((p) {
      final belongsToTeam = teamSide == 'A'
          ? (state.teamAOnCourt.contains(p.dbId.toString()) || state.teamABench.contains(p.dbId.toString()))
          : (state.teamBOnCourt.contains(p.dbId.toString()) || state.teamBBench.contains(p.dbId.toString()));
          
      return belongsToTeam && p.playerNumber == number.toString();
    });

    if (isNumberTaken) {
      throw Exception("El número $number ya está en uso en este equipo.");
    }

    // 3. Llamada de Red (Capa 2)
    // Si no hay internet o el backend lo rechaza, esto lanzará un Exception y cortará el flujo aquí.
    final newPlayerId = await api.addPlayer(teamId, name, number);
    final String playerKey = newPlayerId.toString();

    // 4. Persistencia Local (Capa 3)
    // Guardamos en SQLite para que el jugador siga ahí si se cierra la app.
    await _dao.saveMidGamePlayerLocally(
      matchId: state.matchId,
      playerId: newPlayerId,
      teamId: teamId,
      name: name,
      number: number,
      teamSide: teamSide,
    );

    // 5. Actualización del Estado Reactivo (RAM)
    // Creamos las estadísticas iniciales (0 puntos, 0 faltas)
    final freshStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    freshStatsMap[playerKey] = PlayerStats(
      dbId: newPlayerId,
      playerName: name,
      playerNumber: number.toString(),
      isOnCourt: false,
      isStarter: false,
      hasPlayed: false,
    );

    // Agregamos el ID a la lista de la banca correspondiente
    List<String> freshBenchA = List.from(state.teamABench);
    List<String> freshBenchB = List.from(state.teamBBench);

    if (teamSide == 'A') {
      freshBenchA.add(playerKey);
    } else {
      freshBenchB.add(playerKey);
    }

    // 6. Emisión de Estado
    // Esto disparará la reconstrucción en la UI mágicamente
    state = state.copyWith(
      playerStats: freshStatsMap,
      teamABench: freshBenchA,
      teamBBench: freshBenchB,
    );

    // 7. Actualizamos el timestamp del partido
    _saveToDatabase();
  }

}



final matchGameProvider =
    StateNotifierProvider<MatchGameController, MatchState>((ref) {
      final dao = ref.watch(matchesDaoProvider);
      return MatchGameController(dao);
    });
