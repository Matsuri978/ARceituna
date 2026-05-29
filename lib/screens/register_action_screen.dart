import 'package:flutter/material.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/utils/utils.dart';

class RegisterActionScreen extends StatefulWidget {
  final List<Olive> olives;
  final UserRole role;

  const RegisterActionScreen({
    super.key,
    required this.olives,
    required this.role,
  });

  @override
  State<RegisterActionScreen> createState() => _RegisterActionScreenState();
}

class _RegisterActionScreenState extends State<RegisterActionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Campos Tratamiento
  final _productController = TextEditingController();
  final _doseController = TextEditingController();

  // Campos Observación
  String? _selectedType;
  String? _selectedStatus;
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _productController.dispose();
    _doseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Selecciona una fecha usando el picker de sistema.
  ///
  /// Invocada por: Icono de calendario en el formulario.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Guarda el registro (tratamiento u observación) en la base de datos.
  ///
  /// Invocada por: Botón "Guardar" de cada formulario.
  Future<void> _save(bool isTreatment) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final List<int> oliveIds = widget.olives.map((o) => o.id).toList();

      if (isTreatment) {
        await DatabaseService.instance.addTreatment(
          oliveIds: oliveIds,
          product: _productController.text.trim(),
          dose: _doseController.text.trim(),
          date: _selectedDate,
        );
      } else {
        await DatabaseService.instance.addObservation(
          oliveIds: oliveIds,
          type: _selectedType!,
          status: _selectedStatus!,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
        );
      }

      if (!mounted) return;
      showMessage(context, "Registro guardado correctamente", neutral: true);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, "Error al guardar: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canObserve = widget.role.canRegisterObservations;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: canObserve ? 2 : 1,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.olives.length > 1 
                ? "Acción en Recinto (${widget.olives.length} olivos)"
                : "Nuevo registro"),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                const Tab(icon: Icon(Icons.science), text: "Tratamiento"),
                if (canObserve)
                  const Tab(icon: Icon(Icons.visibility), text: "Observación"),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: TabBarView(
              children: [
                _buildTreatmentForm(),
                if (canObserve) _buildObservationForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateField(),
          const SizedBox(height: 20),
          TextFormField(
            controller: _productController,
            decoration: InputDecoration(
              labelText: "Producto",
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
            validator: (val) =>
                (val == null || val.isEmpty) ? "Campo requerido" : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _doseController,
            decoration: InputDecoration(
              labelText: "Dosis / Cantidad",
              prefixIcon: const Icon(Icons.scale_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
            validator: (val) =>
                (val == null || val.isEmpty) ? "Campo requerido" : null,
          ),
          const SizedBox(height: 40),
          _buildSaveButton(true),
        ],
      ),
    );
  }

  Widget _buildObservationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateField(),
          const SizedBox(height: 20),
          buildSimpleDropdown<String>(
            hint: "Tipo de observación",
            value: _selectedType,
            items: ObservationType.labels,
            itemText: (val) => val,
            onChanged: (val) => setState(() => _selectedType = val),
            validator: (val) => val == null ? "Selecciona un tipo" : null,
          ),
          const SizedBox(height: 20),
          buildSimpleDropdown<String>(
            hint: "Estado de la observación",
            value: _selectedStatus,
            items: ObservationStatus.labels,
            itemText: (val) => val,
            onChanged: (val) => setState(() => _selectedStatus = val),
            validator: (val) => val == null ? "Selecciona un estado" : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: "Descripción / Notas",
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
            validator: (val) =>
                (val == null || val.isEmpty) ? "Campo requerido" : null,
          ),
          const SizedBox(height: 40),
          _buildSaveButton(false),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.green),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Fecha del registro",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isTreatment) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isSaving ? null : () => _save(isTreatment),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving ? "Guardando..." : "Guardar Registro",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
