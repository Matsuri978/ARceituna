import 'package:flutter/material.dart';

import 'package:tfg/services/services.dart';
import 'package:tfg/screens/screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = AuthService.instance.currentUser;

  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_user != null) {
      final roleObtained = await AuthService.instance.getRole(_user.id);
      if (mounted) {
        setState(() {
          _role = roleObtained;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _role = 'guest';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut(bool isGuest) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGuest ? 'Salir' : 'Cerrar Sesión'),
        content: Text(isGuest
            ? '¿Quieres volver a la pantalla de inicio?'
            : '¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
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
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, size: 60, color: Colors.green.shade900),
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoCard(
              title: 'Nombre',
              value: isGuest ? 'Invitado' : (_user.userMetadata?['display_name'] ?? 'Usuario'),
              icon: Icons.badge_outlined,
            ),
            _buildInfoCard(
              title: 'Correo Electrónico',
              value: isGuest ? 'N/A' : _user.email ?? 'Sin email',
              icon: Icons.email_outlined,
            ),
            _buildInfoCard(
              title: 'Rol en el sistema',
              value: _role != null ? _role![0].toUpperCase() + _role!.substring(1) : 'Cargando...',
              icon: Icons.settings_accessibility,
            ),

            const SizedBox(height: 30),

            const Text(
              'Permisos de tu cuenta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),


            ...AuthService.instance.getPermissions(_role ?? 'guest').entries.map((entry) {
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
                    decoration: entry.value ? TextDecoration.none : TextDecoration.lineThrough,
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade700),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    );
  }
}
