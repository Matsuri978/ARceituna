import 'package:flutter/material.dart';

import 'package:tfg/screens/screens.dart';

enum MenuOption {
  profile(
    menuTitle: 'Perfil',
    appBarTitle: 'Perfil',
    icon: Icons.person,
    screen: ProfileScreen(), // Ahora es una sección más
  ),
  home(
    menuTitle: 'Inicio',
    appBarTitle: 'Ubicación en tiempo real',
    icon: Icons.location_on_outlined,
    screen: LivePositionScreen(),
  ),
  arScanner(
    menuTitle: 'Escáner AR',
    appBarTitle: 'Escáner de Realidad Aumentada',
    icon: Icons.qr_code_scanner,
    screen: ARScreen(),
  );

  final String menuTitle;
  final String appBarTitle;
  final IconData icon;
  final Widget screen;

  const MenuOption({
    required this.menuTitle,
    required this.appBarTitle,
    required this.icon,
    required this.screen,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controlamos el estado directamente con el enum en lugar de un número
  MenuOption _currentOption = MenuOption.home;

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
                  color: _currentOption == MenuOption.profile ? Colors.green.shade100 : Colors.green.shade50,
                  border: Border(bottom: BorderSide(color: Colors.green.shade200)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green.shade700,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
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

            ...MenuOption.values.where((option) => option != MenuOption.profile).map((option) {
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
      body: _currentOption.screen,
    );
  }
}
