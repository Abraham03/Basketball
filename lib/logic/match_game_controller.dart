import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/matches_dao.dart';
import '../core/di/dependency_injection.dart';
import '../core/models/catalog_models.dart' as models;
import '../core/service/api_service.dart';

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
  final String playerNumber; // Guardamos el dorsal aquí
  final List<String> foulDetails;

  const PlayerStats({
    this.dbId = 0,
    this.points = 0,
    this.fouls = 0,
    this.isOnCourt = false,
    this.isStarter = false,
    this.playerNumber = "00", // Valor por defecto
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
  final int? teamAId; // ID real de la base de datos (ej: 45)
  final int? teamBId; // ID real de la base de datos (ej: 48)
  final String mainReferee;
  final String auxReferee;
  final String scorekeeper;

  // Listas de NOMBRES (Strings) para referenciar el mapa
  final List<String> teamAOnCourt;
  final List<String> teamABench;
  final List<String> teamBOnCourt;
  final List<String> teamBBench;

  // Tiempos fuera (guardamos el minuto como String, ej: "7")
  final List<String> teamATimeouts1; // 1a Mitad (Periodos 1-2)
  final List<String> teamATimeouts2; // 2a Mitad (Periodos 3-4)
  final List<String> teamBTimeouts1;
  final List<String> teamBTimeouts2;

  final Map<String, PlayerStats> playerStats;

  const MatchState({
    this.matchId = '',
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
    this.teamATimeouts1 = const [],
    this.teamATimeouts2 = const [],
    this.teamBTimeouts1 = const [],
    this.teamBTimeouts2 = const [],
  });

  MatchState copyWith({
    String? matchId,
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
    List<String>? teamATimeouts1,
    List<String>? teamATimeouts2,
    List<String>? teamBTimeouts1,
    List<String>? teamBTimeouts2,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
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
      teamATimeouts1: teamATimeouts1 ?? this.teamATimeouts1,
      teamATimeouts2: teamATimeouts2 ?? this.teamATimeouts2,
      teamBTimeouts1: teamBTimeouts1 ?? this.teamBTimeouts1,
      teamBTimeouts2: teamBTimeouts2 ?? this.teamBTimeouts2,
    );
  }
}

class MatchGameController extends StateNotifier<MatchState> {
  final MatchesDao _dao;
  Timer? _timer;
  final List<MatchState> _history = [];

  MatchGameController(this._dao) : super(const MatchState());

  // Calcula faltas por equipo/periodo
  int getTeamFouls(String teamId) {
    return state.scoreLog.where((e) {
      // Es del equipo correcto, periodo actual y no sumó puntos (asumimos falta)
      return e.teamId == teamId && 
             e.period == state.currentPeriod && 
             e.points == 0;
    }).length;
  }



  Future<bool> finalizeAndSync(
    ApiService api, 
    Uint8List? signatureBytes, 
    String teamAName, 
    String teamBName
  ) async {
    
    // 1. Convertir Firma a Base64
    String? signatureBase64;
    if (signatureBytes != null) {
      signatureBase64 = base64Encode(signatureBytes);
    }

  // 2. Preparar eventos para JSON
    final eventsList = state.scoreLog.map((e) {
      return {
        "period": e.period,
        "team_side": e.teamId, // Enviamos 'A' o 'B' como team_side
        // En tu lógica actual, el playerId es el nombre del jugador
        "player_name": e.playerId, 
        "player_id": e.dbPlayerId,
        
        // Convertimos a string por seguridad, el backend lo pasará a int
        "player_number": e.playerNumber, 
        "points_scored": e.points, // NOMBRE CORREGIDO
        "score_after": e.scoreAfter, // DATO FALTANTE AGREGADO
        // "type" no está en tu tabla SQL, así que no es estrictamente necesario, 
        // pero lo dejamos por si acaso quieres guardarlo en otro lado o futuro.
        "type": e.type, 
      };
    }).toList();

    // 3. Payload Completo
    final payload = {
// IDs y Relaciones
      "match_id": state.matchId,
      "tournament_id": state.tournamentId,
      "venue_id": state.venueId,
      "team_a_id": state.teamAId,
      "team_b_id": state.teamBId,
      
      // Nombres (Redundancia útil para reportes rápidos)
      "team_a_name": teamAName,
      "team_b_name": teamBName,
      
      // Marcador y Estado
      "score_a": state.scoreA,
      "score_b": state.scoreB,
      "current_period": state.currentPeriod,
      "time_left": "${state.timeLeft.inMinutes}:${(state.timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
      
      // Oficiales
      "main_referee": state.mainReferee,
      "aux_referee": state.auxReferee,
      "scorekeeper": state.scorekeeper,
      
      // Datos extra
      "match_date": DateTime.now().toIso8601String(), // Enviamos fecha actual
      "signature_base64": signatureBase64,
      
      // Eventos (Tabla score_logs)
      "events": eventsList,
    };

    // 4. Enviar
    return await api.syncMatchData(payload);
  }


 // Método para agregar Tiempo Fuera
void addTimeout(String teamId) {
  _saveToHistory();

  // Cálculo preciso del minuto para la hoja
  int periodDuration = state.currentPeriod > 4 ? 5 : 10;
  int secondsElapsed = (periodDuration * 60) - state.timeLeft.inSeconds;
  int currentMinute = (secondsElapsed / 60).ceil();
  if (currentMinute == 0) currentMinute = 1;
  if (currentMinute > periodDuration) currentMinute = periodDuration;

  String minStr = currentMinute.toString();

  bool isClutchTime = state.currentPeriod == 4 && state.timeLeft.inSeconds == 120;

  if (teamId == 'A') {
    _processTimeoutWithRules(teamId, minStr, state.currentPeriod, isClutchTime);
  } else {
    _processTimeoutWithRules(teamId, minStr, state.currentPeriod, isClutchTime);
  }
}

void _processTimeoutWithRules(String teamId, String minStr, int period, bool isClutchTime) {
    List<String> currentList;
    bool isFirstHalf = period <= 2;
    bool isSecondHalf = period == 3 || period == 4;

    // A. PRIMERA MITAD (1 y 2)
    if (isFirstHalf) {
      currentList = List.from(teamId == 'A' ? state.teamATimeouts1 : state.teamBTimeouts1);
      if (currentList.length < 2) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 1, currentList);
      }
    } 
    // B. SEGUNDA MITAD (3 y 4)
    else if (isSecondHalf) {
      currentList = List.from(teamId == 'A' ? state.teamATimeouts2 : state.teamBTimeouts2);

      // --- REGLA DE ORO (AUTO-BURN) ---
      // Si estamos en los últimos 2 minutos Y la lista está vacía,
      // significa que no usaron ningún tiempo antes. Pierden uno (se marca X).
      if (isClutchTime && currentList.isEmpty) {
        currentList.add("X"); 
      }

      // Ahora verificamos si hay espacio.
      // Si se agregó la "X", la longitud es 1. Aún pueden agregar 2 más (Total 3).
      if (currentList.length < 3) {
        currentList.add(minStr);
        _updateTimeoutList(teamId, 2, currentList);
      } else {
        // Ya tienen 3 marcas (ej: "X", "9", "10"). No pueden pedir más.
      }
    } 
    // C. TIEMPO EXTRA
    else {
       // Lógica simple para OT: Agregamos a la lista de la 2da mitad si cabe, 
       // o podrías crear una lista nueva si tu PDF lo soporta.
       // FIBA da 1 tiempo por cada OT.
       currentList = List.from(teamId == 'A' ? state.teamATimeouts2 : state.teamBTimeouts2);
       // Aquí podrías permitir ir más allá de 3 si es OT, o resetear.
       // Por ahora, lo agregamos si hay espacio visual.
       if (currentList.length < 5) { // Damos un poco más de margen visual para OT
          currentList.add(minStr);
          _updateTimeoutList(teamId, 2, currentList);
       }
    }
  }

