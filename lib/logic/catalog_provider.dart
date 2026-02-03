import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/catalog_models.dart';
import '../core/service/api_service.dart';

// Provider que instancia el servicio API
final apiServiceProvider = Provider((ref) => ApiService());

// FutureProvider que descarga los datos al iniciar la pantalla
final catalogProvider = FutureProvider<CatalogData>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.fetchCatalogs();
});