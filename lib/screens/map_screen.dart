import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/utils/utils.dart';

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
              BaseMapView(
                controller: _mapController,
                initialCenter: LatLng(pos.latitude, pos.longitude),
                enclosure: enclosure,
                olives: olives,
                userLocation: LatLng(pos.latitude, pos.longitude),
                showOlives: _showOlives,
                onTap: (_, __) {
                  setState(() {
                    _selectedOlive = null;
                  });
                },
                onOliveTap: (olive) {
                  setState(() {
                    _selectedOlive = olive;
                  });
                },
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
