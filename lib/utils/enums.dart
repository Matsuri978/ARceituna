import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tfg/screens/screens.dart';
import 'package:tfg/utils/helpers.dart';

/// Opciones del menú lateral de la aplicación.
///
/// Invocada por: HomeScreen (construcción del Drawer y gestión de navegación).
enum MenuOption {
  profile(
    menuTitle: 'Perfil',
    appBarTitle: 'Perfil',
    icon: Icons.person,
    screen: ProfileScreen(),
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
  ),
  map(
    menuTitle: 'Mapa',
    appBarTitle: 'Mapa del Recinto',
    icon: Icons.map,
    screen: MapScreen(),
  ),
  devAddOlive(
    menuTitle: 'Añadir Olivo (Dev)',
    appBarTitle: 'Herramienta de Desarrollo',
    icon: Icons.add_location_alt_outlined,
    screen: DevAddOliveScreen(),
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

/// Secciones de información detallada en la pantalla de posición en vivo.
///
/// Invocada por: LivePositionScreen para renderizar las tarjetas de coordenadas, dirección y SigPac.
enum InfoSection {
  coordinates(
    title: "Coordenadas",
    icon: Icons.location_searching,
    fieldsBuilder: buildCoordinateFields,
  ),

  address(
    title: "Dirección",
    icon: Icons.location_on,
    fieldsBuilder: buildAddressFields,
  ),

  sigpac(
    title: "SigPac",
    icon: Icons.map_outlined,
    fieldsBuilder: buildSigpacFields,
  );

  final String title;
  final IconData icon;
  final List<Widget> Function(Position?, Placemark?) fieldsBuilder;

  const InfoSection({
    required this.title,
    required this.icon,
    required this.fieldsBuilder,
  });

  /// Construye una tarjeta (Card) para la sección de información.
  ///
  /// Invocada por: LivePositionScreen.
  Widget buildCard(Position? pos, Placemark? place) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...fieldsBuilder(pos, place),
          ],
        ),
      ),
    );
  }
}

/// Tipos de observaciones que se pueden realizar sobre un olivo.
///
/// Invocada por: OliveHistoryScreen (filtros y visualización) y diálogos de registro.
enum ObservationType {
  general('General'),
  pest('Plaga'),
  disease('Enfermedad'),
  pruning('Poda'),
  irrigation('Riego'),
  fertilization('Fertilización');

  final String label;
  const ObservationType(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

/// Variedades de olivos más comunes.
///
/// Invocada por: DevAddOliveScreen.
enum OliveVariety {
  picual('Picual'),
  hojiblanca('Hojiblanca'),
  arbequina('Arbequina'),
  manzanilla('Manzanilla'),
  cornicabra('Cornicabra');

  final String label;
  const OliveVariety(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

/// Estados posibles de un olivo.
///
/// Invocada por: OliveInfoCard.
enum OliveStatus {
  healthy('Sano'),
  sick('Enfermo'),
  underTreatment('En Tratamiento');

  final String label;
  const OliveStatus(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

/// Estados posibles de una observación en el historial.
///
/// Invocada por: OliveHistoryScreen y DatabaseService (actualización de estado).
enum ObservationStatus {
  pending('Pendiente'),
  inProcess('En proceso'),
  resolved('Resuelta');

  final String label;
  const ObservationStatus(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

/// Mapa con los nombres abreviados de los meses en español.
///
/// Invocada por: helpers.dart (buildSimpleDropdown) para mostrar meses en filtros.
const Map<int, String> monthNames = {
  1: 'Ene',
  2: 'Feb',
  3: 'Mar',
  4: 'Abr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Ago',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dic'
};
