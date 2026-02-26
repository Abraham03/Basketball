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
import '../ui/widgets/app_background.dart';

// Provider REACTIVO para leer el fixture local de un torneo específico
final localFixtureProvider = StreamProvider.family<Map<String, List<Fixture>>, String>((ref, tournamentId) {
  final db = ref.read(databaseProvider);
  
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
  // Estado para el filtro de jornadas
  String _selectedRound = "Todas";

  // --- HELPER PARA RESOLVER LA RUTA DEL LOGO ---
  String _resolveLogoUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Si la BD trae rutas como "../assets/team_logo/...", las convertimos a URL absolutas
    return path.replaceAll('../', 'https://basket.techsolutions.management/');
  }

  Future<void> _generateNewFixture(BuildContext context) async {
    int selectedVueltas = 1;
    final txtWin = TextEditingController(text: "2");
    final txtLoss = TextEditingController(text: "1");
    final txtDraw = TextEditingController(text: "1");
    // Puntos por Forfeit (Ausencia)
    final txtForfeitWin = TextEditingController(text: "2");
    final txtForfeitLoss = TextEditingController(text: "0");
    final formKey = GlobalKey<FormState>();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2432),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.settings_suggest, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text("Configurar Calendario", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                        SizedBox(width: 10),
                        Expanded(child: Text("Generar un nuevo calendario borrará los partidos programados actualmente.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  DropdownButtonFormField<int>(
                    dropdownColor: const Color(0xFF2C3444),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Formato del Torneo", 
                      labelStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
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
                  const SizedBox(height: 24),
                  
                  const Text("PUNTOS POR PARTIDO JUGADO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 12, letterSpacing: 1.2)),
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
                  const SizedBox(height: 24),
                  
                  const Text("PUNTOS POR AUSENCIA (FORFEIT)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 12, letterSpacing: 1.2)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: const Text("Generar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      )
    );

    try {
      final api = ref.read(apiServiceProvider);
      
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
                    logoA: drift.Value(m['logo_a']),
                    logoB: drift.Value(m['logo_b']),
                    status: drift.Value(m['status'] ?? 'SCHEDULED'),
                  ),
                  mode: drift.InsertMode.insertOrReplace
                );
              }
            }
          });
          
          ref.invalidate(localFixtureProvider(widget.tournamentId));
          setState(() => _selectedRound = "Todas"); 
        }

        if (!mounted) return; 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Calendario generado con éxito"), backgroundColor: Colors.green));
      } else {
        throw Exception("El servidor rechazó la solicitud");
      }
    } catch (e) {
      if (!mounted) return; 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red));
    }
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Req.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixtureAsync = ref.watch(localFixtureProvider(widget.tournamentId));

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: Colors.transparent, 
      
      appBar: AppBar(
        title: const Text("Calendario de Juegos", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.0)),
        backgroundColor: Colors.black.withOpacity(0.6), 
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateNewFixture(context),
        icon: const Icon(Icons.auto_awesome),
        label: const Text("Generar Calendario", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        elevation: 4,
      ),

      body: AppBackground(
        opacity: 0.8, // Mayor opacidad para mejorar lectura
        child: fixtureAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
          error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
          data: (groupedRounds) {
            if (groupedRounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_month_outlined, size: 70, color: Colors.white54),
                    ),
                    const SizedBox(height: 24),
                    const Text("Aún no hay partidos", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      "Configura y genera el calendario\ndesde el botón inferior.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)
                    ),
                  ],
                ),
              );
            }

            List<String> allRounds = ["Todas"];
            allRounds.addAll(groupedRounds.keys.toList());

            Map<String, List<Fixture>> filteredRounds = {};
            if (_selectedRound == "Todas") {
              filteredRounds = groupedRounds;
            } else if (groupedRounds.containsKey(_selectedRound)) {
              filteredRounds[_selectedRound] = groupedRounds[_selectedRound]!;
            }

            return SafeArea(
              child: Column(
                children: [
                  // --- BARRA DE FILTRO POR JORNADAS ---
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allRounds.length,
                      itemBuilder: (context, index) {
                        final round = allRounds[index];
                        final isSelected = _selectedRound == round;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(round.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.black : Colors.white70)),
                            selected: isSelected,
                            selectedColor: Colors.orangeAccent,
                            backgroundColor: Colors.black.withOpacity(0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), 
                              side: const BorderSide(color: Colors.transparent)
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRound = round);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // --- LISTA DE PARTIDOS FILTRADOS ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100), 
                      itemCount: filteredRounds.keys.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final roundName = filteredRounds.keys.elementAt(index);
                        final matches = filteredRounds[roundName]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedRound == "Todas") 
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                                child: Row(
                                  children: [
                                    // Píldora moderna blanca con texto en NEGRO
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flag, color: Colors.black87, size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            roundName.toUpperCase(), 
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87, letterSpacing: 1.2)
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Colors.white38, indent: 12)),
                                  ],
                                ),
                              ),
                            
                            ...matches.map((m) => _buildMatchCard(context, m)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPER PARA LOGOS ---
  Widget _buildTeamLogo(String? logoPath, String teamName) {
    final String resolvedUrl = _resolveLogoUrl(logoPath);
    final String initial = teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipOval(
        child: resolvedUrl.isNotEmpty
            ? Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)),
                ),
              )
            : Center(
                child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)),
              ),
      ),
    );
  }

  // --- DISEÑO DE TARJETA DE PARTIDO PROFESIONAL ---
  Widget _buildMatchCard(BuildContext context, Fixture match) {
    final isPlayable = match.status == 'SCHEDULED' || 
                       match.status == 'PENDING' || 
                       match.status == 'IN_PROGRESS' || 
                       match.status == 'PLAYING';

    final isFinished = match.status == 'FINISHED';

    // Formatear la fecha para que sea súper profesional y visible
    String dateFormatted = "Horario por definir";
    if (match.scheduledDatetime != null) {
      final dt = match.scheduledDatetime!;
      dateFormatted = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}  •  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} hrs";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPlayable ? () {
                 if (match.status == 'IN_PROGRESS' || match.status == 'PLAYING') {
                   final currentState = ref.read(matchGameProvider);
                   if (currentState.matchId == match.matchId && currentState.matchId.isNotEmpty) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => MatchControlScreen(
                         matchId: currentState.matchId,
                         teamAName: match.teamAName,
                         teamBName: match.teamBName,
                         tournamentName: "Torneo Activo", 
                         venueName: match.venueName ?? '',
                         mainReferee: currentState.mainReferee,
                         auxReferee: currentState.auxReferee,
                         scorekeeper: currentState.scorekeeper,
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
                     ));
                     return; 
                   }
                 }

                 Navigator.push(context, MaterialPageRoute(builder: (_) => MatchSetupScreen(
                     tournamentId: widget.tournamentId,
                     preSelectedFixture: match,
                   ),
                 ));
              } : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("ℹ️ Partido en estado: ${match.status}"), backgroundColor: Colors.blueGrey)
                  );
              },
              splashColor: Colors.orange.withOpacity(0.3),
              highlightColor: Colors.orange.withOpacity(0.1),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearBinding.linear(
                    Colors.white.withOpacity(0.15), 
                    Colors.white.withOpacity(0.03)
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Encabezado de la Tarjeta (Estado y Fecha/Lugar super visibles)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadge(match.status),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month, size: 14, color: Colors.orangeAccent),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        dateFormatted, 
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 13, color: Colors.white54),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        match.venueName ?? 'Sede TBD', 
                                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Cuerpo Principal (Equipo A - Score/Acción - Equipo B)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // EQUIPO A
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildTeamLogo(match.logoA, match.teamAName),
                                const SizedBox(height: 8),
                                Text(
                                  match.teamAName, 
                                  textAlign: TextAlign.center, 
                                  maxLines: 2,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),

                          // SCORE O BOTÓN DE ACCIÓN CENTRAL
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Text(
                                  isFinished && match.scoreA != null && match.scoreB != null 
                                    ? "${match.scoreA} - ${match.scoreB}" 
                                    : "VS", 
                                  style: TextStyle(
                                    color: isFinished ? Colors.white : Colors.orangeAccent, 
                                    fontSize: 28, 
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0
                                  )
                                ),
                                const SizedBox(height: 12),
                                // Botón de jugar
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: isPlayable ? Colors.orangeAccent : Colors.white.withOpacity(0.05), 
                                    shape: BoxShape.circle,
                                    boxShadow: isPlayable ? [BoxShadow(color: Colors.orangeAccent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)] : []
                                  ),
                                  child: Icon(
                                    (match.status == 'IN_PROGRESS' || match.status == 'PLAYING') 
                                        ? Icons.restore 
                                        : isPlayable 
                                            ? Icons.play_arrow_rounded 
                                            : Icons.lock_outline_rounded,
                                    color: isPlayable ? Colors.black : Colors.white38, 
                                    size: 26
                                  )
                                ),
                              ],
                            ),
                          ),

                          // EQUIPO B
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildTeamLogo(match.logoB, match.teamBName),
                                const SizedBox(height: 8),
                                Text(
                                  match.teamBName, 
                                  textAlign: TextAlign.center, 
                                  maxLines: 2,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper para renderizar un chip de estado
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color txtColor;
    String label;

    switch (status) {
      case 'FINISHED':
        bgColor = Colors.green.withOpacity(0.2);
        txtColor = Colors.greenAccent;
        label = "FINALIZADO";
        break;
      case 'IN_PROGRESS':
      case 'PLAYING':
        bgColor = Colors.orange.withOpacity(0.2);
        txtColor = Colors.orangeAccent;
        label = "EN JUEGO";
        break;
      case 'FORFEIT_A':
      case 'FORFEIT_B':
        bgColor = Colors.red.withOpacity(0.2);
        txtColor = Colors.redAccent;
        label = "AUSENCIA";
        break;
      case 'SCHEDULED':
      case 'PENDING':
      default:
        bgColor = Colors.white.withOpacity(0.1);
        txtColor = Colors.white70;
        label = "PROGRAMADO";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: txtColor.withOpacity(0.5))
      ),
      child: Text(label, style: TextStyle(color: txtColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }
}

// Extensión para usar gradientes como fondo del contenedor (Material)
class LinearBinding {
   static LinearGradient linear(Color c1, Color c2) {
      return LinearGradient(
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
         colors: [c1, c2],
      );
   }
}