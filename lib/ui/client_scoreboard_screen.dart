// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../logic/match_game_controller.dart';
import 'widgets/tv_scoreboard_widget.dart'; 
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
    String ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    // Si el usuario puso el puerto manualmente, lo dejamos, si no, lo agregamos nosotros
    if (!ip.contains(':')) {
      ip = '$ip:8080';
    }

    setState(() => _isConnecting = true); 

    try {
      // Construimos la URL completa: ws://192.168.1.5:8080
      final uri = Uri.parse('ws://$ip');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen((message) {
        final Map<String, dynamic> data = jsonDecode(message);
        if (mounted) {
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
        }
      },
      onError: (e) {
        _resetConnection();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se pudo encontrar el tablero. Revisa la IP.'), backgroundColor: Colors.redAccent));
      },
      onDone: () {
        _resetConnection();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conexión cerrada.'), backgroundColor: Colors.orangeAccent));
      });

    } catch (e) {
      _resetConnection();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP o formato inválido'), backgroundColor: Colors.red));
    }
  }

  void _resetConnection() {
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _currentState = null;
      });
    }
    _channel?.sink.close();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected || _currentState == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("CONECTAR PIZARRA GIGANTE"),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: AppBackground(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_remote, size: 80, color: Colors.orangeAccent),
                    const SizedBox(height: 24),
                    const Text(
                      "CONFIGURACIÓN DE RED",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Ingresa la IP del dispositivo Árbitro",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _ipController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "0.0.0.0",
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        suffixIcon: IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () => _ipController.clear()),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent, width: 2)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    _isConnecting 
                      ? const CircularProgressIndicator(color: Colors.orangeAccent)
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent, 
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: _connectToServer,
                            child: const Text("ENLAZAR TABLERO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                        )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // --- VISTA DEL TABLERO GIGANTE CON BOTÓN DE SALIDA ---
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          Center(
            child: SafeArea(
              child: TvScoreboardWidget(
                state: _currentState!,
                teamAName: _teamAName, 
                teamBName: _teamBName,
                teamAFouls: _teamAFouls,
                teamBFouls: _teamBFouls,
              ),
            ),
          ),
          // Botón discreto para desconectarse en la esquina
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.white24),
              onPressed: _resetConnection,
            ),
          ),
        ],
      ),
    );
  }
}