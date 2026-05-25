import 'package:flutter/material.dart';

/// Formatea una cadena de fecha a formato DD/MM/YYYY.
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final DateTime date = DateTime.parse(dateStr);
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  } catch (e) {
    final parts = dateStr.split(RegExp(r'[-/]'));
    if (parts.length >= 3) {
      if (parts[0].length == 4) return "${parts[2]}/${parts[1]}/${parts[0]}";
      return "${parts[0]}/${parts[1]}/${parts[2]}";
    }
    return dateStr;
  }
}

/// Obtiene el número de días de un mes y año específicos.
int getDaysInMonth(int? year, int? month) {
  if (month == null) return 31;
  return DateUtils.getDaysInMonth(year ?? DateTime.now().year, month);
}

/// Extensión para capitalizar la primera letra de un String.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