void _updateTimeoutList(String teamId, int half, List<String> newList) {
  if (teamId == 'A') {
    state = half == 1 
      ? state.copyWith(teamATimeouts1: newList) 
      : state.copyWith(teamATimeouts2: newList);
  } else {
    state = half == 1 
      ? state.copyWith(teamBTimeouts1: newList) 
      : state.copyWith(teamBTimeouts2: newList);
  }
  _saveToDatabase();
}

// ------------------------------------------------------------------------
  // TIMER CON CHEQUEO AUTOMÁTICO
  // ------------------------------------------------------------------------
  void _start() {
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft.inSeconds > 0) {
        final newTime = state.timeLeft - const Duration(seconds: 1);
        
        // Verificamos si al bajar el segundo entramos a 2:00 (120s) exactos en el 4to periodo
        bool triggerAutoBurn = state.currentPeriod == 4 && newTime.inSeconds == 120;

        state = state.copyWith(timeLeft: newTime);

        if (triggerAutoBurn) {
           _applyAutoBurn();
        }
      } else {
        _pause();
      }
    });
  }

  // Este método solo se llama automáticamete cuando el reloj cruza 2:00
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

      state = state.copyWith(
        teamATimeouts2: listA,
        teamBTimeouts2: listB,
      );
      _saveToDatabase();
    }
  }
  void initializeNewMatch({
    required String matchId,
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
    final Map<String, PlayerStats> initialStats = {};
    final List<String> courtA = [];
    final List<String> benchA = [];
    final List<String> courtB = [];
    final List<String> benchB = [];

    // Procesar Equipo A
    for (var player in rosterA) {
      final isStarter = startersA.contains(player.id);
      final pName = player.name;

      initialStats[pName] = PlayerStats(
        dbId: player.id,
        isOnCourt: isStarter,
        isStarter: isStarter,
        playerNumber: player.defaultNumber
            .toString(), // Guardamos el número real
      );

      if (isStarter) {
        courtA.add(pName);
      } else {
        benchA.add(pName);
      }
    }

    // Procesar Equipo B
    for (var player in rosterB) {
      final isStarter = startersB.contains(player.id);
      final pName = player.name;

      initialStats[pName] = PlayerStats(
        dbId: player.id,
        isOnCourt: isStarter,
        isStarter: isStarter,
        playerNumber: player.defaultNumber
            .toString(), // Guardamos el número real
      );

      if (isStarter) {
        courtB.add(pName);
      } else {
        benchB.add(pName);
      }
    }

    state = state.copyWith(
      matchId: matchId,
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
      teamBTimeouts1: [],
      teamBTimeouts2: [],
    );
  }

  // Recibe el equipo ('A' o 'B') directamente
  void setPossession(String team) {
    _saveToHistory();

    // Si tocas la flecha del equipo que YA tiene la posesión, la apagamos (opcional)
    if (state.possession == team) {
      state = state.copyWith(possession: '');
    } else {
      // Si no, le damos la posesión a ese equipo
      state = state.copyWith(possession: team);
    }
  }

  void initMatch(String matchId) {
    // Legacy stub
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
    final currentStats = state.playerStats[playerId] ?? const PlayerStats();
    // Si ya está expulsado (5 faltas), no dejar hacer nada más
    if (currentStats.fouls >= 5 && (points > 0 || fouls > 0)) return;

    _saveToHistory();

    int newScoreA = state.scoreA;
    int newScoreB = state.scoreB;
    int scoreAfter = 0;

    if (points > 0) {
      if (teamId == 'A') {
        newScoreA += points;
        scoreAfter = newScoreA;
      } else {
        newScoreB += points;
        scoreAfter = newScoreB;
      }
    }

    final newPeriodScores = Map<int, List<int>>.from(state.periodScores);
    List<int> currentPeriodScore = List.from(
      newPeriodScores[state.currentPeriod] ?? [0, 0],
    );
    if (points > 0) {
      if (teamId == 'A') {
        currentPeriodScore[0] += points;
      } else {
        currentPeriodScore[1] += points;
      }
    }
    newPeriodScores[state.currentPeriod] = currentPeriodScore;

    // AQUÍ ACTUALIZAMOS LA LISTA DE FALTAS
    List<String> newFoulDetails = List.from(currentStats.foulDetails);
    if (fouls > 0) {
      // Si recibimos un tipo específico (P1, T, etc), lo guardamos. Si no, "P" por defecto.
      // Pero quitamos el número para el PDF si es P1, P2? No, el PDF suele usar P, P1, P2...
      // Vamos a guardar el código tal cual viene del botón (P1, P2, P3, T, U, D)
      newFoulDetails.add(foulType ?? "P");
    }

    final newPlayerStatsMap = Map<String, PlayerStats>.from(state.playerStats);
    newPlayerStatsMap[playerId] = currentStats.copyWith(
      points: currentStats.points + points,
      fouls: currentStats.fouls + fouls,
      foulDetails: newFoulDetails,
    );

    List<ScoreEvent> newScoreLog = List.from(state.scoreLog);
    if (points > 0 || fouls > 0) {
      // Usamos el número real guardado en el estado
      String dorsal = currentStats.playerNumber;
      String eventType = "UNKNOWN";
      if (fouls > 0) eventType = foulType ?? "FOUL";

      newScoreLog.add(
        ScoreEvent(
          period: state.currentPeriod,
          teamId: teamId,
          playerId: playerId,// Nombre del jugador
          dbPlayerId: currentStats.dbId,
          playerNumber: dorsal,
          points: points,
          scoreAfter: scoreAfter,
          type: eventType,
        ),
      );
    }

    state = state.copyWith(
      scoreA: newScoreA,
      scoreB: newScoreB,
      periodScores: newPeriodScores,
      playerStats: newPlayerStatsMap,
      scoreLog: newScoreLog,
    );

    _saveToDatabase();
    _logEventToDb(playerId, points, fouls, foulType);
  }

  void substitutePlayer(String teamId, String playerOut, String playerIn) {
    _saveToHistory();

    final newStats = Map<String, PlayerStats>.from(state.playerStats);
    // Al jugador que SALE, solo le cambiamos isOnCourt a false.
    // isStarter se mantiene igual (si era true, seguirá siendo true).
    if (newStats.containsKey(playerOut)) {
      newStats[playerOut] = newStats[playerOut]!.copyWith(isOnCourt: false);
    }
    // Al jugador que ENTRA, solo le cambiamos isOnCourt a true.
    // isStarter se mantiene igual (si era false, seguirá siendo false).
    if (newStats.containsKey(playerIn)) {
      newStats[playerIn] = newStats[playerIn]!.copyWith(isOnCourt: true);
    }

    if (teamId == 'A') {
      final newOnCourt = List<String>.from(state.teamAOnCourt)
        ..remove(playerOut)
        ..add(playerIn);
      final newBench = List<String>.from(state.teamABench)
        ..remove(playerIn)
        ..add(playerOut);
      state = state.copyWith(
        teamAOnCourt: newOnCourt,
        teamABench: newBench,
        playerStats: newStats,
      );
    } else {
      final newOnCourt = List<String>.from(state.teamBOnCourt)
        ..remove(playerOut)
        ..add(playerIn);
      final newBench = List<String>.from(state.teamBBench)
        ..remove(playerIn)
        ..add(playerOut);
      state = state.copyWith(
        teamBOnCourt: newOnCourt,
        teamBBench: newBench,
        playerStats: newStats,
      );
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

  Future<void> _logEventToDb(
    String player,
    int points,
    int fouls,
    String? foulType,
  ) async {
    if (state.matchId.isEmpty) return;
    String type = "UNKNOWN";
    if (points == 1) type = "POINT_1";
    if (points == 2) type = "POINT_2";
    if (points == 3) type = "POINT_3";
    if (fouls > 0) {
      type = foulType ?? "FOUL";
    }

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
