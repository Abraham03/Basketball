// lib/ui/screens/fixture_list_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; 

import '../core/database/app_database.dart';
import '../core/di/dependency_injection.dart';
import 'match_setup_screen.dart';
import '../logic/match_game_controller.dart';
import 'match_control_screen.dart';

// --- IMPORTAMOS EL FONDO REUTILIZABLE ---
import '../ui/widgets/app_background.dart';

// Provider REACTIVO para leer el fixture local de un torneo específico
final localFixtureProvider = StreamProvider.family<Map<String, List<Fixture>>, String>((ref, tournamentId) {
  final db = ref.read(databaseProvider);
  
  // Usamos .watch() en lugar de .get() para escuchar los cambios en tiempo real
  return (db.select(db.fixtures)
        ..where((tbl) => tbl.tournamentId.equals(tournamentId))
      ).watch().map((matches) {
        
    final Map<String, List<Fixture>> grouped = {};
    for (var m in matches) {
      if (!grouped.containsKey(m.roundName)) {
        grouped[m.roundName] = [];
      }
      grouped[m.roundName]!.add(m);
    }
    
    return grouped;
  });
});

class FixtureListScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const FixtureListScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<FixtureListScreen> createState() => _FixtureListScreenState();
}

class _FixtureListScreenState extends ConsumerState<FixtureListScreen> {

  Future<void> _generateNewFixture(BuildContext context) async {
    int selectedVueltas = 1;
    final txtWin = TextEditingController(text: "2");
    final txtLoss = TextEditingController(text: "1");
    final txtDraw = TextEditingController(text: "1");
    final txtForfeitWin = TextEditingController(text: "2");
    final txtForfeitLoss = TextEditingController(text: "0");
    final formKey = GlobalKey<FormState>();

    // 1. Mostrar Diálogo de Configuración
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("⚙️ Configurar Calendario", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "⚠️ Esto borrará el calendario actual y generará uno nuevo.", 
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)
                  ),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: "Formato de Vueltas", 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    initialValue: selectedVueltas,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Una Vuelta (Ida)")),
                      DropdownMenuItem(value: 2, child: Text("Dos Vueltas (Ida y Vuelta)")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedVueltas = val);
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  const Text("Sistema de Puntuación", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _buildNumberField("Victoria", txtWin)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildNumberField("Derrota", txtLoss)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildNumberField("Empate", txtDraw)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  const Text("Puntos por Forfeit (Ausencia)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _buildNumberField("Gana (W)", txtForfeitWin)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildNumberField("Pierde (L)", txtForfeitLoss)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generar", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;
    if (!mounted) return; 
    
    // 2. Mostrar Loading con estilo
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      )
    );

