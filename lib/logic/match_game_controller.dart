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
  final int points;
  final int fouls;
  final bool isOnCourt;
  final bool isStarter;
  final String playerNumber; 
  final List<String> foulDetails;

  const PlayerStats({
    this.dbId = 0,
    this.points = 0,
    this.fouls = 0,
    this.isOnCourt = false,
    this.isStarter = false,
    this.playerNumber = "00", 
    this.foulDetails = const [],
  });

  PlayerStats copyWith({
    int? dbId,
    int? points,
    int? fouls,
    bool? isOnCourt,
    bool? isStarter,
    String? playerNumber,
    List<String>? foulDetails,
  }) {
    return PlayerStats(
      dbId: dbId ?? this.dbId,
      points: points ?? this.points,
      fouls: fouls ?? this.fouls,
      isOnCourt: isOnCourt ?? this.isOnCourt,
      isStarter: isStarter ?? this.isStarter,
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
    this.periodScores = const { 1: [0, 0] },
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
      return e.teamId == teamId && 
             e.period == state.currentPeriod && 
             e.points == 0;
    }).length;
  }

  Future<bool> finalizeAndSync(
    ApiService api, 
    Uint8List? signatureBytes, 
    Uint8List? pdfBytes,
    String teamAName, 
    String teamBName
  ) async {
    
    String? signatureBase64;
    if (signatureBytes != null) {
      signatureBase64 = base64Encode(signatureBytes);
      await _dao.saveSignature(state.matchId, signatureBase64);
    }

    String? localPdfPath;
    if (pdfBytes != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/match_${state.matchId}.pdf');
        await file.writeAsBytes(pdfBytes);
        localPdfPath = file.path;
        
        await (_dao.update(_dao.db.matches)..where((tbl) => tbl.id.equals(state.matchId)))
            .write(MatchesCompanion(matchReportPath: drift.Value(localPdfPath)));
      } catch (e) {
        // Silencio en release
      }
    }

    final eventsList = state.scoreLog.map((e) {
      final currentStats = state.playerStats[e.playerId]; 
      final updatedNumber = currentStats?.playerNumber ?? e.playerNumber;
      String? parsedPlayerId = (e.dbPlayerId == 0 || e.dbPlayerId == -1) ? null : e.dbPlayerId.toString();

      return {
        "period": e.period,
        "team_side": e.teamId, 
        "player_name": e.playerId, 
        "player_id": parsedPlayerId,
        "player_number": updatedNumber, 
        "points_scored": e.points, 
        "score_after": e.scoreAfter, 
        "type": e.type, 
      };
    }).toList();

    // 1. Buscamos los rosters en la DB local usando _dao.db y el state
    final rosterRows = await (_dao.db.select(_dao.db.matchRosters)
          ..where((r) => r.matchId.equals(state.matchId)))
        .get();

    // 2. Mapeamos esos datos a una lista de JSON, agregando la lógica de "played"
    final rostersList = rosterRows.map((r) {
      // Buscar las estadísticas de este jugador en el state usando su ID de DB
      final pStats = state.playerStats.values.where((p) => p.dbId.toString() == r.playerId).firstOrNull;
      
      // Consideramos que jugó si fue titular, si está en cancha ahora, o si tiene puntos/faltas.
      bool hasPlayed = false;
      if (pStats != null) {
        if (pStats.isStarter || pStats.isOnCourt || pStats.points > 0 || pStats.fouls > 0) {
          hasPlayed = true;
        }
      }

      return {
        "player_id": int.tryParse(r.playerId) ?? 0,
        "team_side": r.teamSide,
        "jersey_number": r.jerseyNumber,
        "is_captain": r.isCaptain ? 1 : 0,
        "played": hasPlayed ? 1 : 0 // <--- NUEVO CAMPO
      };
    }).toList();

    final now = DateTime.now();
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      
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
      "time_left": "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
      "main_referee": state.mainReferee,
      "aux_referee": state.auxReferee,
      "scorekeeper": state.scorekeeper,
      "forfeit_status": state.forfeitStatus,
      "match_date": formattedDate, 
      "signature_base64": signatureBase64,
      "events": eventsList,
      "rosters": rostersList,
    };

    try {
        final success = await api.syncMatchDataMultipart(
          matchData: payload, 
          pdfBytes: pdfBytes
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
      forfeitStatus: defaultingTeam == 'A' ? 'TEAM_A' : (defaultingTeam == 'B' ? 'TEAM_B' : 'BOTH'),
      timeLeft: const Duration(seconds: 0),
    );
    
    _pause();
    _saveToDatabase();
  }

  void addTimeout(String teamId) {
    _saveToHistory();

    int minutesLeft = (state.timeLeft.inSeconds / 60).floor(); 
    if (state.timeLeft.inSeconds % 60 > 0 && minutesLeft == 10) minutesLeft = 9; 
    if (minutesLeft == 0 && state.timeLeft.inSeconds > 0) {minutesLeft = 1;}
    else if (state.timeLeft.inSeconds == 0) {minutesLeft = 0;} 

    String minStr = minutesLeft.toString();
    bool isClutchTime = state.currentPeriod == 4 && state.timeLeft.inSeconds <= 120;

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

  void _processTimeoutWithRules(String teamId, String minStr, int period, bool isClutchTime) {
    List<String> currentList;

    if (period <= 2) {
      currentList = List.from(teamId == 'A' ? state.teamATimeouts1 : state.teamBTimeouts1);
      if (currentList.length < 2) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 1, currentList);
      }
    } 
    else if (period == 3 || period == 4) {
      currentList = List.from(teamId == 'A' ? state.teamATimeouts2 : state.teamBTimeouts2);
      if (isClutchTime && currentList.isEmpty) currentList.add("X"); 

      if (currentList.length < 3) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 2, currentList);
      } 
    } 
    else {
       currentList = List.from(teamId == 'A' ? state.teamAOTTimeouts : state.teamBOTTimeouts);
       int currentOtCount = period - 4;
       if (currentList.length < currentOtCount && currentList.length < 3) { 
         currentList.add(minStr);
         _updateTimeoutList(teamId, 3, currentList); 
       }
    }
  }

  void _updateTimeoutList(String teamId, int section, List<String> newList) {
    if (teamId == 'A') {
      if (section == 1) {state = state.copyWith(teamATimeouts1: newList);}
      else if (section == 2) {state = state.copyWith(teamATimeouts2: newList);}
      else {state = state.copyWith(teamAOTTimeouts: newList);}
    } else {
      if (section == 1) {state = state.copyWith(teamBTimeouts1: newList);}
      else if (section == 2) {state = state.copyWith(teamBTimeouts2: newList);}
      else {state = state.copyWith(teamBOTTimeouts: newList);}
    }
    _saveToDatabase();
  }

  void _start() {
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft.inSeconds > 0) {
        final newTime = state.timeLeft - const Duration(seconds: 1);
        bool triggerAutoBurn = state.currentPeriod == 4 && newTime.inSeconds == 120;

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

    if (listA.isEmpty) { listA.add("X"); changed = true; }
    if (listB.isEmpty) { listB.add("X"); changed = true; }

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
    _dao.updateMatchMetadata(matchId, teamAId, teamBId, mainReferee, auxReferee, scorekeeper);
    final Map<String, PlayerStats> initialStats = {};
    final List<String> courtA = [];
    final List<String> benchA = [];
    final List<String> courtB = [];
    final List<String> benchB = [];

    for (var player in rosterA) {
      final isStarter = startersA.contains(player.id);
      initialStats[player.name] = PlayerStats(dbId: player.id, isOnCourt: isStarter, isStarter: isStarter, playerNumber: player.defaultNumber.toString());
      if (isStarter) { courtA.add(player.name); } else { benchA.add(player.name); }
    }

    for (var player in rosterB) {
      final isStarter = startersB.contains(player.id);
      initialStats[player.name] = PlayerStats(dbId: player.id, isOnCourt: isStarter, isStarter: isStarter, playerNumber: player.defaultNumber.toString());
      if (isStarter) { courtB.add(player.name); } else { benchB.add(player.name); }
    }

    state = state.copyWith(
      matchId: matchId, fixtureId: fixtureId, playerStats: initialStats,
      teamAOnCourt: courtA, teamABench: benchA, teamBOnCourt: courtB, teamBBench: benchB,
      scoreA: 0, scoreB: 0, currentPeriod: 1, possession: '', timeLeft: const Duration(minutes: 10),
      scoreLog: [], periodScores: { 1: [0, 0] }, tournamentId: tournamentId, venueId: venueId, teamAId: teamAId, teamBId: teamBId,
      mainReferee: mainReferee, auxReferee: auxReferee, scorekeeper: scorekeeper,
      teamATimeouts1: [], teamATimeouts2: [], teamAOTTimeouts: [], teamBTimeouts1: [], teamBTimeouts2: [], teamBOTTimeouts: [], 
    );
  }

  void setPossession(String team) {
    _saveToHistory();
    if (state.possession == team) {state = state.copyWith(possession: '');}
    else {state = state.copyWith(possession: team);}
  }

  void initMatch(String matchId) {}

  void _saveToHistory() {
    if (_history.length > 50) _history.removeAt(0);
    _history.add(state);
  }

  void undo() {
    if (_history.isNotEmpty) {
      final previousState = _history.removeLast();
      state = previousState.copyWith(timeLeft: state.timeLeft, isRunning: state.isRunning);
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
    Duration newDuration = (nextPeriodIdx > 4) ? const Duration(minutes: 5) : const Duration(minutes: 10);

    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    if (!newPeriodScores.containsKey(nextPeriodIdx)) newPeriodScores[nextPeriodIdx] = [0, 0];

    state = state.copyWith(currentPeriod: nextPeriodIdx, timeLeft: newDuration, isRunning: false, periodScores: newPeriodScores);
    _saveToDatabase();
  }

  void setPeriod(int period) {
    _saveToHistory();
    Duration newDuration = (period > 4) ? const Duration(minutes: 5) : const Duration(minutes: 10);

    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    if (!newPeriodScores.containsKey(period)) newPeriodScores[period] = [0, 0];

    state = state.copyWith(currentPeriod: period, timeLeft: newDuration, isRunning: false, periodScores: newPeriodScores);
    _saveToDatabase();
  }

  void toggleTimer() {
    if (state.isRunning) {_pause();}
    else {_start();}
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
    _saveToDatabase();
  }

  void updateStats(String teamId, String playerId, {int points = 0, int fouls = 0, String? foulType}) {
    final currentStats = state.playerStats[playerId] ?? const PlayerStats();
    if (currentStats.fouls >= 5 && (points > 0 || fouls > 0)) return;

    _saveToHistory();
    int newScoreA = state.scoreA;
    int newScoreB = state.scoreB;
    int scoreAfter = 0;

    if (points > 0) {
      if (teamId == 'A') { newScoreA += points; scoreAfter = newScoreA; } 
      else { newScoreB += points; scoreAfter = newScoreB; }
    }

    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    List<int> currentPeriodScore = List.from(newPeriodScores[state.currentPeriod] ?? [0, 0]);
    if (points > 0) {
      if (teamId == 'A') {currentPeriodScore[0] += points;}
      else {currentPeriodScore[1] += points;}
    }
    newPeriodScores[state.currentPeriod] = currentPeriodScore;

    List<String> newFoulDetails = List.from(currentStats.foulDetails);
    if (fouls > 0) newFoulDetails.add(foulType ?? "P");

    final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStatsMap[playerId] = currentStats.copyWith(points: currentStats.points + points, fouls: currentStats.fouls + fouls, foulDetails: newFoulDetails);

    List<ScoreEvent> newScoreLog = List.from(state.scoreLog);
    if (points > 0 || fouls > 0) {
      String dorsal = currentStats.playerNumber;
      String eventType = "UNKNOWN";
      if (fouls > 0) eventType = foulType ?? "FOUL";

      newScoreLog.add(ScoreEvent(period: state.currentPeriod, teamId: teamId, playerId: playerId, dbPlayerId: currentStats.dbId, playerNumber: dorsal, points: points, scoreAfter: scoreAfter, type: eventType));
    }

    state = state.copyWith(scoreA: newScoreA, scoreB: newScoreB, periodScores: newPeriodScores, playerStats: newPlayerStatsMap, scoreLog: newScoreLog);
    _saveToDatabase();
    _logEventToDb(currentStats.dbId.toString(), points, fouls, foulType);
  }

  void substitutePlayer(String teamId, String playerOut, String playerIn) {
    _saveToHistory();
    final newStats = Map<String, PlayerStats>.from(state.playerStats);
    if (newStats.containsKey(playerOut)) newStats[playerOut] = newStats[playerOut]!.copyWith(isOnCourt: false);
    if (newStats.containsKey(playerIn)) newStats[playerIn] = newStats[playerIn]!.copyWith(isOnCourt: true);

    if (teamId == 'A') {
      final newOnCourt = List<String>.from(state.teamAOnCourt)..remove(playerOut)..add(playerIn);
      final newBench = List<String>.from(state.teamABench)..remove(playerIn)..add(playerOut);
      state = state.copyWith(teamAOnCourt: newOnCourt, teamABench: newBench, playerStats: newStats);
    } else {
      final newOnCourt = List<String>.from(state.teamBOnCourt)..remove(playerOut)..add(playerIn);
      final newBench = List<String>.from(state.teamBBench)..remove(playerIn)..add(playerOut);
      state = state.copyWith(teamBOnCourt: newOnCourt, teamBBench: newBench, playerStats: newStats);
    }
  }

  Future<void> _saveToDatabase() async {
    if (state.matchId.isEmpty) return;
    final timeStr = "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";
    await _dao.updateMatchStatus(state.matchId, state.scoreA, state.scoreB, timeStr, "IN_PROGRESS");
  }

  Future<void> _logEventToDb(String? playeridDb, int points, int fouls, String? customType) async {
    if (state.matchId.isEmpty) return;
    String type = "UNKNOWN";
    if (points == 1) {type = "POINT_1";}
    else if (points == 2) {type = "POINT_2";}
    else if (points == 3) {type = "POINT_3";}
    else if (customType != null) {type = customType;} 
    else if (fouls > 0) {type = "FOUL"; }

    final timeStr = "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";

    await _dao.insertEvent(
      GameEventsCompanion.insert(
        matchId: state.matchId, playerId: drift.Value(playeridDb), type: type, period: state.currentPeriod, clockTime: timeStr, isSynced: const drift.Value(false),
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
    final newStats = currentStats.copyWith(playerNumber: newNumber ?? currentStats.playerNumber);
    final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStatsMap[playerId] = newStats;
    state = state.copyWith(playerStats: newPlayerStatsMap);
  }
}

final matchGameProvider = StateNotifierProvider<MatchGameController, MatchState>((ref) {
  final dao = ref.watch(matchesDaoProvider);
  return MatchGameController(dao);
});