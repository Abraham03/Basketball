// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. IMPORTANTE: Necesario para controlar la orientación
import 'package:signature/signature.dart';

class ProtestSignatureScreen extends StatefulWidget {
  final String teamName;

  const ProtestSignatureScreen({super.key, required this.teamName});

  @override
  State<ProtestSignatureScreen> createState() => _ProtestSignatureScreenState();
}

class _ProtestSignatureScreenState extends State<ProtestSignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    // No podemos usar MediaQuery aquí directamente porque el contexto no está listo.
    // Usamos addPostFrameCallback para hacerlo apenas se dibuje el primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOrientation();
    });
  }

  void _checkOrientation() {
    // 2. LÓGICA PARA DETECTAR TABLET VS CELULAR
    // "shortestSide" es el ancho cuando estás en portrait.
    final double shortestSide = MediaQuery.of(context).size.shortestSide;
    final bool isTablet = shortestSide >= 600; 

    if (!isTablet) {
      // 3. SI ES CELULAR: Forzamos modo Horizontal para firmar cómodo
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    // Si es tablet, no hacemos nada (mantiene la orientación que tenga)
  }

  @override
  void dispose() {
    // 4. AL SALIR: Restaurar orientación Vertical (para que el resto de la app se vea bien)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firma bajo Protesta"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      // Usamos SafeArea para evitar que la cámara/notch estorbe en horizontal
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Capitán del equipo ${widget.teamName}, firme a continuación:",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            // --- ÁREA DE FIRMA ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  color: Colors.grey.shade100,
                ),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                  // Opcional: define el tamaño máximo si quieres
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            // --- BOTONES ---
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.clear),
                    label: const Text("Borrar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      foregroundColor: Colors.white
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_controller.isNotEmpty) {
                        final Uint8List? data = await _controller.toPngBytes();
                        if (data != null && mounted) {
                          Navigator.pop(context, data);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Debes firmar para continuar")),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Guardar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      foregroundColor: Colors.white
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}