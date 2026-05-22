import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/utils/utils.dart';

class DevAddOliveScreen extends StatefulWidget {
  const DevAddOliveScreen({super.key});

  @override
  State<DevAddOliveScreen> createState() => _DevAddOliveScreenState();
}

class _DevAddOliveScreenState extends State<DevAddOliveScreen> {
  String _selectedVariety = OliveVariety.picual.label;
  String _selectedStatus = OliveStatus.healthy.label;
  bool _isSaving = false;

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
          .updateLocationContext(pos.latitude, pos.longitude);
    }
  }

  Future<void> _registerOlive() async {
    setState(() => _isSaving = true);

    try {
      await DatabaseService.instance.addOlive(
        variety: _selectedVariety,
        healthStatus: _selectedStatus,
      );
      if (mounted) {
        showMessage(context, 'Olivo registrado con éxito', neutral: true);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error al registrar: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          LocationService.instance,
          DatabaseService.instance,
        ]),
        builder: (context, child) {
          final pos = LocationService.instance.currentPosition;
          final enclosure = DatabaseService.instance.currentEnclosure;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.add_location_alt, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Añadir Nuevo Olivo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  '(Herramienta de Desarrollo)',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 24),
                _buildContextInfo(pos, enclosure),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving || pos == null || enclosure == null ? null : _registerOlive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('REGISTRAR OLIVO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedVariety,
              decoration: const InputDecoration(
                labelText: 'Variedad de Olivo',
                prefixIcon: Icon(Icons.eco),
                border: OutlineInputBorder(),
              ),
              items: OliveVariety.labels.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (val) => setState(() => _selectedVariety = val!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Estado de Salud inicial',
                prefixIcon: Icon(Icons.health_and_safety),
                border: OutlineInputBorder(),
              ),
              items: OliveStatus.labels.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextInfo(Position? pos, Enclosure? enclosure) {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text(
                  'Datos de ubicación automática',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
            const Divider(),
            infoRow('Recinto SIGPAC', enclosure?.id ?? 'FUERA DE RECINTO', 
                     isBetween: true, 
                     labelColor: enclosure == null ? Colors.red : null),
            infoRow('Longitud', pos?.longitude.toStringAsFixed(6) ?? 'Buscando...', isBetween: true),
            infoRow('Latitud', pos?.latitude.toStringAsFixed(6) ?? 'Buscando...', isBetween: true),
          ],
        ),
      ),
    );
  }
}
