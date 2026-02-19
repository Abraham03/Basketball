import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; 

import '../core/database/app_database.dart';
import '../core/di/dependency_injection.dart';
import 'match_setup_screen.dart';

// Provider para leer el fixture local de un torneo específico
final localFixtureProvider = FutureProvider.family<Map<String, List<Fixture>>, String>((ref, tournamentId) async {
  final db = ref.read(databaseProvider);
  
  final matches = await (db.select(db.fixtures)
        ..where((tbl) => tbl.tournamentId.equals(tournamentId))
      ).get();

  final Map<String, List<Fixture>> grouped = {};
  for (var m in matches) {
    if (!grouped.containsKey(m.roundName)) {
      grouped[m.roundName] = [];
    }
    grouped[m.roundName]!.add(m);
  }
  
  return grouped;
});

class FixtureListScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const FixtureListScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<FixtureListScreen> createState() => _FixtureListScreenState();
}

class _FixtureListScreenState extends ConsumerState<FixtureListScreen> {

  // --- FUNCIÓN PARA GENERAR EL FIXTURE CON TODOS LOS PARÁMETROS ---
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
          title: const Text("Configurar Calendario", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("⚠️ Esto borrará el calendario actual y generará uno nuevo.", style: TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 20),
                  
                  // SOLUCIÓN AL ERROR DE DEPRECATED 'value' -> usamos 'initialValue'
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Formato de Vueltas", border: OutlineInputBorder()),
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome), // SOLUCIÓN: Cambiado magic_button a auto_awesome
              label: const Text("Generar"),
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
    if (!mounted) return; // SOLUCIÓN: Validar context asíncrono
    
    // 2. Mostrar Loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

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

        if (!mounted) return; // SOLUCIÓN: Validar mounted
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calendario generado con éxito", style: TextStyle(color: Colors.green))));
      } else {
        throw Exception("El servidor rechazó la solicitud");
      }
    } catch (e) {
      if (!mounted) return; // SOLUCIÓN: Validar mounted
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // Pequeño widget para no repetir código de los campos numéricos
  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Req.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixtureAsync = ref.watch(localFixtureProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text("Calendario de Juegos")),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateNewFixture(context),
        icon: const Icon(Icons.auto_awesome),
        label: const Text("Generar Fixture"),
      ),

      body: fixtureAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error local: $err")),
        data: (groupedRounds) {
          if (groupedRounds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No hay partidos programados.", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text("Toca el botón inferior para generarlos\nautomáticamente en la nube.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final roundNames = groupedRounds.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: roundNames.length,
            itemBuilder: (context, index) {
              final roundName = roundNames[index];
              final matches = groupedRounds[roundName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.grey.shade300,
                    child: Text(roundName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  // SOLUCIÓN: Quitar '.toList()' porque es innecesario con el operador spread '...'
                  ...matches.map((m) => _buildMatchCard(context, m)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Fixture match) {
    final isPlayable = match.status == 'SCHEDULED' || match.status == 'PENDING';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(match.teamAName, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text("VS", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Expanded(child: Text(match.teamBName, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        subtitle: Text(match.venueName ?? 'Sin sede'),
        trailing: isPlayable 
          ? const Icon(Icons.play_circle_fill, color: Colors.orange, size: 32)
          : (match.status == 'FINISHED' 
              ? const Icon(Icons.check_circle, color: Colors.green) 
              : const Icon(Icons.lock, color: Colors.grey)),
        onTap: isPlayable ? () {
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
              SnackBar(content: Text("Partido en estado: ${match.status}"))
            );
        },
      ),
    );
  }
}