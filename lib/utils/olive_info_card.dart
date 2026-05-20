import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/screens/olive_history_screen.dart';

class OliveInfoCard extends StatelessWidget {
  final Olive olive;
  final VoidCallback onClose;

  const OliveInfoCard({
    super.key,
    required this.olive,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    bool isCritical = olive.healthStatus == 'Enfermo';
    Color statusColor = isCritical ? Colors.red : Colors.green;
    String statusText = isCritical ? "ATENCIÓN REQUERIDA" : "ESTADO ÓPTIMO";

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Card(
        elevation: 10,
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: statusColor, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABECERA ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    avatar: SvgPicture.asset(
                      'assets/olive.svg',
                      colorFilter:
                          ColorFilter.mode(statusColor, BlendMode.srcIn),
                    ),
                    label: Text("${olive.id}: $statusText",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                  CloseButton(onPressed: onClose),
                ],
              ),
              const Divider(),

              _buildRowInfo("Variedad:", olive.variety ?? "Desconocida"),
              _buildRowInfo("Estado:", olive.healthStatus ?? "Normal"),
              _buildRowInfo("Longitud:", olive.longitude.toString() ),
              _buildRowInfo("Latitud:", olive.latitude.toString() ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.history, size: 16, color: Colors.green),
                        SizedBox(width: 5),
                        Text("Gestión de Olivo",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        "Consulta el historial para ver tratamientos y observaciones."),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 35,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OliveHistoryScreen(olive: olive),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt,
                            size: 18, color: Colors.white),
                        label: const Text("Ver Historial",
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Registrar Observación/Tratamiento"),
                  onPressed: () {
                    // Aquí iría la lógica para abrir un formulario de registro
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
