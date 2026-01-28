import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/matches_dao.dart';
import '../core/di/dependency_injection.dart';

// --- MODELO DE DATOS INMUTABLE ---

class PlayerStats {
  final int points;
  final int fouls;
  const PlayerStats({this.points = 0, this.fouls = 0});

  PlayerStats copyWith({int? points, int? fouls}) {
    return PlayerStats(
      points: points ?? this.points,
      fouls: fouls ?? this.fouls,
    );
  }
}

class MatchState {
  final String matchId;
  final int scoreA;
  final int scoreB;
  final Duration timeLeft;
  final bool isRunning;
  final int currentPeriod;

  // --- NUEVO: PUNTUACIÓN POR PERIODO ---
  // Mapa donde la llave es el periodo (1, 2, 3...) y el valor es una lista [puntosA, puntosB]
  final Map<int, List<int>> periodScores;

  // Listas de jugadores
  final List<String> teamAOnCourt;
  final List<String> teamABench;
  final List<String> teamBOnCourt;
  final List<String> teamBBench;

  // Estadísticas individuales
  final Map<String, PlayerStats> playerStats;

  const MatchState({
    this.matchId = '',
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeLeft = const Duration(minutes: 10),
    this.isRunning = false,
    this.currentPeriod = 1,
    // Inicializamos el periodo 1 en 0-0
    this.periodScores = const {
      1: [0, 0],
    },
    this.teamAOnCourt = const [],
    this.teamABench = const [],
    this.teamBOnCourt = const [],
    this.teamBBench = const [],
    this.playerStats = const {},
  });

  MatchState copyWith({
    String? matchId,
    int? scoreA,
    int? scoreB,
    Duration? timeLeft,
    bool? isRunning,
    int? currentPeriod,
    Map<int, List<int>>? periodScores, // Nuevo parámetro
    List<String>? teamAOnCourt,
    List<String>? teamABench,
    List<String>? teamBOnCourt,
    List<String>? teamBBench,
    Map<String, PlayerStats>? playerStats,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      timeLeft: timeLeft ?? this.timeLeft,
      isRunning: isRunning ?? this.isRunning,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      periodScores: periodScores ?? this.periodScores,
      teamAOnCourt: teamAOnCourt ?? this.teamAOnCourt,
      teamABench: teamABench ?? this.teamABench,
      teamBOnCourt: teamBOnCourt ?? this.teamBOnCourt,
      teamBBench: teamBBench ?? this.teamBBench,
      playerStats: playerStats ?? this.playerStats,
    );
  }
}

// --- CONTROLADOR (LÓGICA) ---

class MatchGameController extends StateNotifier<MatchState> {
  final MatchesDao _dao;
  Timer? _timer;
  final List<MatchState> _history = [];

  MatchGameController(this._dao) : super(const MatchState());

  void initMatch(String matchId) {
    state = state.copyWith(
      matchId: matchId,
      teamAOnCourt: List.generate(5, (i) => "Jugador A$i"),
      teamABench: List.generate(3, (i) => "Banca A$i"),
      teamBOnCourt: List.generate(5, (i) => "Jugador B$i"),
      teamBBench: List.generate(3, (i) => "Banca B$i"),
    );
  }

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

