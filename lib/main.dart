import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/di/dependency_injection.dart'; // Importa tus providers

void main() {
  // 1. Envuelve la app en ProviderScope
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basket Arbitraje',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      // Por ahora apuntamos al Home, luego pondremos el Login
      home: const MatchesListScreen(),
    );
  }
}

// --- PANTALLA DE PRUEBA (Para verificar que la BD funciona) ---
// ConsumerWidget es como un Componente que puede "escuchar" servicios
class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Inyectamos el DAO
    final matchesDao = ref.watch(matchesDaoProvider);

    // 3. Usamos un StreamBuilder (como el AsyncPipe de Angular)
    return Scaffold(
      appBar: AppBar(title: const Text('Partidos Programados')),
      body: StreamBuilder(
        stream: matchesDao.watchPendingMatches(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No hay partidos pendientes'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return ListTile(
                title: Text('${match.teamAName} vs ${match.teamBName}'),
                subtitle: Text(match.scheduledDate.toString()),
                trailing: const Icon(Icons.arrow_forward_ios),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 4. Prueba rápida: Crear un partido dummy
          // Descomenta esto cuando importes drift y uuid
          await matchesDao.createMatch(
            MatchesCompanion.insert(
              teamAName: 'Toros',
              teamBName: 'Lakers',
              scheduledDate: DateTime.now(),
            ),
          );

          print("Botón presionado: Implementar creación");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