    try {
      final api = ref.read(apiServiceProvider);
      
      // 3. Llamar a la API enviando TODOS los parámetros
      final success = await api.generateFixture(
        tournamentId: widget.tournamentId,
        vueltas: selectedVueltas,
        ptsVictoria: int.parse(txtWin.text),
        ptsDerrota: int.parse(txtLoss.text),
        ptsEmpate: int.parse(txtDraw.text),
        ptsForfeitWin: int.parse(txtForfeitWin.text),
        ptsForfeitLoss: int.parse(txtForfeitLoss.text),
      );
      
      if (success) {
        // 4. Descargamos el nuevo fixture de la nube
        final newFixtureData = await api.fetchFixture(widget.tournamentId);
        
        if (newFixtureData.isNotEmpty && newFixtureData['rounds'] != null) {
          final db = ref.read(databaseProvider);
          
          await (db.delete(db.fixtures)..where((f) => f.tournamentId.equals(widget.tournamentId))).go();

          final roundsMap = newFixtureData['rounds'] as Map<String, dynamic>;
          await db.transaction(() async {
            for (var entry in roundsMap.entries) {
              final roundName = entry.key;
              final matches = entry.value as List;
              for (var m in matches) {
                await db.into(db.fixtures).insert(
                  FixturesCompanion.insert(
                    id: m['id'].toString(),
                    tournamentId: widget.tournamentId,
                    roundName: roundName,
                    teamAId: m['team_a_id'].toString(),
                    teamBId: m['team_b_id'].toString(),
                    teamAName: m['team_a'] ?? 'A',
                    teamBName: m['team_b'] ?? 'B',
                    status: drift.Value(m['status'] ?? 'SCHEDULED'),
                  ),
                  mode: drift.InsertMode.insertOrReplace
                );
              }
            }
          });
          
          ref.invalidate(localFixtureProvider(widget.tournamentId));
        }

        if (!mounted) return; 
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Calendario generado con éxito"), backgroundColor: Colors.green));
      } else {
        throw Exception("El servidor rechazó la solicitud");
      }
    } catch (e) {
      if (!mounted) return; 
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red));
    }
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Req.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixtureAsync = ref.watch(localFixtureProvider(widget.tournamentId));

    return Scaffold(
      extendBodyBehindAppBar: true, // IMPORTANTE: El fondo sube hasta arriba
      backgroundColor: Colors.transparent, // Dejar que el AppBackground se vea
      
      // APPBAR TRANSPARENTE
      appBar: AppBar(
        title: const Text("Calendario de Juegos", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.4), 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateNewFixture(context),
        icon: const Icon(Icons.auto_awesome),
        label: const Text("Generar Fixture"),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),

      // ENVOLVEMOS EL BODY CON APPBACKGROUND
      body: AppBackground(
        opacity: 0.5, // Oscurecemos un poco más aquí para leer bien los partidos
        child: fixtureAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
          error: (err, stack) => Center(child: Text("Error local: $err", style: const TextStyle(color: Colors.redAccent))),
          data: (groupedRounds) {
            if (groupedRounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month, size: 60, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    const Text("No hay partidos programados.", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      "Toca el botón inferior para generarlos\nautomáticamente en la nube.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)
                    ),
                  ],
                ),
              );
            }

            final roundNames = groupedRounds.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, bottom: 100), // Padding superior por el AppBar
              itemCount: roundNames.length,
              itemBuilder: (context, index) {
                final roundName = roundNames[index];
                final matches = groupedRounds[roundName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO DE JORNADA (Estilizado)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        children: [
                          Container(width: 4, height: 20, color: Colors.orangeAccent),
                          const SizedBox(width: 10),
                          Text(
                            roundName.toUpperCase(), 
                            style: const TextStyle(
                              fontWeight: FontWeight.w900, 
                              fontSize: 16, 
                              color: Colors.white,
                              letterSpacing: 1.2
                            )
                          ),
                        ],
                      ),
                    ),
                    
                    // LISTA DE PARTIDOS
                    ...matches.map((m) => _buildMatchCard(context, m)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- DISEÑO DE TARJETA DE PARTIDO (MatchCard) ---
  Widget _buildMatchCard(BuildContext context, Fixture match) {
    final isPlayable = match.status == 'SCHEDULED' || 
                       match.status == 'PENDING' || 
                       match.status == 'IN_PROGRESS' || 
                       match.status == 'PLAYING';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto cristal
          child: Material(
            color: Colors.white.withOpacity(0.15),
            child: InkWell(
              onTap: isPlayable ? () {
                 // 1. Verificar si el partido ya está en progreso
                 if (match.status == 'IN_PROGRESS' || match.status == 'PLAYING') {
                   final currentState = ref.read(matchGameProvider);
                   
                   // 2. Si el partido sigue vivo en memoria (el usuario solo le dio "Atrás")
                   if (currentState.matchId == match.matchId && currentState.matchId.isNotEmpty) {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (_) => MatchControlScreen(
                           // Recuperamos la información vital de la memoria
                           matchId: currentState.matchId,
                           teamAName: match.teamAName,
                           teamBName: match.teamBName,
                           tournamentName: "Torneo Activo", 
                           venueName: match.venueName ?? '',
                           mainReferee: currentState.mainReferee,
                           auxReferee: currentState.auxReferee,
                           scorekeeper: currentState.scorekeeper,
                           
                           // Estas listas se ignoran porque el partido ya inicializó
                           fullRosterA: const [], 
                           fullRosterB: const [], 
                           startersAIds: const {},
                           startersBIds: const {},
                           
                           tournamentId: currentState.tournamentId ?? int.tryParse(widget.tournamentId) ?? 0,
                           venueId: currentState.venueId ?? 0,
                           teamAId: currentState.teamAId ?? 0,
                           teamBId: currentState.teamBId ?? 0,
                           coachA: '',
                           coachB: '',
                         ),
                       ),
                     );
                     return; // Salimos de la función para NO abrir el Setup
                   }
                 }

                 // 3. Flujo normal: Si es un partido nuevo o la app se cerró por completo
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => MatchSetupScreen(
                       tournamentId: widget.tournamentId,
                       preSelectedFixture: match,
                     ),
                   ),
                 );
              } : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("ℹ️ Partido en estado: ${match.status}"), backgroundColor: Colors.blueGrey)
                  );
              },
              splashColor: Colors.orange.withOpacity(0.3),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Columna de Equipos y Sede
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match.teamAName, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: const Text("VS", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text(
                                  match.teamBName, 
                                  textAlign: TextAlign.end, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.white54),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  match.venueName ?? 'Sede por definir', 
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Icono de acción
                    isPlayable 
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(
                            // 2. ACTUALIZAMOS EL ICONO PARA QUE MUESTRE REANUDAR
                            (match.status == 'IN_PROGRESS' || match.status == 'PLAYING') ? Icons.restore : Icons.play_arrow,
                            color: Colors.orangeAccent, 
                            size: 24
                          )
                        )
                      : (match.status == 'FINISHED' 
                          ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28) 
                          : const Icon(Icons.lock, color: Colors.white38, size: 24)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}