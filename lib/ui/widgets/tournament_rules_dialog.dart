import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TournamentRulesDialog extends StatefulWidget {
  final bool showVueltas; // true = Generación Automática | false = Constructor Manual

  const TournamentRulesDialog({super.key, this.showVueltas = false});

  @override
  State<TournamentRulesDialog> createState() => _TournamentRulesDialogState();
}

class _TournamentRulesDialogState extends State<TournamentRulesDialog> {
  int selectedVueltas = 1;
  final txtWin = TextEditingController(text: "2");
  final txtLoss = TextEditingController(text: "1");
  final txtDraw = TextEditingController(text: "1");
  final txtForfeitWin = TextEditingController(text: "2");
  final txtForfeitLoss = TextEditingController(text: "0");
  final formKey = GlobalKey<FormState>();

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
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2432),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.settings_suggest, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Text(widget.showVueltas ? "Generar Calendario" : "Reglas de Puntos", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showVueltas) ...[
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
              ] else ...[
                const Text("Define cómo se sumarán los puntos en la tabla de posiciones.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
                const SizedBox(height: 24),
              ],
              
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
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
          ),
          icon: Icon(widget.showVueltas ? Icons.auto_awesome : Icons.save, color: Colors.white, size: 18),
          label: Text(widget.showVueltas ? "Generar" : "Guardar", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              // Retornamos un mapa con todos los datos capturados
              Navigator.pop(context, {
                'vueltas': selectedVueltas,
                'win': int.parse(txtWin.text),
                'loss': int.parse(txtLoss.text),
                'draw': int.parse(txtDraw.text),
                'forfeitWin': int.parse(txtForfeitWin.text),
                'forfeitLoss': int.parse(txtForfeitLoss.text),
              });
            }
          },
        ),
      ],
    );
  }
}