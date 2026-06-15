/// Implementación de un Filtro de Kalman Adaptativo de primer orden para suavizado de señales de sensores.
class KalmanFilter {
  final double _q; // Incertidumbre del proceso (Process Noise)
  final double _r; // Incertidumbre de la medida (Measurement Noise)
  double _p = 1.0; // Error de estimación (Estimation Error)
  double _x = 0.0; // Estado actual (Valor estimado)
  double _k = 0.0; // Ganancia de Kalman

  bool _isInitialized = false;

  /// Constructor del filtro.
  /// [processNoise] (Q): Qué tan rápido esperamos que cambie el valor real.
  /// [measurementNoise] (R): Qué tan ruidoso es el sensor (error típico).
  KalmanFilter({double processNoise = 0.01, double measurementNoise = 0.1})
      : _q = processNoise,
        _r = measurementNoise;



  /// Versión especializada para ángulos (0-360º) que maneja el salto del Norte.
  /// [customR] permite pasar un ruido de medida dinámico.
  double filterAngle(double measurement, {double? customR}) {
    if (!_isInitialized) {
      _x = measurement;
      _isInitialized = true;
      return _x;
    }

    double rToUse = customR ?? _r;

    // 1. Predicción
    _p = _p + _q;

    // 2. Cálculo de la diferencia mínima circular
    double diff = measurement - _x;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    // 3. Actualización
    _k = _p / (_p + rToUse);
    _x = (_x + _k * diff) % 360;
    if (_x < 0) _x += 360;
    
    _p = (1 - _k) * _p;

    return _x;
  }

  void reset() {
    _isInitialized = false;
    _p = 1.0;
  }
}
