import 'package:arceituna/models/models.dart';
import 'package:arceituna/utils/utils.dart';

/// Clase que calcula y encapsula las estadísticas de un recinto.
class EnclosureSummary {
  final List<Olive> olives;
  final List<Map<String, dynamic>> treatments;
  final List<Map<String, dynamic>> observations;
  final Enclosure? enclosure;

  late final int totalOlives;
  late final Map<OliveStatus, int> statusCounts;
  late final Map<OliveStatus, double> statusPercentages;
  late final Map<String, int> varietyCounts;

  // Nuevas estadísticas de actividad
  late final int pendingObservations;
  late final String? lastTreatmentDate;
  late final String? lastTreatmentProduct;
  late final double areaHectares;

  EnclosureSummary(
    this.olives, {
    this.treatments = const [],
    this.observations = const [],
    this.enclosure,
  }) {
    totalOlives = olives.length;
    _calculateStats();
    _calculateActivityStats();
    _calculateArea();
  }

  void _calculateStats() {
    statusCounts = {
      for (var status in OliveStatus.values) status: 0,
    };
    varietyCounts = {};

    if (totalOlives == 0) {
      statusPercentages = {
        for (var status in OliveStatus.values) status: 0.0,
      };
      return;
    }

    for (var olive in olives) {
      final status = OliveStatus.fromLabel(olive.healthStatus);
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      final varietyEnum = OliveVariety.fromLabel(olive.variety);
      final varietyLabel = varietyEnum?.label ?? olive.variety ?? 'Desconocida';
      varietyCounts[varietyLabel] = (varietyCounts[varietyLabel] ?? 0) + 1;
    }

    statusPercentages = statusCounts.map((status, count) {
      return MapEntry(status, (count / totalOlives) * 100);
    });
  }

  void _calculateActivityStats() {
    // Observaciones pendientes (Pendiente o En proceso)
    pendingObservations = observations.where((obs) {
      final status = obs['estado']?.toString().toLowerCase();
      return status == 'pendiente' || status == 'en proceso';
    }).length;

    // Último tratamiento
    if (treatments.isNotEmpty) {
      // Ya vienen ordenados por fecha descendente desde DatabaseService
      final last = treatments.first;
      lastTreatmentDate = last['fecha_tratamiento'];
      lastTreatmentProduct = last['producto'];
    } else {
      lastTreatmentDate = null;
      lastTreatmentProduct = null;
    }
  }

  void _calculateArea() {
    if (enclosure == null || enclosure!.coordinates.isEmpty) {
      areaHectares = 0.0;
      return;
    }
    // Calculamos el área en hectáreas
    areaHectares = calculatePolygonArea(enclosure!.coordinates) / 10000;
  }

  /// Devuelve el porcentaje formateado como string para un estado.
  String getFormattedPercentage(OliveStatus status) {
    return "${statusPercentages[status]?.toStringAsFixed(1) ?? '0.0'}%";
  }
}
