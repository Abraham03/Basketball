import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../service/api_service.dart';

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

// Esto crea la variable 'apiServiceProvider' que te faltaba
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
