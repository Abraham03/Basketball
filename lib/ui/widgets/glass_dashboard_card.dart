// lib/ui/widgets/glass_dashboard_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const GlassDashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Efecto desenfoque del fondo
        child: Material(
          color: Colors.white.withOpacity(0.1), // Transparencia base
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.3),
            highlightColor: color.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                // Ligero gradiente interno
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                    child: Icon(icon, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}