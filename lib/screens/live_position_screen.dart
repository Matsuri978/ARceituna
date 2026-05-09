import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// IMPORTANTE: Pon la ruta correcta hacia tu nuevo servicio
import 'package:tfg/services/services.dart';

class LivePositionScreen extends StatefulWidget {
  const LivePositionScreen({Key? key}) : super(key: key);

  @override
  State<LivePositionScreen> createState() => _LivePositionScreenState();
}

class _LivePositionScreenState extends State<LivePositionScreen> {
  @override
  void initState() {
    super.initState();
    // Arrancamos el tracking al entrar en la pantalla
    LocationService.instance.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      // ListenableBuilder escucha al ChangeNotifier y se redibuja solo
      body: ListenableBuilder(
        listenable: LocationService.instance,
        builder: (context, child) {
          final pos = LocationService.instance.currentPosition;
          final place = LocationService.instance.currentPlace;
          final status = LocationService.instance.statusMessage;

          if (pos == null || place == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(status, style: const TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: InfoSection.values.map(
                    (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: section.buildCard(pos, place),
                ),
              ).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// SECCIÓN VISUAL (Sin cambios)
// ==========================================

enum InfoSection {
  coordinates(
    title: "Coordenadas",
    icon: Icons.location_searching,
    fieldsBuilder: _buildCoordinateFields,
  ),

  address(
    title: "Dirección",
    icon: Icons.location_on,
    fieldsBuilder: _buildAddressFields,
  );

  final String title;
  final IconData icon;
  final List<Widget> Function(Position?, Placemark?) fieldsBuilder;

  const InfoSection({
    required this.title,
    required this.icon,
    required this.fieldsBuilder,
  });

  Widget buildCard(Position? pos, Placemark? place) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...fieldsBuilder(pos, place),
          ],
        ),
      ),
    );
  }
}

List<Widget> _buildCoordinateFields(Position? pos, Placemark? place) {
  return [
    _row("Latitud", pos?.latitude.toStringAsFixed(6)),
    _row("Longitud", pos?.longitude.toStringAsFixed(6)),
    _row("Altitud", "${pos?.altitude.toStringAsFixed(2)} m"),
    _row("Precisión", "${pos?.accuracy.toStringAsFixed(2)} m"),
  ];
}

List<Widget> _buildAddressFields(Position? pos, Placemark? place) {
  return [
    _row("País", place?.country),
    _row("Comunidad Autónoma", place?.administrativeArea),
    _row("Ciudad", place?.locality),
    _row("Calle", place?.street),
    _row("Edificio", place?.name),
    _row("Código postal", place?.postalCode),
  ];
}

Widget _row(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value ?? "-"),
      ],
    ),
  );
}