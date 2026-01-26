import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

// Provider de la Base de Datos (Singleton)
// Equivalente a un @Bean en Spring
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider del DAO de Partidos
final matchesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.matchesDao;
});
