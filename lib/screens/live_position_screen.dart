import 'package:flutter/material.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/utils/utils.dart';

class LivePositionScreen extends StatefulWidget {
  const LivePositionScreen({super.key});

  @override
  State<LivePositionScreen> createState() => _LivePositionScreenState();
}

class _LivePositionScreenState extends State<LivePositionScreen> {
  String? _lastEnclosureId;

  @override
  void initState() {
    super.initState();
    LocationService.instance.startTracking();
    LocationService.instance.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    LocationService.instance.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    final pos = LocationService.instance.currentPosition;
    if (pos != null) {
      _updateDatabaseContext(pos.latitude, pos.longitude);
    }
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
