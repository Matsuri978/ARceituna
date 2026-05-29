import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/utils/utils.dart';
import 'package:flutter_map/flutter_map.dart';

class AddOliveMapScreen extends StatefulWidget {
  const AddOliveMapScreen({super.key});

  @override
  State<AddOliveMapScreen> createState() => _AddOliveMapScreenState();
}

class _AddOliveMapScreenState extends State<AddOliveMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _tempPosition;
  Enclosure? _tempEnclosure;
  List<Olive> _existingOlives = [];
  bool _isLoading = false;

  Future<void> _handleMapTap(TapPosition tapPos, LatLng point) async {
    setState(() {
      _tempPosition = point;
      _isLoading = true;
    });

    try {
      final enclosure = await DatabaseService.instance
          .fetchEnclosureByCoordinates(point.latitude, point.longitude);

      if (enclosure == null) {
        if (mounted) {
          showMessage(context,
              'Esa ubicación no pertenece a ningún recinto registrado',
              isError: true);
        }
        setState(() {
          _tempPosition = null;
          _tempEnclosure = null;
          _existingOlives = [];
        });
      } else {
        // Cargar olivos existentes en ese recinto para que el usuario los vea
        final olives =
            await DatabaseService.instance.fetchOlivesByEnclosure(enclosure.id);

        setState(() {
          _tempEnclosure = enclosure;
          _existingOlives = olives;
        });
        if (mounted) {
          _showAddOliveDialog(point, enclosure);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddOliveDialog(LatLng point, Enclosure enclosure) {
    String selectedVariety = OliveVariety.picual.label;
    String selectedStatus = OliveStatus.healthy.label;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Olivo en Mapa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Recinto: ${enclosure.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedVariety,
                decoration: const InputDecoration(labelText: 'Variedad', border: OutlineInputBorder()),
                items: OliveVariety.labels.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setDialogState(() => selectedVariety = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Estado inicial', border: OutlineInputBorder()),
                items: OliveStatus.labels.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo
                _saveOlive(point, enclosure.id, selectedVariety, selectedStatus);
              },
              child: const Text('AÑADIR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOlive(LatLng point, String enclosureId, String variety, String status) async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService.instance.addOlive(
        variety: variety,
        healthStatus: status,
        lat: point.latitude,
        lng: point.longitude,
        enclosureId: enclosureId,
      );
      if (mounted) {
        showMessage(context, 'Olivo añadido correctamente', neutral: true);
        setState(() {
          _tempPosition = null;
          _tempEnclosure = null;
        });
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = LocationService.instance.currentPosition;
    final LatLng initialCenter = pos != null 
        ? LatLng(pos.latitude, pos.longitude) 
        : const LatLng(37.888, -4.777); // Córdoba por defecto si no hay GPS

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          BaseMapView(
            controller: _mapController,
            initialCenter: initialCenter,
            enclosure: _tempEnclosure, // Mostrar el recinto si se ha detectado uno
            olives: _existingOlives,
            userLocation:
                pos != null ? LatLng(pos.latitude, pos.longitude) : null,
            onTap: _handleMapTap,
            additionalMarkers: [
              if (_tempPosition != null)
                Marker(
                  point: _tempPosition!,
                  width: 50,
                  height: 50,
                  child:
                      const Icon(Icons.add_location, color: Colors.red, size: 50),
                ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withValues(alpha: 0.9),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(child: Text('Toca en el mapa para situar un nuevo olivo.')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
