import 'package:flutter/material.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/utils/utils.dart';

class LivePositionScreen extends StatefulWidget {
  const LivePositionScreen({super.key});

  @override
  State<LivePositionScreen> createState() => _LivePositionScreenState();
}

class _LivePositionScreenState extends State<LivePositionScreen> {
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

  /// Escucha los cambios de ubicación y solicita la actualización del contexto en la base de datos.
  ///
  /// Invocada por: LocationService cada vez que cambia la posición.
  void _onLocationChanged() {
    final pos = LocationService.instance.currentPosition;
    if (pos != null) {
      DatabaseService.instance
          .updateLocationContext(pos.latitude, pos.longitude)
          .then((hasChanged) {
        if (hasChanged && mounted) setState(() {});
      });
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
              children: InfoSection.values
                  .map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: section.buildCard(pos, place),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
