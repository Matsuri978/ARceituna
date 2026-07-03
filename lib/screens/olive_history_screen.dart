import 'package:flutter/material.dart';
import 'package:arceituna/models/models.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/utils/utils.dart';

class OliveHistoryScreen extends StatefulWidget {
  final Olive olive;

  const OliveHistoryScreen({super.key, required this.olive});

  @override
  State<OliveHistoryScreen> createState() => _OliveHistoryScreenState();
}

class _OliveHistoryScreenState extends State<OliveHistoryScreen> {
  // Datos
  late Future<List<Map<String, dynamic>>> _treatmentsFuture;
  late Future<List<Map<String, dynamic>>> _observationsFuture;

  // Filtros comunes
  bool _showDateFilters = false;
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _treatmentSearchController =
      TextEditingController();
  final TextEditingController _observationSearchController =
      TextEditingController();

  final List<int> _months = List.generate(12, (index) => index + 1);

  // Filtros Tratamientos
  String _treatmentSearch = "";

  // Filtros Observaciones
  String _observationSearch = "";
  String? _selectedObsType;
  String? _selectedObsStatus;

  final List<String> _obsTypes = ObservationType.labels;
  final List<String> _obsStatuses = ObservationStatus.labels;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _treatmentSearchController.dispose();
    _observationSearchController.dispose();
    super.dispose();
  }

  /// Comprueba si hay algún filtro o búsqueda activa en la pantalla.
  ///
  /// Invocada por: build() para determinar el color y estado del botón de reinicio.
  bool get _anyFilterActive {
    return _selectedYear != null ||
        _selectedMonth != null ||
        _selectedDay != null ||
        _treatmentSearch.isNotEmpty ||
        _observationSearch.isNotEmpty ||
        _selectedObsType != null ||
        _selectedObsStatus != null;
  }

  /// Carga los datos de tratamientos y observaciones desde el servicio de base de datos.
  ///
  /// Invocada por: initState() y RefreshIndicator.
  void _loadData() {
    _treatmentsFuture =
        DatabaseService.instance.getTreatmentsByOlive(widget.olive.id);
    _observationsFuture =
        DatabaseService.instance.getObservationsByOlive(widget.olive.id);
  }

  /// Restablece todos los filtros y controladores de búsqueda a su estado inicial.
  ///
  /// Invocada por: Botón de reinicio en la barra de búsqueda.
  void _resetFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
      _selectedDay = null;
      _yearController.clear();
      _treatmentSearch = "";
      _treatmentSearchController.clear();
      _observationSearch = "";
      _observationSearchController.clear();
      _selectedObsType = null;
      _selectedObsStatus = null;
    });
  }

  /// Filtra una fecha según los criterios de año, mes y día seleccionados.
  ///
  /// Invocada por: Lógica de filtrado en los FutureBuilder de tratamientos y observaciones.
  bool _matchesDate(String? dateStr) {
    if (_selectedYear == null && _selectedMonth == null && _selectedDay == null) {
      return true;
    }
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final DateTime date = DateTime.parse(dateStr);
      if (_selectedYear != null && date.year != _selectedYear) return false;
      if (_selectedMonth != null && date.month != _selectedMonth) return false;
      if (_selectedDay != null && date.day != _selectedDay) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Historial: Olivo (${widget.olive.variety})"),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.science), text: "Tratamientos"),
                Tab(icon: Icon(Icons.visibility), text: "Observaciones"),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
          ),
          body: TabBarView(
            children: [
              _buildTreatmentsTab(),
              _buildObservationsTab(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la barra de búsqueda común para ambas pestañas.
  ///
  /// Invocada por: buildTreatmentsTab() y buildObservationsTab().
  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(
              Icons.restart_alt,
              color: _anyFilterActive ? Colors.black : Colors.grey,
            ),
            tooltip: "Reiniciar búsqueda",
            onPressed: _anyFilterActive ? _resetFilters : null,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(
              _showDateFilters ? Icons.filter_alt_off : Icons.filter_alt,
              color: _showDateFilters ? Colors.green : Colors.grey,
            ),
            tooltip: "Filtros",
            onPressed: () =>
                setState(() => _showDateFilters = !_showDateFilters),
          ),
        ),
      ],
    );
  }

  /// Construye el contenido de la pestaña de Tratamientos.
  ///
  /// Invocada por: build() de OliveHistoryScreen.
  Widget _buildTreatmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildSearchBar(
                controller: _treatmentSearchController,
                hintText: "Buscar producto...",
                onChanged: (val) => setState(() => _treatmentSearch = val),
              ),
              if (_showDateFilters) ...[
                const SizedBox(height: 8),
                _buildProgressiveDateFilter(),
              ]
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _treatmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text("Error al cargar tratamientos."));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text("No hay tratamientos registrados."));
              }

              final treatments = snapshot.data!.where((t) {
                final matchesSearch = t['producto']
                        ?.toString()
                        .toLowerCase()
                        .contains(_treatmentSearch.toLowerCase()) ??
                    true;
                final matchesDate = _matchesDate(t['fecha_tratamiento']);
                return matchesSearch && matchesDate;
              }).toList();

              if (treatments.isEmpty) {
                return const Center(child: Text("No coinciden tratamientos."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadData();
                  setState(() {});
                },
                child: ListView.builder(
                  itemCount: treatments.length,
                  itemBuilder: (context, index) {
                    final t = treatments[index];
                    final formattedDate = formatDate(t['fecha_tratamiento']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ExpansionTile(
                        leading: const Icon(Icons.science, color: Colors.blue),
                        title: Text(t['producto'] ?? 'Tratamiento',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Fecha: $formattedDate"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                infoRow("Producto", t['producto']),
                                infoRow("Fecha", formattedDate),
                                infoRow("Dosis", t['dosis']),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Construye el contenido de la pestaña de Observaciones.
  ///
  /// Invocada por: build() de OliveHistoryScreen.
  Widget _buildObservationsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.green.shade50,
          child: Column(
            children: [
              _buildSearchBar(
                controller: _observationSearchController,
                hintText: "Buscar por tipo, estado...",
                onChanged: (val) => setState(() => _observationSearch = val),
              ),
              if (_showDateFilters) ...[
                const SizedBox(height: 8),
                _buildProgressiveDateFilter(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: buildSimpleDropdown<String>(
                        hint: "Tipo",
                        value: _selectedObsType,
                        items: _obsTypes,
                        onChanged: (val) =>
                            setState(() => _selectedObsType = val),
                        itemText: (val) => val,
                        showAllOption: true,
                        allOptionLabel: "Todos",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildSimpleDropdown<String>(
                        hint: "Estado",
                        value: _selectedObsStatus,
                        items: _obsStatuses,
                        onChanged: (val) =>
                            setState(() => _selectedObsStatus = val),
                        itemText: (val) => val,
                        showAllOption: true,
                        allOptionLabel: "Todos"
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _observationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                    child: Text("Error al cargar observaciones."));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text("No hay observaciones registradas."));
              }

              final observations = snapshot.data!.where((o) {
                final matchesDate = _matchesDate(o['fecha_observacion']);
                final matchesType = _selectedObsType == null ||
                    o['tipo_observacion'] == _selectedObsType;
                final matchesStatus = _selectedObsStatus == null ||
                    o['estado'] == _selectedObsStatus;

                final String searchText = _observationSearch.toLowerCase();
                final matchesText = searchText.isEmpty ||
                    (o['tipo_observacion']
                            ?.toString()
                            .toLowerCase()
                            .contains(searchText) ??
                        false) ||
                    (o['estado']?.toString().toLowerCase().contains(searchText) ??
                        false) ||
                    (o['descripcion']
                            ?.toString()
                            .toLowerCase()
                            .contains(searchText) ??
                        false);

                return matchesDate &&
                    matchesType &&
                    matchesStatus &&
                    matchesText;
              }).toList();

              if (observations.isEmpty) {
                return const Center(child: Text("No coinciden observaciones."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadData();
                  setState(() {});
                },
                child: ListView.builder(
                  itemCount: observations.length,
                  itemBuilder: (context, index) {
                    final o = observations[index];
                    final formattedDate = formatDate(o['fecha_observacion']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ExpansionTile(
                        leading: const Icon(Icons.remove_red_eye,
                            color: Colors.orange),
                        title: Text(o['tipo_observacion'] ?? 'Observación',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Fecha: $formattedDate"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                infoRow("Tipo", o['tipo_observacion']),
                                infoRow("Fecha", formattedDate),
                                infoRow("Estado", o['estado']),
                                infoRow("Descripción", o['descripcion']),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Construye el selector de fecha progresivo (Año -> Mes -> Día).
  ///
  /// Invocada por: _buildTreatmentsTab y _buildObservationsTab.
  Widget _buildProgressiveDateFilter() {
    final int maxDays = getDaysInMonth(_selectedYear, _selectedMonth);
    final List<int> currentDaysList = List.generate(maxDays, (i) => i + 1);

    return Row(
      children: [
        // Año: Reducido el flex y el hint
        Expanded(
          flex: 1,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: "Año",
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedYear = int.tryParse(val);
                  if (_selectedYear == null) {
                    _selectedMonth = null;
                    _selectedDay = null;
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 5),
        // Mes: Reducido un poco el flex
        Expanded(
          flex: 1,
          child: buildSimpleDropdown<int>(
            hint: "Mes",
            value: _selectedMonth,
            items: _months,
            onChanged: (val) => setState(() {
              _selectedMonth = val;
              if (val == null) {
                _selectedDay = null;
              } else {
                int max = getDaysInMonth(_selectedYear, val);
                if (_selectedDay != null && _selectedDay! > max) {
                  _selectedDay = max;
                }
              }
            }),
            itemText: (val) => monthNames[val] ?? val.toString(),
            enabled: _selectedYear != null,
          ),
        ),
        const SizedBox(width: 5),
        // Día: Mantenemos el espacio mínimo
        Expanded(
          flex: 1,
          child: buildSimpleDropdown<int>(
            hint: "Día",
            value: _selectedDay,
            items: currentDaysList,
            onChanged: (val) => setState(() => _selectedDay = val),
            itemText: (val) => val.toString(),
            enabled: _selectedMonth != null,
          ),
        ),
      ],
    );
  }
}
