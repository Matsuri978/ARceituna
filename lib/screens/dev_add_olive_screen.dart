import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/utils/utils.dart';
import 'package:arceituna/screens/screens.dart';

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
                const Icon(Icons.add_location_alt,
                    size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Añadir Olivo',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Cómo quieres añadir el olivo?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // OPCIÓN 1: GPS ACTUAL
                _buildMethodCard(
                  title: 'Usar mi ubicación actual',
                  subtitle: 'El olivo se situará donde estés ahora mismo.',
                  icon: Icons.gps_fixed,
                  color: Colors.blue,
                  onTap: () {
                    // Ya estamos en la pantalla que lo hace por defecto
                  },
                  isSelected: true,
                ),

                const SizedBox(height: 16),

                // OPCIÓN 2: SELECCIONAR EN MAPA
                _buildMethodCard(
                  title: 'Seleccionar en el mapa',
                  subtitle: 'Toca en el mapa para indicar la posición exacta.',
                  icon: Icons.map,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddOliveMapScreen()),
                    );
                  },
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Datos para ubicación GPS actual:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildForm(),
                const SizedBox(height: 24),
                _buildContextInfo(pos, enclosure),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving || pos == null || enclosure == null
                      ? null
                      : _registerOlive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('REGISTRAR CON GPS',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color)
            else
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
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
              value: _selectedVariety,
              decoration: const InputDecoration(
                labelText: 'Variedad de Olivo',
                prefixIcon: Icon(Icons.eco),
                border: OutlineInputBorder(),
              ),
              items: OliveVariety.labels
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedVariety = val!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Estado de Salud inicial',
                prefixIcon: Icon(Icons.health_and_safety),
                border: OutlineInputBorder(),
              ),
              items: OliveStatus.labels
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800),
                ),
              ],
            ),
            const Divider(),
            infoRow('Recinto SIGPAC', enclosure?.id ?? 'FUERA DE RECINTO',
                isBetween: true,
                labelColor: enclosure == null ? Colors.red : null),
            infoRow('Longitud', pos?.longitude.toStringAsFixed(6) ?? 'Buscando...',
                isBetween: true),
            infoRow('Latitud', pos?.latitude.toStringAsFixed(6) ?? 'Buscando...',
                isBetween: true),
          ],
        ),
      ),
    );
  }
}
