import 'package:flutter/material.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/utils/utils.dart';
import 'package:arceituna/services/services.dart';

class EnclosureSummaryModal extends StatefulWidget {
  final List<Olive> olives;
  final Enclosure? enclosure;

  const EnclosureSummaryModal({
    super.key,
    required this.olives,
    this.enclosure,
  });

  @override
  State<EnclosureSummaryModal> createState() => _EnclosureSummaryModalState();
}

class _EnclosureSummaryModalState extends State<EnclosureSummaryModal> {
  late Future<EnclosureSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummaryData();
  }

  Future<EnclosureSummary> _loadSummaryData() async {
    List<Map<String, dynamic>> treatments = [];
    List<Map<String, dynamic>> observations = [];

    if (widget.enclosure != null) {
      final results = await Future.wait([
        DatabaseService.instance.getTreatmentsByEnclosure(widget.enclosure!.id),
        DatabaseService.instance.getObservationsByEnclosure(widget.enclosure!.id),
      ]);
      treatments = results[0];
      observations = results[1];
    }

    return EnclosureSummary(
      widget.olives,
      treatments: treatments,
      observations: observations,
      enclosure: widget.enclosure,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        // Limitamos la altura al 70% de la pantalla
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: FutureBuilder<EnclosureSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text("Error al cargar estadísticas")),
            );
          }

          final stats = snapshot.data!;
          return _buildContent(context, stats);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EnclosureSummary stats) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABECERA FIJA con Flecha de cierre
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Resumen del Recinto",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  Text(
                    widget.enclosure != null
                        ? "Ref: ${widget.enclosure!.fullRef}"
                        : "Ubicación actual",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${stats.totalOlives} Olivos",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 24),

        // CUERPO CON SCROLL
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección: Información Geográfica
                _buildGeoInfo(stats),
                const SizedBox(height: 24),

                // Sección: Estado Fitosanitario
                const Text(
                  "Estado de Salud Global",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...OliveStatus.values.map((status) => _buildStatusRow(status, stats)),

                const SizedBox(height: 24),

                // Sección: Actividad Reciente
                const Text(
                  "Actividad Reciente",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildActivityCards(stats),

                const SizedBox(height: 24),

                // Sección: Variedades
                const Text(
                  "Variedades",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.varietyCounts.entries.map((entry) {
                    return Chip(
                      label: Text("${entry.key}: ${entry.value}"),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeoInfo(EnclosureSummary stats) {
    return Row(
      children: [
        _buildMiniStat(Icons.straighten, "Superficie",
            "${stats.areaHectares.toStringAsFixed(2)} ha"),
        const SizedBox(width: 16),
        _buildMiniStat(Icons.category, "Uso SIGPAC",
            widget.enclosure?.sigpacUse ?? "N/A"),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCards(EnclosureSummary stats) {
    return Column(
      children: [
        _buildActivityRow(
          Icons.notification_important,
          "Observaciones pendientes",
          "${stats.pendingObservations}",
          stats.pendingObservations > 0 ? Colors.orange : Colors.green,
        ),
        const SizedBox(height: 8),
        _buildActivityRow(
          Icons.event_available,
          "Último tratamiento",
          stats.lastTreatmentDate != null
              ? "${formatDate(stats.lastTreatmentDate)} (${stats.lastTreatmentProduct})"
              : "Sin registros",
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildActivityRow(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(OliveStatus status, EnclosureSummary stats) {
    final double percentage = (stats.statusPercentages[status] ?? 0.0) / 100;
    final int count = stats.statusCounts[status] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status.label),
              Text(
                "${stats.getFormattedPercentage(status)} ($count)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: status.color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Función auxiliar para mostrar el resumen.
void showEnclosureSummary(
    BuildContext context, List<Olive> olives, Enclosure? enclosure) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EnclosureSummaryModal(
      olives: olives,
      enclosure: enclosure,
    ),
  );
}
