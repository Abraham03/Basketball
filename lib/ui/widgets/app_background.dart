// lib/ui/widgets/app_background.dart
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  
  /// Permite agregar un oscurecimiento extra si la pantalla lo requiere
  final double opacity; 

  const AppBackground({
    super.key, 
    required this.child,
    this.opacity = 0.4, // Nivel de sombra por defecto
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. IMAGEN DE FONDO GLOBAL
        Positioned.fill(
          child: Image.asset(
            'assets/images/fondo1.jpg',
            fit: BoxFit.cover,
          ),
        ),
        
        // 2. CAPA DE OSCURECIMIENTO (Para mejorar la lectura del texto)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(opacity),
          ),
        ),

        // 3. EL CONTENIDO DE TU PANTALLA
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}