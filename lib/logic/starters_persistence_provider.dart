import 'package:flutter_riverpod/flutter_riverpod.dart';

// Verifica que NO diga "StateProvider.autoDispose"
final selectedStartersProvider = StateProvider.family<Map<String, Set<int>>, String>((ref, matchId) {
  return {
    'A': <int>{},
    'B': <int>{},
  };
});

final selectedCaptainsProvider = StateProvider.family<Map<String, int?>, String>((ref, matchId) {
  return {
    'A': null,
    'B': null,
  };
});