  // --- AVANZAR PERIODO ---
  void nextPeriod() {
    _saveToHistory();

    int nextPeriodIdx = state.currentPeriod + 1;
    Duration newDuration = (nextPeriodIdx > 4)
        ? const Duration(minutes: 5)
        : const Duration(minutes: 10);

    // Inicializamos el marcador parcial del nuevo periodo en [0, 0]
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

  // --- ASIGNAR PERIODO MANUAL ---
  void setPeriod(int period) {
    _saveToHistory();
    Duration newDuration = (period > 4)
        ? const Duration(minutes: 5)
        : const Duration(minutes: 10);

    // Aseguramos que exista la entrada en el mapa para ese periodo
    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    if (!newPeriodScores.containsKey(period)) {
      newPeriodScores[period] = [0, 0];
    }

    state = state.copyWith(
      currentPeriod: period,
      timeLeft: newDuration,
      isRunning: false,
      periodScores: newPeriodScores,
    );
    _saveToDatabase();
  }

  void toggleTimer() {
    if (state.isRunning){
      _pause();
    }
    else{
      _start();
    }
  }

  void _start() {
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft.inSeconds > 0) {
        state = state.copyWith(
          timeLeft: state.timeLeft - const Duration(seconds: 1),
        );
      } else {
        _pause();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveToDatabase();
  }

  // --- AGREGAR PUNTOS Y FALTAS ---
  void updateStats(
    String teamId,
    String playerId, {
    int points = 0,
    int fouls = 0,
  }) {
    final currentStats = state.playerStats[playerId] ?? const PlayerStats();

    // Bloqueo de 5 faltas
    if (currentStats.fouls >= 5 && (points > 0 || fouls > 0)) return;

    _saveToHistory();

    // 1. Actualizar Score Global
    int newScoreA = state.scoreA;
    int newScoreB = state.scoreB;
    if (points > 0) {
      if (teamId == 'A'){
          newScoreA += points;
      }
        
      else{
          newScoreB += points;
      }
        
    }

    // 2. Actualizar Score Parcial del Periodo Actual
    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    // Recuperamos el score actual del periodo o iniciamos en [0,0]
    List<int> currentPeriodScore = List.from(
      newPeriodScores[state.currentPeriod] ?? [0, 0],
    );

    if (points > 0) {
      if (teamId == 'A'){
        currentPeriodScore[0] += points;
      }
        
      else{
        currentPeriodScore[1] += points;
      }
        
    }
    newPeriodScores[state.currentPeriod] = currentPeriodScore;

    // 3. Actualizar Stats Jugador
    final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStatsMap[playerId] = currentStats.copyWith(
      points: currentStats.points + points,
      fouls: currentStats.fouls + fouls,
    );

    state = state.copyWith(
      scoreA: newScoreA,
      scoreB: newScoreB,
      periodScores: newPeriodScores, // Guardamos el mapa actualizado
      playerStats: newPlayerStatsMap,
    );

    _saveToDatabase();
    _logEventToDb(playerId, points, fouls);
  }

  // --- SUSTITUCIONES ---
  void substitutePlayer(String teamId, String playerOut, String playerIn) {
    _saveToHistory();
    if (teamId == 'A') {
      final newOnCourt = List<String>.from(state.teamAOnCourt)
        ..remove(playerOut)
        ..add(playerIn);
      final newBench = List<String>.from(state.teamABench)
        ..remove(playerIn)
        ..add(playerOut);
      state = state.copyWith(teamAOnCourt: newOnCourt, teamABench: newBench);
    } else {
      final newOnCourt = List<String>.from(state.teamBOnCourt)
        ..remove(playerOut)
        ..add(playerIn);
      final newBench = List<String>.from(state.teamBBench)
        ..remove(playerIn)
        ..add(playerOut);
      state = state.copyWith(teamBOnCourt: newOnCourt, teamBBench: newBench);
    }
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

  Future<void> _logEventToDb(String player, int points, int fouls) async {
    if (state.matchId.isEmpty) return;
    String type = "UNKNOWN";
    if (points == 1) type = "POINT_1";
    if (points == 2) type = "POINT_2";
    if (points == 3) type = "POINT_3";
    if (fouls > 0) type = "FOUL";
    final timeStr =
        "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";
    await _dao.insertEvent(
      GameEventsCompanion.insert(
        matchId: state.matchId,
        type: type,
        period: state.currentPeriod,
        clockTime: timeStr,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final matchGameProvider =
    StateNotifierProvider<MatchGameController, MatchState>((ref) {
      final dao = ref.watch(matchesDaoProvider);
      return MatchGameController(dao);
    });
