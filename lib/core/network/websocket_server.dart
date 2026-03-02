import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LocalWebSocketServer {
  // Patrón Singleton corregido
  static final LocalWebSocketServer _instance = LocalWebSocketServer._internal();
  static LocalWebSocketServer get instance => _instance;
  
  LocalWebSocketServer._internal();

  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];
  String _lastPayload = "{}"; 

  Future<void> startServer() async {
    if (_server != null) return; 

    var handler = webSocketHandler((webSocket) {
      _clients.add(webSocket);
      webSocket.sink.add(_lastPayload); 
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080, shared: true);
    print('Servidor WebSocket activo en: ${_server!.address.address}:${_server!.port}');
  }

  void broadcast(String message) {
    _lastPayload = message;
    for (var client in _clients) {
      client.sink.add(message);
    }
  }

  void stopServer() {
    _server?.close(force: true);
    for (var client in _clients) {
      client.sink.close();
    }
    _clients.clear();
    _server = null;
  }
}