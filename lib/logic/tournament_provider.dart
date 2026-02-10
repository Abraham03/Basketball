import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importamos app_database.dart donde se genera la clase Tournament
import '../core/database/app_database.dart';

// 1. Provider para obtener la base de datos
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// 2. Provider que escucha los torneos disponibles en la BD
final tournamentsListProvider = StreamProvider<List<Tournament>>((ref) {
  final db = ref.watch(databaseProvider);
  // NOTA: Si 'db.tournaments' sale en rojo, ES PORQUE FALTA EJECUTAR EL PASO 1 (build_runner)
  return db.select(db.tournaments).watch();
});

// 3. Provider para guardar el ID del torneo seleccionado
final selectedTournamentIdProvider = StateProvider<String?>((ref) => null);

// 4. Provider computado: Devuelve el objeto Tournament completo seleccionado
final currentTournamentProvider = Provider<Tournament?>((ref) {
  final selectedId = ref.watch(selectedTournamentIdProvider);
  final tournamentsAsync = ref.watch(tournamentsListProvider);

  return tournamentsAsync.when(
    data: (tournaments) {
      if (selectedId == null) return null;
      try {
        // Buscamos el torneo cuyo ID coincida
        return tournaments.firstWhere((t) => t.id == selectedId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});