import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:arceituna/utils/utils.dart';

class LocationService extends ChangeNotifier {
  // ==========================================
  // PATRÓN SINGLETON (Igual que en AuthService)
  // ==========================================
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  static LocationService get instance => _instance;

  // ==========================================
  // ESTADO Y VARIABLES
  // ==========================================
  Position? _currentPosition;
  Placemark? _currentPlace;
  double? _currentHeading;
  String _statusMessage = 'Inicializando...';
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Filtros de Kalman para suavizar señales
  final KalmanFilter _headingFilter = KalmanFilter(processNoise: 0.1); 

  // Variables para el cálculo dinámico de R en la brújula
  final List<double> _compassHistory = [];
  static const int _historyLimit = 10;

  // Getters para acceder desde la UI
  Position? get currentPosition => _currentPosition;
  Placemark? get currentPlace => _currentPlace;
  double? get currentHeading => _currentHeading;
  String get statusMessage => _statusMessage;

  // ==========================================
  // MÉTODOS DE NEGOCIO (LÓGICA)
  // ==========================================

  /// Inicia el rastreo de la ubicación en tiempo real.
  ///
  /// Verifica permisos y actualiza la posición y dirección (geocoding).
  ///
  /// Invocada por: LivePositionScreen y MapScreen al inicializarse.
  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusMessage = 'El servicio de ubicación está desactivado.';
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _statusMessage = 'Permiso de ubicación denegado.';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _statusMessage = 'Permiso de ubicación denegado permanentemente.';
      notifyListeners();
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _currentPlace = placemarks.first;
      } catch (e) {
        _currentPlace = null;
      }


      _currentPosition = Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        accuracy: position.accuracy,
        altitude: position.altitude,
        altitudeAccuracy: position.altitudeAccuracy,
        heading: position.heading,
        headingAccuracy: position.headingAccuracy,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
      );
      
      _statusMessage = 'Ubicación actualizada';

      // Avisa a ListenableBuilder para que redibuje la pantalla
      notifyListeners();
    });

    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        // Cálculo de R dinámico para brújula basado en la estabilidad reciente
        _compassHistory.add(event.heading!);
        if (_compassHistory.length > _historyLimit) _compassHistory.removeAt(0);
        
        double dynamicR = _calculateCompassVariance();
        
        _currentHeading = _headingFilter.filterAngle(event.heading!, customR: dynamicR);
        notifyListeners();
      }
    });
  }

  /// Calcula la varianza de las últimas lecturas de la brújula para auto-ajustar el filtro.
  double _calculateCompassVariance() {
    if (_compassHistory.length < 2) return 4.0; 
    
    double mean = _compassHistory.reduce((a, b) => a + b) / _compassHistory.length;
    double variance = _compassHistory.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / _compassHistory.length;
    
    return variance.clamp(1.0, 20.0);
  }

  /// Detiene el rastreo de la ubicación y cancela la suscripción al flujo de posiciones.
  ///
  /// Invocada por: Componentes que ya no requieran actualizaciones de ubicación.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }
}
