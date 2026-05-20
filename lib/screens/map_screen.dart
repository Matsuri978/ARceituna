import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/utils/olive_info_card.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String? _lastEnclosureId;
  Olive? _selectedOlive;

  @override
  void initState() {
    super.initState();
    LocationService.instance.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: LocationService.instance,
        builder: (context, child) {
          final pos = LocationService.instance.currentPosition;
          
          if (pos == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Actualizamos la información de la base de datos de forma modular
          _updateDatabaseContext(pos.latitude, pos.longitude);

          final db = DatabaseService.instance;
          final enclosure = db.currentEnclosure;
          final olives = db.olives;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(pos.latitude, pos.longitude),
                  initialZoom: 18.0,
                  onTap: (_, __) {
                    setState(() {
                      _selectedOlive = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    // Usamos el servicio WMTS del IGN para evitar el error de bbox
                    urlTemplate:
                        'https://www.ign.es/wmts/pnoa-ma?layer=OI.OrthoimageCoverage&style=default&tilematrixset=GoogleMapsCompatible&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image/jpeg&TileMatrix={z}&TileCol={x}&TileRow={y}',
                    userAgentPackageName: 'com.example.tfg',
                  ),
                  if (enclosure != null && enclosure.coordinates.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: enclosure.coordinates
                              .map((c) => LatLng(c.latitude, c.longitude))
                              .toList(),
                          color: const Color.fromARGB(51, 250, 201, 3),
                          borderStrokeWidth: 3,
                          borderColor: const Color.fromARGB(255, 0, 255, 0),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      ...olives.map((olive) => Marker(
                            point: LatLng(olive.latitude, olive.longitude),
                            width: 40,
                            height: 40,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Sombras (simulando el efecto del Marker de posición)
                                    ...[
                                      const Offset(-1, -1),
                                      const Offset(1, -1),
                                      const Offset(1, 1),
                                      const Offset(-1, 1),
                                    ].map((offset) => Transform.translate(
                                          offset: offset,
                                          child: SvgPicture.asset(
                                            'assets/olive.svg',
                                            width: 30,
                                            height: 30,
                                            colorFilter: const ColorFilter.mode(
                                                Colors.black, BlendMode.srcIn),
                                          ),
                                        )),
                                    // Icono principal
                                    SvgPicture.asset(
                                      'assets/olive.svg',
                                      width: 30,
                                      height: 30,
                                      colorFilter: const ColorFilter.mode(
                                          Color.fromARGB(255, 35, 87, 23),
                                          BlendMode.srcIn),
                                    ),
                                  ],
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedOlive = olive;
                                });
                              },
                            ),
                          )),
                      Marker(
                        point: LatLng(pos.latitude, pos.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                          shadows: [
                            Shadow(offset: Offset(-1, -1), color: Colors.black),
                            Shadow(offset: Offset(1, -1), color: Colors.black),
                            Shadow(offset: Offset(1, 1), color: Colors.black),
                            Shadow(
                                offset: Offset(-1, 1), color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_selectedOlive != null)
                OliveInfoCard(
                  olive: _selectedOlive!,
                  onClose: () {
                    setState(() {
                      _selectedOlive = null;
                    });
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fitEnclosure,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }

  /// Función idéntica a LivePositionScreen para mantener la consistencia
  Future<void> _updateDatabaseContext(double lat, double lng) async {
    final db = DatabaseService.instance;

    // 1. Buscamos el recinto
    final enclosure = await db.fetchEnclosureByCoordinates(lat, lng);
    
    // Solo actuamos si el recinto ha cambiado
    if (enclosure != null) {
      if (enclosure.id != _lastEnclosureId) {
        setState(() {
          _lastEnclosureId = enclosure.id;
        });
        // Si el recinto es nuevo, ajustamos la cámara al polígono
        _fitEnclosure();
      }
    } else {
      // Si salimos de un recinto, limpiamos el estado
      if (_lastEnclosureId != null) {
        setState(() {
          _lastEnclosureId = null;
        });
      }
    }
  }

  void _fitEnclosure() {
    final enclosure = DatabaseService.instance.currentEnclosure;
    if (enclosure != null && enclosure.coordinates.isNotEmpty) {
      final long = LocationService.instance.currentPosition!.longitude;
      final lat = LocationService.instance.currentPosition!.latitude;
      
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(lat-0.001, long-0.001),
            LatLng(lat+0.001, long+0.001),
          ),
          padding: const EdgeInsets.all(5), // Menos padding para acercar más la cámara
        ),
      );
    }
  }
}
