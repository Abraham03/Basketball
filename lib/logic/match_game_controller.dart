import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/matches_dao.dart';
import '../core/di/dependency_injection.dart';

// --- NUEVO: CLASE PARA REGISTRAR CADA ANOTACIÓN ---
class ScoreEvent {
  final int period;
  final String teamId; // 'A' o 'B'
  final String playerId; // Nombre o ID del jugador
  final String playerNumber; // El dorsal (ej. "10") para poner en la hoja
  final int points; // 1, 2, o 3
  final int scoreAfter; // El marcador acumulado de ese equipo (ej. 12)

  const ScoreEvent({
    required this.period,
    required this.teamId,
    required this.playerId,
    required this.playerNumber,
    required this.points,
    required this.scoreAfter,
  });
}

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

  // --- PUNTUACIÓN POR PERIODO ---
  final Map<int, List<int>> periodScores;

  // --- NUEVO: HISTORIAL DE ANOTACIONES (PARA CONTEO CORRIDO) ---
  final List<ScoreEvent> scoreLog;

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
    this.periodScores = const {1: [0, 0]},
    this.scoreLog = const [], // Inicializamos vacío
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
    Map<int, List<int>>? periodScores,
    List<ScoreEvent>? scoreLog, // Nuevo parámetro
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
      scoreLog: scoreLog ?? this.scoreLog,
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
        // Al restaurar state, scoreLog regresa a su estado anterior automáticamente
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
    if (state.isRunning){ _pause();} else {_start();}
  }

  void _start() {
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft.inSeconds > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - const Duration(seconds: 1));
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

  // --- MODIFICADO: AGREGAR PUNTOS Y REGISTRAR EN EL LOG ---
  void updateStats(String teamId, String playerId, {int points = 0, int fouls = 0}) {
    final currentStats = state.playerStats[playerId] ?? const PlayerStats();

    if (currentStats.fouls >= 5 && (points > 0 || fouls > 0)) return;

    _saveToHistory();

    // 1. Calcular nuevos scores
    int newScoreA = state.scoreA;
    int newScoreB = state.scoreB;
    int scoreAfter = 0; // Para el evento

    if (points > 0) {
      if (teamId == 'A') {
        newScoreA += points;
        scoreAfter = newScoreA;
      } else {
        newScoreB += points;
        scoreAfter = newScoreB;
      }
    }

    // 2. Score por periodo
    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    List<int> currentPeriodScore = List.from(newPeriodScores[state.currentPeriod] ?? [0, 0]);
    if (points > 0) {
      if (teamId == 'A') {currentPeriodScore[0] += points;}
      else {currentPeriodScore[1] += points;}
    }
    newPeriodScores[state.currentPeriod] = currentPeriodScore;

    // 3. Stats Jugador
    final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStatsMap[playerId] = currentStats.copyWith(
      points: currentStats.points + points,
      fouls: currentStats.fouls + fouls,
    );

    // 4. NUEVO: Agregar al LOG si hubo puntos
    List<ScoreEvent> newScoreLog = List.from(state.scoreLog);
    if (points > 0) {
      // Obtenemos el dorsal simulado (i+4) igual que en el PDF
      String dorsal = "00";
      int indexA = state.teamAOnCourt.indexOf(playerId);
      if (indexA == -1) indexA = state.teamABench.indexOf(playerId);
      if (indexA != -1) dorsal = "${indexA + 4}";
      
      int indexB = state.teamBOnCourt.indexOf(playerId);
      if (indexB == -1) indexB = state.teamBBench.indexOf(playerId);
      if (indexB != -1) dorsal = "${indexB + 4}";

      newScoreLog.add(ScoreEvent(
        period: state.currentPeriod,
        teamId: teamId,
        playerId: playerId,
        playerNumber: dorsal,
        points: points,
        scoreAfter: scoreAfter,
      ));
    }

    state = state.copyWith(
      scoreA: newScoreA,
      scoreB: newScoreB,
      periodScores: newPeriodScores,
      playerStats: newPlayerStatsMap,
      scoreLog: newScoreLog, // Guardamos el log
    );

    _saveToDatabase();
    _logEventToDb(playerId, points, fouls);
  }

  void substitutePlayer(String teamId, String playerOut, String playerIn) {
    _saveToHistory();
    if (teamId == 'A') {
      final newOnCourt = List<String>.from(state.teamAOnCourt)..remove(playerOut)..add(playerIn);
      final newBench = List<String>.from(state.teamABench)..remove(playerIn)..add(playerOut);
      state = state.copyWith(teamAOnCourt: newOnCourt, teamABench: newBench);
    } else {
      final newOnCourt = List<String>.from(state.teamBOnCourt)..remove(playerOut)..add(playerIn);
      final newBench = List<String>.from(state.teamBBench)..remove(playerIn)..add(playerOut);
      state = state.copyWith(teamBOnCourt: newOnCourt, teamBBench: newBench);
    }
  }

  Future<void> _saveToDatabase() async {
    if (state.matchId.isEmpty) return;
    final timeStr = "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";
    await _dao.updateMatchStatus(state.matchId, state.scoreA, state.scoreB, timeStr, "IN_PROGRESS");
  }

  Future<void> _logEventToDb(String player, int points, int fouls) async {
    if (state.matchId.isEmpty) return;
    String type = "UNKNOWN";
    if (points == 1) type = "POINT_1";
    if (points == 2) type = "POINT_2";
    if (points == 3) type = "POINT_3";
    if (fouls > 0) type = "FOUL";
    final timeStr = "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}";
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

final matchGameProvider = StateNotifierProvider<MatchGameController, MatchState>((ref) {
  final dao = ref.watch(matchesDaoProvider);
  return MatchGameController(dao);
});