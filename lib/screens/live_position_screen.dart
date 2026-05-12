import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tfg/services/services.dart';

class LivePositionScreen extends StatefulWidget {
  const LivePositionScreen({Key? key}) : super(key: key);

  @override
  State<LivePositionScreen> createState() => _LivePositionScreenState();
}

class _LivePositionScreenState extends State<LivePositionScreen> {
  String? _lastEnclosureId;

  @override
  void initState() {
    super.initState();
    LocationService.instance.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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

          // Actualizamos la información de la base de datos de forma modular
          _updateDatabaseContext(pos.latitude, pos.longitude);

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

  /// Función que llama a las peticiones de base de datos de forma secuencial
  Future<void> _updateDatabaseContext(double lat, double lng) async {
    final db = DatabaseService.instance;

    // 1. Buscamos el recinto
    final enclosure = await db.fetchEnclosureByCoordinates(lat, lng);
    
    // Optimizamos: solo realizamos las peticiones extra si el recinto ha cambiado
    if (enclosure != null) {
      if (enclosure.id != _lastEnclosureId) {
        _lastEnclosureId = enclosure.id;

        // 2. Buscamos la parcela usando la ref catastral del recinto
        await db.fetchParcelByRef(enclosure.cadastralRef);

        // 3. Buscamos el municipio usando el código de hoja de la parcela
        if (db.currentParcel != null) {
          await db.fetchMunicipalityBySheet(db.currentParcel!['codigo_hoja']);
        }

        // 4. Buscamos la provincia usando el código INE del municipio
        if (db.currentMunicipality != null) {
          await db.fetchProvinceByIne(db.currentMunicipality!['codigo_ine_prov']);
        }
        
        // Refrescamos la UI ya que han cambiado los datos de ubicación
        if (mounted) setState(() {});
      }
    } else {
      // Si salimos de un recinto, limpiamos el estado
      if (_lastEnclosureId != null) {
        _lastEnclosureId = null;
        db.currentParcel = null;
        db.currentMunicipality = null;
        db.currentProvince = null;
        db.olives = [];
        if (mounted) setState(() {});
      }
    }
  }
}

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
  final db = DatabaseService.instance;
  
  // Provincia: (Num_Prov) Nombre Provincia
  String? provinceText;
  if (db.currentProvince != null) {
    provinceText = "(${db.currentProvince!['codigo_ine_prov']}) ${db.currentProvince!['nombre']}";
  }

  // Ciudad: Nombre (Num_Mun)
  String? cityText = place?.locality;
  if (db.currentMunicipality != null) {
    cityText = "${db.currentMunicipality!['nombre']} (${db.currentMunicipality!['num_municipio']})";
  }

  return [
    _row("País", place?.country),
    _row("C. Autónoma", place?.administrativeArea),
    _row("Provincia", provinceText),
    _row("Municipio", cityText),
    _row("Calle", place?.street),
    _row("Edificio", place?.name),
    _row("Código postal", place?.postalCode),
    _row("Parcela", db.currentParcel?['num_parcela']?.toString()),
    // Recinto: (Num_Poligono) Numero de Recinto
    _row("Recinto", db.currentEnclosure != null 
        ? "(${db.currentEnclosure!.polygonNumber}) ${db.currentEnclosure!.enclosureNumber}"
        : null),
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
