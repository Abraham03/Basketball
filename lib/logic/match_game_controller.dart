import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final int scoreA;
  final int scoreB;
  final Duration timeLeft;
  final bool isRunning;
  final int currentPeriod;

  // Nuevo: Mapa para guardar stats por ID de jugador ("A_1", "B_5", etc.)
  final Map<String, PlayerStats> playerStats;

  const MatchState({
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeLeft = const Duration(minutes: 10),
    this.isRunning = false,
    this.currentPeriod = 1,
    this.playerStats = const {},
  });

  MatchState copyWith({
    int? scoreA,
    int? scoreB,
    Duration? timeLeft,
    bool? isRunning,
    int? currentPeriod,
    Map<String, PlayerStats>? playerStats,
  }) {
    return MatchState(
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      timeLeft: timeLeft ?? this.timeLeft,
      isRunning: isRunning ?? this.isRunning,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      playerStats: playerStats ?? this.playerStats,
    );
  }
}

// --- CONTROLADOR (LÓGICA) ---

class MatchGameController extends StateNotifier<MatchState> {
  Timer? _timer;
  // Pila de historial para "Deshacer"
  final List<MatchState> _history = [];

  MatchGameController() : super(const MatchState());

  // Helper para guardar historial antes de modificar (excepto el reloj)
  void _saveToHistory() {
    // Limitamos el historial a 50 pasos para no llenar la memoria
    if (_history.length > 50) _history.removeAt(0);
    _history.add(state);
  }

  // 1. DESHACER (UNDO)
  void undo() {
    if (_history.isNotEmpty) {
      final previousState = _history.removeLast();
      // Mantenemos el reloj actual o el anterior?
      // Generalmente el reloj NO se deshace, solo puntos/faltas.
      // Así que restauramos todo menos el tiempo y isRunning.
      state = previousState.copyWith(
        timeLeft: state.timeLeft,
        isRunning: state.isRunning,
      );
    }
  }

  // 2. AJUSTAR RELOJ
  void adjustTime(int seconds) {
    // No guardamos historial para ajustes de reloj
    final newSeconds = state.timeLeft.inSeconds + seconds;
    if (newSeconds < 0) return; // No bajar de 0
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
  }

  // 3. AGREGAR PUNTOS Y FALTAS
  void updateStats(
    String teamId,
    String playerId, {
    int points = 0,
    int fouls = 0,
  }) {
    _saveToHistory();

    // Actualizamos marcador global
    int newScoreA = state.scoreA;
    int newScoreB = state.scoreB;
    if (points > 0) {
      if (teamId == 'A')
        newScoreA += points;
      else
        newScoreB += points;
    }

    // Actualizamos stats del jugador específico
    final currentStats = state.playerStats[playerId] ?? const PlayerStats();
    final newStats = currentStats.copyWith(
      points: currentStats.points + points,
      fouls: currentStats.fouls + fouls,
    );

    // Creamos nuevo mapa de stats
    final newPlayerStats = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStats[playerId] = newStats;

    state = state.copyWith(
      scoreA: newScoreA,
      scoreB: newScoreB,
      playerStats: newPlayerStats,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final matchGameProvider =
    StateNotifierProvider.autoDispose<MatchGameController, MatchState>((ref) {
      return MatchGameController();
    });
