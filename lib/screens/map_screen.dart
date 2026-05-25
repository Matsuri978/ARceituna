import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/utils/utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _fabKey = GlobalKey<ExpandableFabState>();
  Olive? _selectedOlive;
  bool _showOlives = true;

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
      DatabaseService.instance
          .updateLocationContext(pos.latitude, pos.longitude)
          .then((hasChanged) {
        if (hasChanged && mounted) {
          _focusOnCurrentLocation();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([
          LocationService.instance,
          DatabaseService.instance,
        ]),
        builder: (context, child) {
          final pos = LocationService.instance.currentPosition;

          if (pos == null) {
            return const Center(child: CircularProgressIndicator());
          }

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
                      if (_showOlives)
                        ...olives.map((olive) => Marker(
                              point: LatLng(olive.location.latitude,
                                  olive.location.longitude),
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
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                      Colors.black,
                                                      BlendMode.srcIn),
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
                            Shadow(offset: Offset(-1, 1), color: Colors.black),
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _fabKey,
        type: ExpandableFabType.up,
        distance: 70,
        openButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          fabSize: ExpandableFabSize.regular,
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          fabSize: ExpandableFabSize.regular,
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        ),
        children: [
          FloatingActionButton(
            heroTag: "btn_focus",
            onPressed: () {
              _focusOnCurrentLocation();
              _fabKey.currentState?.toggle();
            },
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            child: const Icon(Icons.center_focus_strong, size: 30),
          ),
          FloatingActionButton(
            heroTag: "btn_visibility",
            onPressed: () {
              setState(() => _showOlives = !_showOlives);
              _fabKey.currentState?.toggle();
            },
            backgroundColor: Colors.green.shade700,
            child: SvgPicture.asset(
              'assets/olive.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                _showOlives ? Colors.white : Colors.red,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ajusta la cámara del mapa para encuadrar la posición actual con un margen de seguridad.
  ///
  /// Invocada por: Botón flotante y automáticamente al cambiar de recinto.
  void _focusOnCurrentLocation() {
    final pos = LocationService.instance.currentPosition;
    if (pos != null) {
      const double margin = 0.001;

      // Aseguramos que las coordenadas estén dentro de los límites terrestres (-90/90 y -180/180)
      final southWest = LatLng(
        (pos.latitude - margin).clamp(-90.0, 90.0),
        (pos.longitude - margin).clamp(-180.0, 180.0),
      );
      final northEast = LatLng(
        (pos.latitude + margin).clamp(-90.0, 90.0),
        (pos.longitude + margin).clamp(-180.0, 180.0),
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(southWest, northEast),
          padding: const EdgeInsets.all(5),
        ),
      );
    }
  }
}
