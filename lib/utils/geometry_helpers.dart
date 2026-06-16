import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/services/services.dart';

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

/// Calcula la distancia perpendicular de un punto a una línea definida por dos puntos.
double perpendicularDistance(Coordinate p, Coordinate start, Coordinate end) {
  double x = p.longitude;
  double y = p.latitude;
  double x1 = start.longitude;
  double y1 = start.latitude;
  double x2 = end.longitude;
  double y2 = end.latitude;

  if (x1 == x2 && y1 == y2) {
    return sqrt(pow(x - x1, 2) + pow(y - y1, 2));
  }

  double numerator = ((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1).abs();
  double denominator = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2));

  return numerator / denominator;
}

/// Implementación del algoritmo de Douglas-Peucker para la simplificación de polígonos.
/// Reduce el número de vértices manteniendo la forma geométrica esencial.
/// [epsilon]: Tolerancia de error (en grados). 0.00001 aprox. 1.1 metros.
List<Coordinate> douglasPeucker(List<Coordinate> points, double epsilon) {
  if (points.length < 3) return points;

  int maxIndex = 0;
  double maxDistance = 0.0;

  for (int i = 1; i < points.length - 1; i++) {
    double distance = perpendicularDistance(points[i], points[0], points.last);
    if (distance > maxDistance) {
      maxDistance = distance;
      maxIndex = i;
    }
  }

  if (maxDistance > epsilon) {
    List<Coordinate> firstHalf = douglasPeucker(points.sublist(0, maxIndex + 1), epsilon);
    List<Coordinate> secondHalf = douglasPeucker(points.sublist(maxIndex), epsilon);
    return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
  } else {
    return [points[0], points.last];
  }
}

/// Calcula el área de un polígono en metros cuadrados.
/// Utiliza la fórmula de Shoelace (cordón de zapato) proyectada.
double calculatePolygonArea(List<Coordinate> polygon) {
  if (polygon.length < 3) return 0.0;

  double area = 0.0;
  const double R = 6371000; // Radio de la Tierra en metros

  for (int i = 0; i < polygon.length; i++) {
    int j = (i + 1) % polygon.length;

    double latI = polygon[i].latitude * pi / 180;
    double lonI = polygon[i].longitude * pi / 180;
    double latJ = polygon[j].latitude * pi / 180;
    double lonJ = polygon[j].longitude * pi / 180;

    // Proyección simple equidistante para áreas pequeñas
    double xi = lonI * R * cos(latI);
    double yi = latI * R;
    double xj = lonJ * R * cos(latJ);
    double yj = latJ * R;

    area += (xi * yj) - (xj * yi);
  }

  return area.abs() / 2.0;
}
