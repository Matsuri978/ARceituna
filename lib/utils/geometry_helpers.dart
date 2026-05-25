import 'package:geolocator/geolocator.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/services/services.dart';

// ==========================================
// CONSTANTES DE AR / DETECCIÓN
// ==========================================
const double oliveDetectionRadius = 5.0; // metros
const double oliveFovDegrees = 30.0; // Grados de apertura del visor

/// Comprueba si un punto (lat, lng) está dentro de un polígono definido por una lista de coordenadas.
/// Implementación robusta de Ray Casting usando 3 rayos para evitar anomalías en vértices o aristas.
bool isPointInPolygon(double lat, double lng, List<Coordinate> polygon,
    {Coordinate? min, Coordinate? max}) {
  if (polygon.isEmpty) return false;

  if (min != null && max != null) {
    if (lat < min.latitude ||
        lat > max.latitude ||
        lng < min.longitude ||
        lng > max.longitude) {
      return false;
    }
  }

  bool horizontalInside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    if (((polygon[i].latitude > lat) != (polygon[j].latitude > lat)) &&
        (lng < (polygon[j].longitude - polygon[i].longitude) * (lat - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
      horizontalInside = !horizontalInside;
    }
  }

  bool verticalInside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    if (((polygon[i].longitude > lng) != (polygon[j].longitude > lng)) &&
        (lat < (polygon[j].latitude - polygon[i].latitude) * (lng - polygon[i].longitude) / (polygon[j].longitude - polygon[i].longitude) + polygon[i].latitude)) {
      verticalInside = !verticalInside;
    }
  }

  if (horizontalInside == verticalInside) return horizontalInside;

  bool diagonalInside = false;
  for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    double pointSum = lat + lng;
    double piSum = polygon[i].latitude + polygon[i].longitude;
    double pjSum = polygon[j].latitude + polygon[j].longitude;

    if (((piSum > pointSum) != (pjSum > pointSum)) &&
        (lat - lng < (polygon[j].latitude - polygon[j].longitude - (polygon[i].latitude - polygon[i].longitude)) * 
        (pointSum - piSum) / (pjSum - piSum) + (polygon[i].latitude - polygon[i].longitude))) {
      diagonalInside = !diagonalInside;
    }
  }

  return diagonalInside;
}

/// Busca el olivo más cercano a la posición actual que esté dentro del campo de visión.
Olive? getOliveInSight(Position currentPos, double? heading) {
  final olives = DatabaseService.instance.olives;
  if (olives.isEmpty || heading == null) return null;

  Olive? closest;
  double minDistance = oliveDetectionRadius;

  for (var olive in olives) {
    double distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      olive.location.latitude,
      olive.location.longitude,
    );

    if (distance < minDistance) {
      double bearing = Geolocator.bearingBetween(
        currentPos.latitude,
        currentPos.longitude,
        olive.location.latitude,
        olive.location.longitude,
      );

      double bearing360 = (bearing + 360) % 360;

      if (isWithinFOV(heading, bearing360, oliveFovDegrees)) {
        minDistance = distance;
        closest = olive;
      }
    }
  }
  return closest;
}

/// Determina si un bearing está dentro del rango de visión respecto al heading actual.
bool isWithinFOV(double heading, double bearing, double fov) {
  double diff = (bearing - heading).abs();
  if (diff > 180) diff = 360 - diff;
  return diff <= (fov / 2);
}
