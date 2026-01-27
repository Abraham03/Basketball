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
  final String matchId; // Necesario para guardar en BD
  final int scoreA;
  final int scoreB;
  final Duration timeLeft;
  final bool isRunning;
  final int currentPeriod;

  // --- NUEVO: LISTAS PARA SUSTITUCIONES ---
  final List<String> teamAOnCourt;
  final List<String> teamABench;
  final List<String> teamBOnCourt;
  final List<String> teamBBench;

  // Mapa de estadísticas por jugador
  final Map<String, PlayerStats> playerStats;

  const MatchState({
    this.matchId = '',
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeLeft = const Duration(minutes: 10),
    this.isRunning = false,
    this.currentPeriod = 1,
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
  final MatchesDao _dao; // DAO Inyectado
  Timer? _timer;
  final List<MatchState> _history = [];

  // Constructor recibe el DAO
  MatchGameController(this._dao) : super(const MatchState());

  // INICIALIZACIÓN: Carga datos iniciales (Dummy por ahora)
  void initMatch(String matchId) {
    state = state.copyWith(
      matchId: matchId,
      // Generamos 5 titulares y 3 suplentes por equipo
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

  // 1. DESHACER (UNDO) CON GUARDADO EN BD
  void undo() {
    if (_history.isNotEmpty) {
      final previousState = _history.removeLast();
      // Restauramos todo MENOS el tiempo y el estado del reloj (generalmente no se deshace el tiempo corrido)
      state = previousState.copyWith(
        timeLeft: state.timeLeft,
        isRunning: state.isRunning,
      );
      // ¡IMPORTANTE! Guardamos el estado restaurado en la BD
      _saveToDatabase();
    }
  }

  // 2. AJUSTAR RELOJ (SCROLL)
  void setTime(Duration newTime) {
    state = state.copyWith(timeLeft: newTime);
  }

  void adjustTime(int seconds) {
    final newSeconds = state.timeLeft.inSeconds + seconds;
    if (newSeconds < 0) return;
    state = state.copyWith(timeLeft: Duration(seconds: newSeconds));
  }

  void toggleTimer() {
    if (state.isRunning) {
      _pause();
    } else {
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
    _saveToDatabase(); // Guardar al pausar
  }

  // 3. AGREGAR PUNTOS Y FALTAS
  void updateStats(
    String teamId,
    String playerId, {
    int points = 0,
    int fouls = 0,
  }) {
    _saveToHistory();

    int newScoreA = state.scoreA;
    int newScoreB = state.scoreB;
    if (points > 0) {
      if (teamId == 'A') {
        newScoreA += points;
      } else {
        newScoreB += points;
      }
    }

    final currentStats = state.playerStats[playerId] ?? const PlayerStats();
    final newStats = currentStats.copyWith(
      points: currentStats.points + points,
      fouls: currentStats.fouls + fouls,
    );

    final newPlayerStats = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStats[playerId] = newStats;

    state = state.copyWith(
      scoreA: newScoreA,
      scoreB: newScoreB,
      playerStats: newPlayerStats,
    );

    // GUARDADO AUTOMÁTICO
    _saveToDatabase();
    _logEventToDb(playerId, points, fouls);
  }

  // 4. SUSTITUCIONES
  void substitutePlayer(String teamId, String playerOut, String playerIn) {
    _saveToHistory(); // Guardar historial antes del cambio

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

    // Podríamos guardar el evento de cambio aquí también si fuera necesario
  }

  // --- MÉTODOS PRIVADOS DE BASE DE DATOS ---
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

    // Insertamos en GameEvents
    await _dao.insertEvent(
      GameEventsCompanion.insert(
        matchId: state.matchId,
        type: type,
        period: state.currentPeriod,
        clockTime: timeStr,
        // playerId: Value(player), // En un futuro usarás el UUID real
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// PROVIDER (Sin autoDispose para mantener el reloj vivo si sales de la pantalla)
final matchGameProvider =
    StateNotifierProvider<MatchGameController, MatchState>((ref) {
      final dao = ref.watch(matchesDaoProvider); // Inyectamos el DAO
      return MatchGameController(dao);
    });
