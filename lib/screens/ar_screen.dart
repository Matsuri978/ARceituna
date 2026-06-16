import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:arceituna/services/services.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/utils/utils.dart';

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  ARStatus _status = ARStatus.initializing;
  String _errorMessage = "";

  bool showInfoCard = false;
  bool planeFound = false;

  Olive? _selectedOlive;

  @override
  void initState() {
    super.initState();
    _checkARAvailability();
  }

  /// Verifica permisos y compatibilidad de hardware antes de iniciar la vista AR.
  Future<void> _checkARAvailability() async {
    setState(() => _status = ARStatus.initializing);

    try {
      // 1. Comprobar permisos de cámara
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isPermanentlyDenied) {
        setState(() {
          _status = ARStatus.permissionDenied;
          _errorMessage = "El acceso a la cámara está bloqueado en los ajustes.";
        });
        return;
      }

      if (!status.isGranted) {
        setState(() {
          _status = ARStatus.permissionDenied;
          _errorMessage = "Se requiere permiso de cámara para usar la Realidad Aumentada.";
        });
        return;
      }

      // 2. Iniciar servicios de ubicación (necesarios para el escaneo)
      LocationService.instance.startTracking();
      LocationService.instance.addListener(_checkScanning);

      // 3. Esta correcto
      setState(() => _status = ARStatus.ready);
      
    } catch (e) {
      setState(() {
        _status = ARStatus.cameraDisabled;
        _errorMessage = "Error al acceder al hardware de la cámara.";
      });
    }
  }

  @override
  void dispose() {
    LocationService.instance.removeListener(_checkScanning);
    arSessionManager?.dispose();
    super.dispose();
  }

  /// Escanea constantemente la posición y orientación para detectar olivos cercanos.
  /// Independiente de la detección de planos de ARCore/ARKit.
  void _checkScanning() {
    if (showInfoCard || planeFound || _status != ARStatus.ready) return;

    final pos = LocationService.instance.currentPosition;
    final heading = LocationService.instance.currentHeading;

    if (pos != null && heading != null) {
      try {
        Olive? oliveFound = getOliveInSight(pos, heading);

        if (oliveFound != null) {
          setState(() {
            planeFound = true;
            _selectedOlive = oliveFound;
            showInfoCard = true;
          });
        }
      } catch (e) {
        // Error silenciado
      }
    }
  }

  /// Reinicia los estados de la interfaz AR.
  ///
  /// Invocada por: Cierre de la tarjeta de información del olivo.
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
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case ARStatus.initializing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text("Inicializando cámara...", style: TextStyle(color: Colors.white)),
            ],
          ),
        );

      case ARStatus.permissionDenied:
      case ARStatus.cameraDisabled:
      case ARStatus.unsupported:
        return ARErrorView(
          status: _status,
          errorMessage: _errorMessage,
          onRetry: _checkARAvailability,
        );

      case ARStatus.ready:
        return Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
            viewCard(),
          ],
        );
    }
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
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      showAnimatedGuide: false,
      handleTaps: false,
    );

    arObjectManager!.onInitialize();
    arSessionManager!.onPlaneDetected = (plane) {};
  }

  /// Decide qué componente mostrar sobre la vista AR (tarjeta de info o mensaje de escaneo).
  ///
  /// Invocada por: build() de ARScreen.
  Widget viewCard() {
    if (showInfoCard && _selectedOlive != null) {
      return OliveInfoCard(
        olive: _selectedOlive!,
        onClose: _resetUI,
      );
    } else {
      return _buildScanningMessage();
    }
  }

  /// Construye el mensaje flotante que indica que se está buscando un olivo.
  ///
  /// Invocada por: viewCard().
  Widget _buildScanningMessage() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(30)),
          child: const Text("Apunta hacia un olivo cercano...",
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
