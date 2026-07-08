import 'package:flutter/material.dart';
import 'package:arceituna/screens/screens.dart';
import 'package:arceituna/utils/utils.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});


  /// Muestra un diálogo informativo y permite acceder a la app sin iniciar sesión.
  ///
  /// Invocada por: Botón "Continuar como Invitado".
  void _continueAsGuest(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Modo Invitado',
      content: 'Como invitado podrás ver el mapa y la información pública del olivar, '
          'pero no podrás registrar observaciones, añadir tratamientos ni modificar el estado de los árboles.\n\n'
          '¿Deseas continuar?',
      confirmColor: Colors.green,
      confirmText: 'Continuar',
    );

    if (confirm) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo de la aplicación
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/arceituna.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'ARCeituna',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade900),
              ),
              Text(
                'Gestión Integral',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),
              const Text(
                'de Olivar con AR',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              ),

              const Spacer(),

              // Botón de Registro / Iniciar Sesión
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.person),
                  label: const Text('Iniciar Sesión / Registrarse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Botón de Invitado
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade700, width: 2),
                    foregroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.explore),
                  label: const Text('Continuar como Invitado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => _continueAsGuest(context),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
