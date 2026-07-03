import 'package:flutter/material.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/screens/screens.dart';
import 'package:arceituna/utils/utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = AuthService.instance.currentUser;
  late final UserRole _role;

  @override
  void initState() {
    super.initState();
    _role = AuthService.instance.currentRole;
  }

  /// Gestiona el cierre de sesión o la salida del modo invitado con confirmación.
  ///
  /// Invocada por: Botón "Cerrar Sesión" / "Salir".
  Future<void> _signOut(bool isGuest) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: isGuest ? 'Salir' : 'Cerrar Sesión',
      content: isGuest
          ? '¿Quieres volver a la pantalla de inicio?'
          : '¿Estás seguro de que quieres salir?',
    );

    if (confirm) {
      if (!isGuest) {
        await AuthService.instance.signOut();
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = _user == null;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade50,
                child: Image.asset(
                    'assets/arceituna.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            infoCard(
              title: 'Nombre',
              value: isGuest
                  ? 'Invitado'
                  : (_user.userMetadata?['display_name'] ?? 'Usuario'),
              icon: Icons.badge_outlined,
              iconColor: Colors.green.shade700,
            ),
            infoCard(
              title: 'Correo Electrónico',
              value: isGuest ? 'N/A' : _user.email ?? 'Sin email',
              icon: Icons.email_outlined,
              iconColor: Colors.green.shade700,
            ),
            infoCard(
              title: 'Rol en el sistema',
              value: isGuest ? 'Invitado' : _role.label,
              icon: Icons.settings_accessibility,
              iconColor: Colors.green.shade700,
            ),
            const SizedBox(height: 30),
            const Text(
              'Permisos de tu cuenta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._role.permissionsMap.entries.map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  color: entry.value ? Colors.green : Colors.red,
                  size: 28,
                ),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 16,
                    color: entry.value ? Colors.black87 : Colors.grey,
                    decoration: entry.value
                        ? TextDecoration.none
                        : TextDecoration.lineThrough,
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _signOut(isGuest),
                icon: Icon(isGuest ? Icons.login : Icons.logout),
                label: Text(
                  isGuest ? 'Salir' : 'Cerrar Sesión',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
