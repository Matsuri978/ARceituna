import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:arceituna/screens/screens.dart';
import 'package:arceituna/utils/utils.dart';

/// Flag para activar/desactivar el modo desarrollo.
const bool isDevMode = true;

/// Roles de usuario definidos en el sistema.
enum UserRole {
  guest(label: 'Invitado', dbValue: 'guest'),
  farmer(label: 'Agricultor', dbValue: 'agricultor'),
  fieldManager(label: 'Gestor de Campo', dbValue: 'gestor_campo'),
  technician(label: 'Técnico', dbValue: 'tecnico'),
  admin(label: 'Administrador', dbValue: 'admin');

  final String label;
  final String dbValue;
  const UserRole({required this.label, required this.dbValue});

  /// Convierte un String de la base de datos a un UserRole.
  static UserRole fromString(String? roleStr) {
    return UserRole.values.firstWhere(
      (e) => e.dbValue == roleStr?.toLowerCase(),
      orElse: () => UserRole.guest,
    );
  }

  // --- Permisos Granulares (Basados en la lógica original) ---
  bool get canAddOlive => this == fieldManager || this == admin;
  bool get canRegisterTreatments =>
      this == farmer ||
      this == technician ||
      this == admin;
  bool get canRegisterObservations => this == technician || this == admin;
  bool get canModifyOlives =>
      this == technician || this == admin;
  bool get canUseDevTools => this == admin;

  /// Roles disponibles para el registro de nuevos usuarios (excluye Guest por defecto).
  static List<UserRole> get registrationRoles => [
        farmer,
        technician,
        fieldManager,
        if (isDevMode) admin,
      ];

  /// Mapa de permisos para mostrar en la pantalla de perfil.
  Map<String, bool> get permissionsMap => {
        'Ver ubicación y mapas': true,
        'Uso de Escáner AR': true,
        'Registrar Tratamientos': canRegisterTreatments,
        'Registrar Observaciones': canRegisterObservations,
        'Modificar datos de Olivos': canModifyOlives,
        'Añadir nuevos Olivos': canAddOlive,
      };
}

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
  addOlive(
    menuTitle: 'Añadir Olivo',
    appBarTitle: 'Registro de Olivos',
    icon: Icons.add_location_alt_outlined,
    screen: AddOliveScreen(),
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

  /// Filtro de visibilidad para el menú lateral.
  bool isVisible(UserRole role) {
    if (this == addOlive) return role.canAddOlive;
    return true;
  }
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
/// Invocada por: AddOliveScreen.
enum OliveVariety {
  picual('Picual'),
  hojiblanca('Hojiblanca'),
  arbequina('Arbequina'),
  manzanilla('Manzanilla'),
  cornicabra('Cornicabra');

  final String label;
  const OliveVariety(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();

  static OliveVariety? fromLabel(String? label) {
    if (label == null) return null;
    try {
      return values.firstWhere((e) => e.label.toLowerCase() == label.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

/// Estados posibles de un olivo.
///
/// Invocada por: OliveInfoCard.
enum OliveStatus {
  healthy('Sano', Colors.green, "ESTADO ÓPTIMO"),
  sick('Enfermo', Colors.red, "ATENCIÓN REQUERIDA"),
  underTreatment('En Tratamiento', Colors.blue, "EN TRATAMIENTO");

  final String label;
  final Color color;
  final String infoText;
  const OliveStatus(this.label, this.color, this.infoText);

  static List<String> get labels => values.map((e) => e.label).toList();

  static OliveStatus fromLabel(String? label) {
    return values.firstWhere((e) => e.label == label, orElse: () => healthy);
  }
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

/// Estados de disponibilidad y permisos de la cámara para Realidad Aumentada.
enum ARStatus {
  initializing,
  unsupported,
  permissionDenied,
  cameraDisabled,
  ready
}
