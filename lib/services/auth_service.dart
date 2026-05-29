import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arceituna/utils/utils.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  static AuthService get instance => _instance;

  final _supabase = Supabase.instance.client;

  UserRole _role = UserRole.guest;

  /// Devuelve el rol actual como un Enum.
  UserRole get currentRole => _role;

  // ==========================================
  // LÓGICA DE NEGOCIO
  // ==========================================

  /// Obtiene el usuario actual si hay sesión iniciada, o null.
  User? get currentUser => _supabase.auth.currentUser;

  /// Inicia sesión con correo y contraseña.
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Registra un nuevo usuario y guarda su rol en la tabla 'perfiles'.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name},
    );

    final user = res.user;

    if (user != null) {
      await _supabase.from('perfiles').insert({
        'id': user.id,
        'rol': role, // Pasamos el dbValue que viene de AuthScreen
      });
      _role = UserRole.fromString(role);
    }
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _role = UserRole.guest;
  }

  /// Obtiene el rol de un usuario desde la tabla 'perfiles'.
  Future<UserRole> getRole(String userId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', userId)
          .single();
      _role = UserRole.fromString(response['rol'] as String);
    } catch (e) {
      _role = UserRole.guest;
    }
    return _role;
  }

  /// Comprueba si el usuario actual tiene un permiso específico.
  bool hasPermission(bool Function(UserRole) check) {
    return check(_role);
  }
}
