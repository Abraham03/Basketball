import 'package:flutter/material.dart';
import 'match_setup_screen.dart';
import 'team_management_screen.dart';

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Basketball Manager")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _menuButton(
              context, 
              "🏀 Jugar Partido", 
              Colors.orange, 
              Icons.sports_basketball,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchSetupScreen()))
            ),
            const SizedBox(height: 20),
            _menuButton(
              context, 
              "📋 Gestionar Equipos", 
              Colors.blue, 
              Icons.groups,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementScreen()))
            ),
            const SizedBox(height: 20),
            _menuButton(
              context, 
              "🏆 Gestionar Torneos", 
              Colors.green, 
              Icons.emoji_events,
              () { 
                // Navegar a pantalla CRUD de Torneos
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String text, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(text, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
      ),
    );
  }
}