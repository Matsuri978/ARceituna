class Coordinate {
  final double latitude;
  final double longitude;

  Coordinate({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'Coordinate(lat: $latitude, lng: $longitude)';
}
