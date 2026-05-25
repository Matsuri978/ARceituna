import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tfg/models/models.dart';
import 'package:tfg/services/services.dart';


class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ==========================================
  // ESTADO LOCAL (CACHE)
  // ==========================================
  List<Olive> olives = [];
  Enclosure? currentEnclosure;
  Map<String, dynamic>? currentParcel;
  Map<String, dynamic>? currentMunicipality;
  Map<String, dynamic>? currentProvince;

  // Optimización: Guardar la última posición de búsqueda para evitar spam fuera de recintos
  Position? _lastSearchPosition;
  static const double _minDistanceForNewSearch = 10.0; // metros

  // ==========================================
  // OLIVOS
  // ==========================================

  /// Obtiene y actualiza la lista local de olivos para un recinto específico.
  ///
  /// Invocada por: updateLocationContext cuando cambia el recinto.
  Future<void> _updateOlivesByEnclosure(String enclosureId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('olivos')
          .select()
          .eq('id_recinto_sigpac', enclosureId);

      olives = response.map((json) => Olive.fromMap(json)).toList();
      notifyListeners();
    } catch (e) {
      olives = [];
      notifyListeners();
    }
  }

  // ==========================================
  // RECINTOS Y UBICACIÓN (MODULAR)
  // ==========================================

  /// Obtiene el recinto por coordenadas llamando a la función RPC de Postgres.
  ///
  /// Invocada por: updateLocationContext.
  Future<Enclosure?> _fetchEnclosureByCoordinates(double lat, double lng) async {
    try {
      // Llamamos a la función RPC creada en Supabase (get_enclosure_by_point)
      final response = await _supabase.rpc('get_enclosure_by_point', params: {
        'lng_param': lng,
        'lat_param': lat,
      }).maybeSingle();

      if (response != null) {
        return Enclosure.fromMap(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Metodo de conveniencia para actualizar todoo el contexto de ubicación (Recinto, Parcela, Municipio, Provincia).
  ///
  /// Devuelve true si el recinto ha cambiado, permitiendo a la UI reaccionar.
  ///
  /// Invocada por: LivePositionScreen y MapScreen en cada cambio de ubicación detectado.
  Future<bool> updateLocationContext(double lat, double lng) async {
    try {
      // 1. COMPROBACIÓN LOCAL (Algoritmo Ray Casting)
      // Si ya tenemos un recinto, comprobamos matemáticamente si seguimos dentro.
      if (currentEnclosure != null && currentEnclosure!.coordinates.isNotEmpty) {
        if (currentEnclosure!.contains(lat, lng)) {
          return false; // Seguimos dentro, optimizamos evitando la petición a la DB.
        }
      }

      // 2. CONTROL DE FLUJO (Cooldown por distancia)
      // Si estamos fuera de un recinto, solo buscamos uno nuevo si nos hemos movido 
      // una distancia significativa (10m) desde la última búsqueda fallida.
      if (currentEnclosure == null && _lastSearchPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastSearchPosition!.latitude,
          _lastSearchPosition!.longitude,
          lat,
          lng,
        );
        if (distance < _minDistanceForNewSearch) {
          return false; 
        }
      }

      // 3. PETICIÓN A BASE DE DATOS (Solo si las comprobaciones anteriores fallan)
      _lastSearchPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final enclosure = await _fetchEnclosureByCoordinates(lat, lng);

      if (enclosure == null) {
        if (currentEnclosure != null) {
          currentEnclosure = null;
          currentParcel = null;
          currentMunicipality = null;
          currentProvince = null;
          olives = [];
          notifyListeners();
          return true; // Cambio de "estar dentro" a "estar fuera"
        }
        return false;
      }

      // El recinto ha cambiado, actualizamos todoo
      currentEnclosure = enclosure;
      await _updateOlivesByEnclosure(enclosure.id);
      await fetchParcelByRef(enclosure.cadastralRef);

      if (currentParcel != null) {
        await fetchMunicipalityBySheet(currentParcel!['codigo_hoja']);
      }

      if (currentMunicipality != null) {
        await fetchProvinceByIne(currentMunicipality!['codigo_ine_prov']);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la parcela usando la referencia catastral del recinto.
  ///
  /// Invocada por: updateLocationContext.
  Future<void> fetchParcelByRef(String cadastralRef) async {
    try {
      currentParcel = await _supabase
          .from('parcelas')
          .select()
          .eq('ref_catastral', cadastralRef)
          .maybeSingle();
      notifyListeners();
    } catch (e) {
      currentParcel = null;
      notifyListeners();
    }
  }

  /// Obtiene el municipio usando el código de hoja de la parcela.
  ///
  /// Invocada por: updateLocationContext.
  Future<void> fetchMunicipalityBySheet(String sheetCode) async {
    try {
      currentMunicipality = await _supabase
          .from('municipios')
          .select()
          .eq('codigo_hoja', sheetCode)
          .maybeSingle();
      notifyListeners();
    } catch (e) {
      currentMunicipality = null;
      notifyListeners();
    }
  }

  /// Obtiene la provincia usando el código INE del municipio.
  ///
  /// Invocada por: updateLocationContext.
  Future<void> fetchProvinceByIne(String ineCode) async {
    try {
      currentProvince = await _supabase
          .from('provincias')
          .select()
          .eq('codigo_ine_prov', ineCode)
          .maybeSingle();
      notifyListeners();
    } catch (e) {
      currentProvince = null;
      notifyListeners();
    }
  }

  /// Actualiza el estado de salud de un olivo en la base de datos y en la caché local.
  ///
  /// Invocada por: Componentes que gestionen el estado de los olivos.
  Future<void> updateOliveStatus(int oliveId, String newStatus) async {
    try {
      await _supabase
          .from('olivos')
          .update({'estado_salud': newStatus}).eq('cod_olivo', oliveId);

      // Actualizar caché local
      final index = olives.indexWhere((o) => o.id == oliveId);
      if (index != -1) {
        final old = olives[index];
        olives[index] = Olive(
          id: old.id,
          enclosureId: old.enclosureId,
          variety: old.variety,
          healthStatus: newStatus,
          location: old.location,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Registra un nuevo olivo en la base de datos usando el contexto actual.
  ///
  /// Invocada por: DevAddOliveScreen.
  Future<void> addOlive({
    required String variety,
    required String healthStatus,
  }) async {
    try {
      final pos = LocationService.instance.currentPosition;
      final enclosure = currentEnclosure;

      if (pos == null || enclosure == null) {
        throw Exception('Falta ubicación o recinto');
      }

      await _supabase.from('olivos').insert({
        'id_recinto_sigpac': enclosure.id,
        'variedad': variety,
        'estado_salud': healthStatus,
        'geom': 'POINT(${pos.longitude} ${pos.latitude})',
      });

      // Refrescar la lista local de olivos para incluir el nuevo
      await _updateOlivesByEnclosure(enclosure.id);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // REGISTROS (Tratamientos y Observaciones)
  // ==========================================

  /// Obtiene el historial de tratamientos de un olivo específico.
  ///
  /// Invocada por: OliveHistoryScreen (_loadData).
  Future<List<Map<String, dynamic>>> getTreatmentsByOlive(int oliveId) async {
    try {
      return await _supabase
          .from('registro_tratamientos')
          .select()
          .eq('cod_olivo', oliveId)
          .order('fecha_tratamiento', ascending: false);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene el historial de observaciones de un olivo específico.
  ///
  /// Invocada por: OliveHistoryScreen (_loadData).
  Future<List<Map<String, dynamic>>> getObservationsByOlive(int oliveId) async {
    try {
      return await _supabase
          .from('registro_observaciones')
          .select()
          .eq('cod_olivo', oliveId)
          .order('fecha_observacion', ascending: false);
    } catch (e) {
      return [];
    }
  }

  /// Registra un nuevo tratamiento para un olivo.
  ///
  /// Invocada por: RegisterActionScreen.
  Future<void> addTreatment({
    required int oliveId,
    required String product,
    required String dose,
    required DateTime date,
  }) async {
    try {
      await _supabase.from('registro_tratamientos').insert({
        'cod_olivo': oliveId,
        'producto': product,
        'dosis': dose,
        'fecha_tratamiento': date.toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Registra una nueva observación para un olivo.
  ///
  /// Invocada por: RegisterActionScreen.
  Future<void> addObservation({
    required int oliveId,
    required String type,
    required String status,
    required String description,
    required DateTime date,
  }) async {
    try {
      await _supabase.from('registro_observaciones').insert({
        'cod_olivo': oliveId,
        'tipo_observacion': type,
        'estado': status,
        'descripcion': description,
        'fecha_observacion': date.toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
