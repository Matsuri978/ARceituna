import 'coordinate.dart';
import 'package:tfg/utils/utils.dart';

class Enclosure {
  final String id;
  final String cadastralRef;
  final String polygonNumber;
  final String enclosureNumber;
  final String sigpacUse;
  final List<Coordinate> coordinates;

  // Bounding Box (AABB) calculada una sola vez para optimización espacial
  late final Coordinate minBounds;
  late final Coordinate maxBounds;

  Enclosure({
    required this.id,
    required this.cadastralRef,
    required this.polygonNumber,
    required this.enclosureNumber,
    required this.sigpacUse,
    required this.coordinates,
  }) {
    _calculateBounds();
  }

  /// Calcula la caja delimitadora (Bounding Box) del polígono.
  void _calculateBounds() {
    if (coordinates.isEmpty) {
      minBounds = Coordinate(latitude: 0.0, longitude: 0.0);
      maxBounds = Coordinate(latitude: 0.0, longitude: 0.0);
      return;
    }

    double minLat = coordinates[0].latitude;
    double minLng = coordinates[0].longitude;
    double maxLat = coordinates[0].latitude;
    double maxLng = coordinates[0].longitude;

    for (var coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    minBounds = Coordinate(latitude: minLat, longitude: minLng);
    maxBounds = Coordinate(latitude: maxLat, longitude: maxLng);
  }

  /// Crea un objeto Enclosure a partir de un mapa de Supabase.
  factory Enclosure.fromMap(Map<String, dynamic> map) {
    List<Coordinate> coords = [];

    if (map['geom'] != null) {
      final geom = map['geom'];
      if (geom is Map && geom['coordinates'] != null) {
        var rawCoords = geom['coordinates'];

        if (geom['type'] == 'Polygon') {
          for (var point in rawCoords[0]) {
            coords.add(Coordinate(
              latitude: (point[1] as num).toDouble(),
              longitude: (point[0] as num).toDouble(),
            ));
          }
        } else if (geom['type'] == 'MultiPolygon') {
          for (var point in rawCoords[0][0]) {
            coords.add(Coordinate(
              latitude: (point[1] as num).toDouble(),
              longitude: (point[0] as num).toDouble(),
            ));
          }
        }
      }
    }

    return Enclosure(
      id: map['id_recinto_sigpac'] as String,
      cadastralRef: map['ref_catastral'] as String,
      polygonNumber: map['num_poligono']?.toString() ?? '',
      enclosureNumber: map['num_recinto']?.toString() ?? '',
      sigpacUse: map['uso_sigpac']?.toString() ?? '',
      coordinates: coords,
    );
  }

  /// Determina si un punto geográfico está dentro del recinto.
  /// Utiliza optimización por Bounding Box y Ray Casting.
  bool contains(double lat, double lng) {
    return isPointInPolygon(
      lat,
      lng,
      coordinates,
      min: minBounds,
      max: maxBounds,
    );
  }

  /// Convierte el objeto Enclosure a Map para Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id_recinto_sigpac': id,
      'ref_catastral': cadastralRef,
      'num_poligono': polygonNumber,
      'num_recinto': enclosureNumber,
      'uso_sigpac': sigpacUse,
    };
  }
}
