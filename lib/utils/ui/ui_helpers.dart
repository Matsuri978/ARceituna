import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tfg/services/services.dart';
import 'package:tfg/utils/format_helpers.dart';

/// Muestra una fila de información personalizable.
Widget infoRow(
  String label,
  dynamic value, {
  String nullValue = 'N/A',
  bool isBetween = false,
  FontWeight labelWeight = FontWeight.bold,
  FontWeight valueWeight = FontWeight.normal,
  Color? labelColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment:
          isBetween ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      crossAxisAlignment:
          isBetween ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(isBetween ? label : "$label: ",
            style: TextStyle(fontWeight: labelWeight, color: labelColor)),
        if (isBetween)
          Text("${value ?? nullValue}",
              style: TextStyle(fontWeight: valueWeight))
        else
          Expanded(
              child: Text("${value ?? nullValue}",
                  style: TextStyle(fontWeight: valueWeight))),
      ],
    ),
  );
}

/// Builders para las secciones de información de ubicación.
List<Widget> buildCoordinateFields(Position? pos, Placemark? place) {
  return [
    infoRow("Longitud", pos?.longitude.toStringAsFixed(6),
        isBetween: true, nullValue: "-"),
    infoRow("Latitud", pos?.latitude.toStringAsFixed(6),
        isBetween: true, nullValue: "-"),
    infoRow("Altitud", "${pos?.altitude.toStringAsFixed(2)} m",
        isBetween: true, nullValue: "-"),
    infoRow("Precisión", "${pos?.accuracy.toStringAsFixed(2)} m",
        isBetween: true, nullValue: "-"),
  ];
}

List<Widget> buildAddressFields(Position? pos, Placemark? place) {
  final db = DatabaseService.instance;
  final province = db.currentProvince?['nombre']?.toString().capitalize();
  final municipality =
      db.currentMunicipality?['nombre']?.toString().capitalize();

  return [
    infoRow("País", place?.country, isBetween: true, nullValue: "-"),
    infoRow("C. Autónoma", place?.administrativeArea,
        isBetween: true, nullValue: "-"),
    infoRow("Provincia", province ?? place?.subAdministrativeArea,
        isBetween: true, nullValue: "-"),
    infoRow("Municipio", municipality ?? place?.locality,
        isBetween: true, nullValue: "-"),
    infoRow("Calle", place?.street, isBetween: true, nullValue: "-"),
    infoRow("Edificio", place?.name, isBetween: true, nullValue: "-"),
    infoRow("Código postal", place?.postalCode, isBetween: true, nullValue: "-"),
  ];
}

List<Widget> buildSigpacFields(Position? pos, Placemark? place) {
  final db = DatabaseService.instance;
  final provinceData = db.currentProvince;
  final municipalityData = db.currentMunicipality;

  return [
    infoRow(
        "Provincia",
        provinceData != null
            ? "${provinceData['nombre']} (${provinceData['codigo_ine_prov']})"
            : null,
        isBetween: true,
        nullValue: "-"),
    infoRow(
        "Municipio",
        municipalityData != null
            ? "${municipalityData['nombre']} (${municipalityData['num_municipio']})"
            : null,
        isBetween: true,
        nullValue: "-"),
    infoRow("Num. Parcela", db.currentParcel?['num_parcela']?.toString(),
        isBetween: true, nullValue: "-"),
    infoRow(
        "Recinto",
        db.currentEnclosure != null
            ? "${db.currentEnclosure!.enclosureNumber} (${db.currentEnclosure!.polygonNumber})"
            : null,
        isBetween: true,
        nullValue: "-"),
  ];
}

/// Muestra una tarjeta de información con icono, título y valor.
Widget infoCard({
  required String title,
  required String value,
  required IconData icon,
  Color iconColor = Colors.green,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 2,
    child: ListTile(
      leading: Icon(icon, color: iconColor),
      title:
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    ),
  );
}

/// Muestra un SnackBar rápido en la pantalla.
void showMessage(BuildContext context, String message,
    {bool isError = false, bool neutral = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          neutral ? null : (isError ? Colors.red : Colors.green.shade700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

/// Muestra un diálogo de confirmación estándar.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  Color confirmColor = Colors.red,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText, style: const TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Selector desplegable genérico con estilo personalizado.
Widget buildSimpleDropdown<T>({
  required String hint,
  required T? value,
  required List<T> items,
  required void Function(T?) onChanged,
  required String Function(T) itemText,
  bool enabled = true,
  bool showAllOption = false,
  String? allOptionLabel,
  String? Function(T?)? validator,
}) {
  return Opacity(
    opacity: enabled ? 1.0 : 0.5,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: hint,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(showAllOption ? (allOptionLabel ?? "Todos") : hint,
              style: TextStyle(
                  fontSize: 16,
                  color: showAllOption ? Colors.black : Colors.grey)),
        ),
        ...items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemText(item), style: const TextStyle(fontSize: 16)),
          );
        }),
      ],
    ),
  );
}
