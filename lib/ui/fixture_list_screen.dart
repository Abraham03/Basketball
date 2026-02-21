// lib/ui/screens/fixture_list_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../core/database/app_database.dart';
import '../core/di/dependency_injection.dart';
import 'match_setup_screen.dart';

// --- IMPORTAMOS EL FONDO REUTILIZABLE ---
import '../ui/widgets/app_background.dart';

// 1. Provider para manejar el estado del filtro seleccionado (null = Todas las jornadas)
final selectedRoundProvider = StateProvider<String?>((ref) => null);

// Provider para leer el fixture local de un torneo específico
final localFixtureProvider = StreamProvider.autoDispose
    .family<Map<String, List<Fixture>>, String>((ref, tournamentId) {
      final db = ref.read(databaseProvider);

      return (db.select(db.fixtures)
            ..where((tbl) => tbl.tournamentId.equals(tournamentId)))
          .watch()
          .map((matches) {
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

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "⚙️ Configurar Calendario",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "⚠️ Esto borrará el calendario actual y generará uno nuevo.",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: "Formato de Vueltas",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    initialValue: selectedVueltas,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text("Una Vuelta (Ida)"),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text("Dos Vueltas (Ida y Vuelta)"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedVueltas = val);
                    },
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    "Sistema de Puntuación",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

                  const Text(
                    "Puntos por Forfeit",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField("Gana (W)", txtForfeitWin),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNumberField("Pierde (L)", txtForfeitLoss),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                "Generar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
      ),
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

          await (db.delete(
            db.fixtures,
          )..where((f) => f.tournamentId.equals(widget.tournamentId))).go();

          final roundsMap = newFixtureData['rounds'] as Map<String, dynamic>;
          await db.transaction(() async {
            for (var entry in roundsMap.entries) {
              final roundName = entry.key;
              final matches = entry.value as List;
              for (var m in matches) {
                DateTime? scheduledDate;
                if (m['scheduled_datetime'] != null &&
                    m['scheduled_datetime'].toString().isNotEmpty) {
                  scheduledDate = DateTime.tryParse(
                    m['scheduled_datetime'].toString(),
                  );
                }

                int? sA;
                int? sB;
                if (m['score_a'] != null)
                  sA = int.tryParse(m['score_a'].toString());
                if (m['score_b'] != null)
                  sB = int.tryParse(m['score_b'].toString());

                await db
                    .into(db.fixtures)
                    .insert(
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
                        venueId: drift.Value(m['venue_id']?.toString()),
                        venueName: drift.Value(m['venue_name']),
                        scheduledDatetime: drift.Value(scheduledDate),
                        matchId: drift.Value(m['match_id']?.toString()),
                        scoreA: drift.Value(sA),
                        scoreB: drift.Value(sB),
                        status: drift.Value(m['status'] ?? 'SCHEDULED'),
                      ),
                      mode: drift.InsertMode.insertOrReplace,
                    );
              }
            }
          });

          // Reseteamos el filtro a "Todas" al generar nuevo calendario
          ref.read(selectedRoundProvider.notifier).state = null;
        }

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Calendario generado con éxito"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("El servidor rechazó la solicitud");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
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
    final selectedRound = ref.watch(
      selectedRoundProvider,
    ); // Escuchamos el filtro actual

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text(
          "Calendario de Juegos",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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

      body: AppBackground(
        opacity: 0.5,
        child: fixtureAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          ),
          error: (err, stack) => Center(
            child: Text(
              "Error local: $err",
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
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
                      child: const Icon(
                        Icons.calendar_month,
                        size: 60,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No hay partidos programados.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Toca el botón inferior para generarlos\nautomáticamente en la nube.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 2. Extraer todas las jornadas disponibles para los botones de filtro
            final allRoundNames = groupedRounds.keys.toList();
            // Opcional: Ordenar alfabéticamente (Jornada 1, Jornada 2...)
            allRoundNames.sort((a, b) => a.compareTo(b));

            // 3. Aplicar el filtro al mapa de partidos
            final Map<String, List<Fixture>> filteredRounds =
                selectedRound == null
                ? groupedRounds
                : (groupedRounds.containsKey(selectedRound)
                      ? {selectedRound: groupedRounds[selectedRound]!}
                      : {});

            final displayRoundNames = filteredRounds.keys.toList();

            return Column(
              children: [
                // --- BARRA DE FILTROS SUPERIOR ---
                Container(
                  height: 60,
                  margin: EdgeInsets.only(
                    top:
                        MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        10,
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      _buildFilterChip("Todas", null, selectedRound, ref),
                      ...allRoundNames.map(
                        (round) =>
                            _buildFilterChip(round, round, selectedRound, ref),
                      ),
                    ],
                  ),
                ),

                // --- LISTA PRINCIPAL FILTRADA ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // Padding inferior para el FAB
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayRoundNames.length,
                    itemBuilder: (context, index) {
                      final roundName = displayRoundNames[index];
                      final matches = filteredRounds[roundName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TÍTULO DE LA JORNADA
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: const Border(
                                      left: BorderSide(
                                        color: Colors.orangeAccent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.sports_score,
                                        color: Colors.orangeAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        roundName.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // PARTIDOS DE ESA JORNADA
                          ...matches.map((m) => _buildMatchCard(context, m)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET PARA LOS BOTONES DE FILTRO (CHIPS) ---
  Widget _buildFilterChip(
    String label,
    String? value,
    String? selectedValue,
    WidgetRef ref,
  ) {
    final isSelected = value == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.orange.shade600,
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isSelected ? Colors.orangeAccent : Colors.white24,
        ),
        showCheckmark: false,
        onSelected: (_) {
          // Cambiamos el estado del provider al presionar
          ref.read(selectedRoundProvider.notifier).state = value;
        },
      ),
    );
  }

  // --- TARJETA DEL PARTIDO ---
  Widget _buildMatchCard(BuildContext context, Fixture match) {
    final isPlayable = match.status == 'SCHEDULED' || match.status == 'PENDING';
    final isFinished = match.status == 'FINISHED';
    final isPlaying = match.status == 'PLAYING';

    Color statusColor = Colors.grey;
    String statusText = "Por Jugar";

    if (isPlayable) {
      statusColor = Colors.orangeAccent;
      statusText = "Programado";
    } else if (isFinished) {
      statusColor = Colors.greenAccent;
      statusText = "Finalizado";
    } else if (isPlaying) {
      statusColor = Colors.redAccent;
      statusText = "En Vivo";
    }

    // Formatear Fecha
    String dateStr = "Horario por definir";
    if (match.scheduledDatetime != null) {
      final dt = match.scheduledDatetime!;
      dateStr =
          "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withOpacity(0.1),
            child: InkWell(
              onTap: isPlayable
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchSetupScreen(
                            tournamentId: widget.tournamentId,
                            preSelectedFixture: match,
                          ),
                        ),
                      );
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "ℹ️ Partido en estado: ${match.status}",
                          ),
                          backgroundColor: Colors.blueGrey,
                        ),
                      );
                    },
              splashColor: statusColor.withOpacity(0.3),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // 1. ENCABEZADO (Sede y Status)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      match.venueName ?? 'Sede por definir',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // 2. CUERPO (Equipos, Logos y Score)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Equipo A
                        Expanded(
                          child: Column(
                            children: [
                              _buildTeamLogo(match.logoA),
                              const SizedBox(height: 8),
                              Text(
                                match.teamAName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // SCORE o VS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: (isFinished || isPlaying)
                              ? Column(
                                  children: [
                                    Text(
                                      "${match.scoreA ?? 0} - ${match.scoreB ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    if (isFinished)
                                      const Text(
                                        "Final",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: const Text(
                                    "VS",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),

                        // Equipo B
                        Expanded(
                          child: Column(
                            children: [
                              _buildTeamLogo(match.logoB),
                              const SizedBox(height: 8),
                              Text(
                                match.teamBName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 3. PIE DE TARJETA (Solo si es jugable)
                    if (isPlayable) ...[
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Toca para iniciar partido",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl) {
    String? fullUrl;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      final cleanPath = logoUrl.startsWith('../')
          ? logoUrl.substring(3)
          : logoUrl;

      fullUrl = "https://basket.techsolutions.management/$cleanPath";
    }

    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: fullUrl != null
          ? ClipOval(
              child: Image.network(
                fullUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shield, color: Colors.grey, size: 30),
              ),
            )
          : const Icon(Icons.shield, color: Colors.grey, size: 30),
    );
  }
}
