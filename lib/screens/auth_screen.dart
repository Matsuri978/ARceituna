import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Solo para capturar AuthException

import 'package:arceituna/services/services.dart';
import 'package:arceituna/screens/screens.dart';
import 'package:arceituna/utils/utils.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;
  UserRole _selectedRole = UserRole.farmer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Gestiona el flujo de autenticación (Inicio de sesión o Registro).
  ///
  /// Invocada por: Botón principal de la pantalla de autenticación.
  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(context, 'Por favor, rellena todos los campos', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Delegamos el inicio de sesión al Singleton
        await AuthService.instance.signIn(email: email, password: password);
      } else {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          showMessage(
              context, 'Por favor, introduce tu nombre de usuario', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        // Delegamos el registro al Singleton
        await AuthService.instance.signUp(
          email: email,
          password: password,
          name: name,
          role: _selectedRole.dbValue, // Usamos dbValue para la base de datos
        );
      }

      // Si no ha saltado ningún error en el try, navegamos al Home
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!context.mounted) return;
      showMessage(context, error.message, isError: true);
    } catch (error) {
      if (!context.mounted) return;
      showMessage(context, 'Error: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // El metodo build() se queda exactamente igual que lo tenías,
    // ya que la UI no cambia, solo la lógica subyacente.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isLogin
                    ? 'Introduce tus datos para acceder al olivar'
                    : 'Regístrate para empezar a gestionar tus parcelas',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),

              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre y Apellidos',
                    prefixIcon: const Icon(Icons.person_outline),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Selecciona tu perfil',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  items: UserRole.registrationRoles.map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(role.label),
                    );
                  }).toList(),
                  onChanged: (UserRole? newValue) {
                    if (newValue != null) setState(() => _selectedRole = newValue);
                  },
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _emailController.clear();
                      _passwordController.clear();
                      _nameController.clear();
                    });
                  },
                  child: Text(
                    _isLogin
                        ? '¿No tienes cuenta? Regístrate aquí'
                        : '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                        color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Continuar como Invitado',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
