import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../logic/match_game_controller.dart';
import 'widgets/scoreboard_widget.dart';
import 'widgets/app_background.dart';

class ClientScoreboardScreen extends StatefulWidget {
  const ClientScoreboardScreen({super.key});

  @override
  State<ClientScoreboardScreen> createState() => _ClientScoreboardScreenState();
}

class _ClientScoreboardScreenState extends State<ClientScoreboardScreen> {
  final TextEditingController _ipController = TextEditingController();
  WebSocketChannel? _channel;
  MatchState? _currentState;
  bool _isConnected = false;
  bool _isConnecting = false;

  String _teamAName = "Equipo A";
  String _teamBName = "Equipo B";
  int _teamAFouls = 0;
  int _teamBFouls = 0;

  void _connectToServer() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _isConnecting = true); 

    try {
      final uri = Uri.parse('ws://$ip:8080');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen((message) {
        final Map<String, dynamic> data = jsonDecode(message);
        setState(() {
          if (data.containsKey("state")) {
             _currentState = MatchState.fromJson(data["state"]);
             _teamAName = data["teamAName"] ?? "Equipo A";
             _teamBName = data["teamBName"] ?? "Equipo B";
             _teamAFouls = data["teamAFouls"] ?? 0;
             _teamBFouls = data["teamBFouls"] ?? 0;
          } else {
             _currentState = MatchState.fromJson(data);
          }
          _isConnected = true;
          _isConnecting = false; 
        });
      },
      onError: (e) {
        setState(() { _isConnected = false; _isConnecting = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo conectar. Verifica la IP y el Wi-Fi.'), backgroundColor: Colors.redAccent));
      },
      onDone: () {
        setState(() { _isConnected = false; _isConnecting = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desconectado del celular árbitro'), backgroundColor: Colors.orangeAccent));
      });

    } catch (e) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IP inválida: $e')));
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected || _currentState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Conectar a Pizarra")),
        body: AppBackground(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi, size: 60, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text("Ingresa la IP que aparece en el celular del árbitro:", style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ej: 192.168.43.1",
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  
                  _isConnecting 
                    ? const CircularProgressIndicator(color: Colors.orangeAccent)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                        onPressed: _connectToServer,
                        child: const Text("Conectar al Tablero", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Center(
        child: SafeArea(
          child: ScoreboardWidget(
            state: _currentState!,
            teamAName: _teamAName, 
            teamBName: _teamBName,
            teamAFouls: _teamAFouls,
            teamBFouls: _teamBFouls,
            isWideScreen: true,
            isLandscape: true,
            isReadOnly: true, 
            isFullScreen: true, // <--- LA MAGIA OCURRE AQUÍ PARA LA TABLET
          ),
        ),
      ),
    );
  }
}