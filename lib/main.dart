import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa Drift para usar la clase 'MatchesCompanion' para insertar
import 'core/database/app_database.dart';
import 'core/di/dependency_injection.dart';

// Importamos la nueva pantalla de control
import 'ui/match_control_screen.dart';

void main() {
  // Inicializamos el ProviderScope para que Riverpod funcione en toda la app
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basket Arbitraje',
      // Definimos un tema visual consistente
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        // Personalizamos las Cards para que se vean modernas
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MatchesListScreen(),
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta 'Debug'
    );
  }
}

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inyección de Dependencias: Obtenemos el DAO singleton
    final matchesDao = ref.watch(matchesDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partidos Programados')),
      // StreamBuilder escucha cambios en la BD en tiempo real
      body: StreamBuilder(
        stream: matchesDao.watchPendingMatches(),
        builder: (context, snapshot) {
          // 1. Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Manejo de errores
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar BD: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // 3. Datos obtenidos
          final matches = snapshot.data ?? [];

          // 4. Estado vacío
          if (matches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_basketball,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay partidos programados.\nPresiona + para crear uno.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 5. Lista de partidos
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.deepOrange,
                    child: Text(match.teamAName.substring(0, 1)),
                  ),
                  title: Text(
                    '${match.teamAName} vs ${match.teamBName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Fecha: ${match.scheduledDate.toString().split('.')[0]}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),

                  // --- LÓGICA DE NAVEGACIÓN ---
                  onTap: () {
                    // Navegamos a la pantalla de la cancha pasando los datos del partido
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchControlScreen(
                          matchId: match.id, // Pasamos el UUID del partido
                          teamAName: match.teamAName,
                          teamBName: match.teamBName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // Botón flotante para crear datos de prueba (Mock Data)
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Crear Partido"),
        icon: const Icon(Icons.add),
        onPressed: () async {
          // Generamos nombres aleatorios para simular variedad
          final randomId = DateTime.now().second;

          final nuevoPartido = MatchesCompanion.insert(
            teamAName: 'Toros $randomId',
            teamBName: 'Lakers $randomId',
            scheduledDate: DateTime.now(),
            // status se pone por defecto en 'PENDING' gracias al schema
          );

          await matchesDao.createMatch(nuevoPartido);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Partido creado localmente (SQLite)'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}
