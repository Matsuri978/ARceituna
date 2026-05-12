import 'package:flutter/material.dart';
import 'package:tfg/screens/screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _continueAsGuest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text('Modo Invitado'),
          ],
        ),
        content: const Text(
            'Como invitado podrás ver el mapa y la información pública del olivar, '
                'pero no podrás registrar plagas, añadir tratamientos ni modificar el estado de los árboles.\n\n'
                '¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cierra el diálogo
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              // Navegamos al HomeSwipeScreen. Usamos push para que pueda volver atrás si quiere.
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
              );
            },
            child: const Text('Continuar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

              // Aquí puedes poner tu logo real más adelante con Image.asset
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.agriculture, size: 100, color: Colors.green.shade700),
              ),
              const SizedBox(height: 30),

              Text(
                'Gestión Integral',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade900),
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
