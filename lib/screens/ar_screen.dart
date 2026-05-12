import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tfg/services/services.dart';
import 'package:tfg/models/models.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool showInfoCard = false;
  bool planeFound = false;

  Olive? _selectedOlive;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  void _resetUI() {
    setState(() {
      showInfoCard = false;
      planeFound = false;
      _selectedOlive = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          viewCard(),
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      dynamic anchorManager,
      ARLocationManager locationManager,
      ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: false,
      showAnimatedGuide: true,
      handleTaps: false,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneDetected = (plane) async {
      if (planeFound) return;

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

        // Buscamos el olivo más cercano de los cargados en el servicio
        Olive? oliveFound = _getClosestOlive(position);

        if (oliveFound != null) {
          setState(() {
            planeFound = true;
            _selectedOlive = oliveFound;
            showInfoCard = true;
          });
        }
      } catch (e) {
        debugPrint("Error obteniendo GPS: $e");
      }
    };
  }

  Olive? _getClosestOlive(Position currentPos) {
    final olives = DatabaseService.instance.olives;
    if (olives.isEmpty) return null;

    Olive? closest;
    double minDistance = 10.0; // metros

    for (var olive in olives) {
      double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        olive.latitude,
        olive.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closest = olive;
      }
    }
    return closest;
  }

  Widget viewCard() {
    if (showInfoCard && _selectedOlive != null) {
      // De momento usamos lógica simple para el estado crítico
      bool isCritical = _selectedOlive!.healthStatus == 'Enfermo';
      Color statusColor = isCritical ? Colors.red : Colors.green;
      String statusText = isCritical ? "ATENCIÓN REQUERIDA" : "ESTADO ÓPTIMO";

      return Positioned(
        bottom: 30, left: 20, right: 20,
        child: Card(
          elevation: 10,
          color: Colors.white.withValues(alpha: 0.98),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: statusColor, width: 2)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      avatar: Icon(Icons.park, color: statusColor),
                      label: Text("${_selectedOlive!.id}: $statusText", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                    CloseButton(onPressed: _resetUI),
                  ],
                ),
                const Divider(),

                _buildRowInfo("Variedad:", _selectedOlive!.variety ?? "Desconocida"),
                _buildRowInfo("Estado:", _selectedOlive!.healthStatus ?? "Normal"),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.history, size: 16, color: Colors.blue),
                          SizedBox(width: 5),
                          Text("Gestión de Olivo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Consulta el historial para ver tratamientos y observaciones."),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 35,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                          onPressed: () => _showHistoryDialog(context),
                          icon: const Icon(Icons.list_alt, size: 18, color: Colors.white),
                          label: const Text("Ver Historial", style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Registrar Observación/Tratamiento"),
                    onPressed: () {
                      // Aquí iría la lógica para abrir un formulario de registro
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } else {
      return _buildScanningMessage();
    }
  }

  Widget _buildRowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanningMessage() {
    return Positioned(
      top: 20, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
          child: const Text("Buscando olivo cercano...", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    // Diálogo para mostrar tratamientos y observaciones
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Historial Olivo ${_selectedOlive!.id}"),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder(
              future: Future.wait([
                DatabaseService.instance.getTreatmentsByOlive(_selectedOlive!.id),
                DatabaseService.instance.getObservationsByOlive(_selectedOlive!.id),
              ]),
              builder: (context, AsyncSnapshot<List<List<Map<String, dynamic>>>> snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final treatments = snapshot.data![0];
                final observations = snapshot.data![1];

                return ListView(
                  shrinkWrap: true,
                  children: [
                    const Text("Tratamientos:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...treatments.map((t) => ListTile(
                      title: Text(t['producto'] ?? 'Tratamiento'),
                      subtitle: Text(t['fecha_treatment'] ?? ''),
                    )),
                    const Divider(),
                    const Text("Observaciones:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...observations.map((o) => ListTile(
                      title: Text(o['tipo_observacion'] ?? 'Obs'),
                      subtitle: Text(o['descripcion'] ?? ''),
                    )),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
          ],
        );
      },
    );
  }
}
