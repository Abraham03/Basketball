import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/home_menu_screen.dart'; // Importamos tu nuevo menú principal

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
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta 'Debug'
      
      // Definimos un tema visual consistente y moderno
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange, // Color principal (Naranja Basket)
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        
        // Estilo global para las Cards
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Estilo global para los Inputs (TextFormField)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        
        // Estilo global para botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // 🚀 AQUÍ ESTÁ EL CAMBIO CLAVE:
      // En lugar de ir a la lista de pruebas, vamos al Menú Principal que creamos
      home: const HomeMenuScreen(), 
    );
  }
}