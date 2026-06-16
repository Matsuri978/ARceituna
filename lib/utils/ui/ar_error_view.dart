import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arceituna/utils/utils.dart';

class ARErrorView extends StatelessWidget {
  final ARStatus status;
  final String errorMessage;
  final VoidCallback onRetry;

  const ARErrorView({
    super.key,
    required this.status,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == ARStatus.permissionDenied
                  ? Icons.camera_enhance_outlined
                  : Icons.videocam_off_outlined,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "Cámara no disponible",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (status == ARStatus.permissionDenied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text("Abrir Ajustes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Reintentar"),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
