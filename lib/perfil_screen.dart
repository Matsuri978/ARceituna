import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<String> _obtenerRol(String userId) async {
    try {
      final respuesta = await Supabase.instance.client
          .from('perfiles')
          .select('rol')
          .eq('id', userId)
          .single();
      return respuesta['rol'] as String;
    } catch (e) {
      return 'invitado';
    }
  }

  // Lógica de permisos según el rol
  Map<String, bool> _mapearPermisos(String rol) {
    bool esAgri = rol == 'agricultor' || rol == 'admin';
    bool esTec = rol == 'tecnico' || rol == 'admin' || rol == 'agricultor';

    return {
      'Ver ubicación y mapas': true, // Todos pueden
      'Uso de Escáner AR': true,     // Todos pueden
      'Registrar Tratamientos': esAgri || esTec,
      'Registrar Plagas': esTec,
      'Modificar datos de Olivos': esTec,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Sesión de invitado';
    final nombre = user?.userMetadata?['display_name'] ?? 'Invitado';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // --- CABECERA (ESTILO GITHUB) ---
          IntrinsicHeight(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.person, size: 40, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 15),
                VerticalDivider(color: Colors.grey.shade300, thickness: 2, width: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Nombre', nombre),
                      _infoRow('Email', email),
                      FutureBuilder<String>(
                        future: user != null ? _obtenerRol(user.id) : Future.value('invitado'),
                        builder: (context, snapshot) {
                          final rol = snapshot.data ?? 'Cargando...';
                          return _infoRow('Rol', rol[0].toUpperCase() + rol.substring(1));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 10),

          // --- SECCIÓN DE PERMISOS ---
          const Text(
            'Permisos del sistema',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: FutureBuilder<String>(
              future: user != null ? _obtenerRol(user.id) : Future.value('invitado'),
              builder: (context, snapshot) {
                final permisos = _mapearPermisos(snapshot.data ?? 'invitado');

                return ListView(
                  children: permisos.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          // Checkbox deshabilitado (no se puede cambiar)
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: entry.value,
                              onChanged: null, // Esto lo hace de "solo lectura"
                              activeColor: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: entry.value ? Colors.black87 : Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // --- BOTÓN CERRAR SESIÓN ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _confirmarSalida(context, user == null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  void _confirmarSalida(BuildContext context, bool esInvitado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esInvitado ? 'Salir' : 'Cerrar sesión'),
        content: Text(esInvitado
            ? '¿Quieres volver a la pantalla de inicio?'
            : '¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.black,
            ),
          )),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              if (!esInvitado) await Supabase.instance.client.auth.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Confirmar',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}