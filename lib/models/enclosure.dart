import 'coordinate.dart';

class Enclosure {
  final String id;
  final String cadastralRef;
  final String polygonNumber;
  final String enclosureNumber;
  final String sigpacUse;
  final List<Coordinate> coordinates;

  Enclosure({
    required this.id,
    required this.cadastralRef,
    required this.polygonNumber,
    required this.enclosureNumber,
    required this.sigpacUse,
    required this.coordinates,
  });

  factory Enclosure.fromMap(Map<String, dynamic> map) {
    List<Coordinate> coords = [];

    if (map['geom'] != null) {
      final geom = map['geom'];
      // Si el geom viene como GeoJSON (Polygon o MultiPolygon)
      if (geom is Map && geom['coordinates'] != null) {
        var rawCoords = geom['coordinates'];

        // Si es Polygon: [[[lng, lat], [lng, lat], ...]]
        if (geom['type'] == 'Polygon') {
          for (var point in rawCoords[0]) {
            coords.add(Coordinate(
              latitude: (point[1] as num).toDouble(),
              longitude: (point[0] as num).toDouble(),
            ));
          }
        }
        // Si es MultiPolygon (cogemos el primer polígono por simplicidad)
        else if (geom['type'] == 'MultiPolygon') {
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
      polygonNumber: map['num_poligono'] as String,
      enclosureNumber: map['num_recinto'] as String,
      sigpacUse: map['uso_sigpac'] as String,
      coordinates: coords,
    );
  }

  /// Devuelve el punto mínimo del polígono como un objeto Coordinate
  Coordinate get minBounds {
    if (coordinates.isEmpty) return Coordinate(latitude: 0.0, longitude: 0.0);
    double minLat = coordinates[0].latitude;
    double minLng = coordinates[0].longitude;

    for (var coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
    }
    return Coordinate(latitude: minLat, longitude: minLng);
  }

  /// Devuelve el punto máximo del polígono como un objeto Coordinate
  Coordinate get maxBounds {
    if (coordinates.isEmpty) return Coordinate(latitude: 0.0, longitude: 0.0);
    double maxLat = coordinates[0].latitude;
    double maxLng = coordinates[0].longitude;

    for (var coord in coordinates) {
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }
    return Coordinate(latitude: maxLat, longitude: maxLng);
  }

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
