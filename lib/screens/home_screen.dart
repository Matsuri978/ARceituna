import 'package:flutter/material.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/utils/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controlamos el estado directamente con el enum en lugar de un número
  MenuOption _currentOption = MenuOption.home;
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  /// Inicializa la autenticación cargando el rol del usuario actual.
  Future<void> _initAuth() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      await AuthService.instance.getRole(user.id);
    }
    if (mounted) {
      setState(() {
        _roleLoaded = true;
      });
    }
  }

  /// Cambia la pantalla actual mostrada en el Home y cierra el Drawer.
  ///
  /// Invocada por: Opciones del menú lateral (Drawer).
  void _changeScreen(MenuOption option) {
    setState(() {
      _currentOption = option;
    });
    // Cerramos el menú lateral al seleccionar una opción
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          _currentOption.appBarTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            InkWell(
              onTap: () => _changeScreen(MenuOption.profile),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20),
                decoration: BoxDecoration(
                  color: _currentOption == MenuOption.profile
                      ? Colors.green.shade100
                      : Colors.green.shade50,
                  border:
                      Border(bottom: BorderSide(color: Colors.green.shade200)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green.shade700,
                      child: const Icon(Icons.person,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...MenuOption.values
                .where((option) =>
                    option != MenuOption.profile &&
                    option.isVisible(AuthService.instance.currentRole))
                .map((option) {
              return ListTile(
                leading: Icon(option.icon, size: 30, color: Colors.black87),
                title: Text(option.menuTitle, style: const TextStyle(fontSize: 18)),
                selected: _currentOption == option,
                selectedTileColor: Colors.green.shade100,
                onTap: () => _changeScreen(option),
              );
            }),
          ],
        ),
      ),
      // Mostramos la pantalla leyendo directamente el widget guardado en el enum
      body: !_roleLoaded
          ? const Center(child: CircularProgressIndicator())
          : _currentOption.screen,
    );
  }
}
