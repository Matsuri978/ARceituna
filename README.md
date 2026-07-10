# ARceituna - Realidad Aumentada y Gestión Agrícola

ARceituna es una aplicación desarrollada en Flutter diseñada para la gestión de parcelas de olivar, integrando tecnología de **Realidad Aumentada (AR)**, geolocalización avanzada y sincronización en tiempo real con **Supabase**.

## Guía de Instalación

Si deseas integrar este código fuente en un proyecto nuevo de Flutter, sigue estos pasos detallados:

### 1. Configuración del Proyecto (`pubspec.yaml`)
Copia el contenido íntegro del archivo `pubspec.yaml` de este repositorio a tu proyecto, o asegúrate de incluir todas las dependencias y la sección de assets.

**Comandos necesarios:**
Tras copiar el archivo, ejecuta los siguientes comandos en la terminal desde la raíz del proyecto:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

**Assets:**
Asegúrate de incluir la carpeta `assets/` en la raíz de tu proyecto. El archivo `pubspec.yaml` ya incluye las declaraciones necesarias:
```yaml
flutter:
  assets:
    - assets/olive.svg
    - assets/arceituna.png
    - assets/no_olive.svg
```

### 2. Migración de Código
Reemplaza las carpetas `lib/` y `assets/` de tu proyecto nuevo con las de este repositorio.

---

### 3. Configuración por Plataforma (Obligatorio)

#### Android
1.  **Versión Mínima de SDK:** 
    En `android/app/build.gradle`, asegúrate de que el `minSdkVersion` sea al menos **24** (requerido para ARCore).
    ```gradle
    defaultConfig {
        minSdk = 28 // Recomendado para este proyecto
    }
    ```
2.  **Permisos:** 
    Añade lo siguiente a tu `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    ```

#### iOS
Añade las siguientes claves a tu `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Se requiere acceso a la cámara para la Realidad Aumentada.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte las parcelas cercanas.</string>
```

---

### 4. Configuración de Base de Datos (Supabase)
La aplicación requiere una instancia de Supabase activa. El esquema de base de datos debe incluir:

**Tabla: `perfiles`**
- `id`: uuid (Primary Key, referenciando a `auth.users`)
- `rol`: text (Valores: 'agricultor', 'tecnico', 'invitado')
- `display_name`: text

> **Nota:** Las credenciales de Supabase (URL y Anon Key) se encuentran configuradas en `lib/main.dart`. Asegúrate de habilitar el servicio de Auth con Email.

---

## Tecnologías Utilizadas
- **Flutter & Dart**: Framework principal.
- **Supabase**: Autenticación y base de datos PostgreSQL.
- **AR Flutter Plugin**: Visualización de elementos 3D en el entorno real.
- **Geolocator**: Gestión de coordenadas y distancias.
- **Flutter Map**: Mapas interactivos con OpenStreetMap.

## Autores
Raúl Cobos Lanzas - rcl00050@red.ujaen.es
