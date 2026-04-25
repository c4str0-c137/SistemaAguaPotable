import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/injection_container.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_event.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_state.dart';

class IngresoLecturaScreen extends StatefulWidget {
  const IngresoLecturaScreen({super.key});

  @override
  State<IngresoLecturaScreen> createState() => _IngresoLecturaScreenState();
}

class _IngresoLecturaScreenState extends State<IngresoLecturaScreen> {
  final _dio = sl<DioClient>().dio;
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _periodos = [];
  List<dynamic> _viviendas = [];
  List<String> _gestiones = ['2026', '2027', '2028'];
  String _selectedGestion = '2026';
  bool _loadingData = true;
  String? _dataError;

  // Table data
  List<dynamic> _zonas = [];
  List<dynamic> _lecturasList = [];
  int? _selectedZonaId;
  dynamic _tablePeriodo;
  bool _loadingLecturas = false;
  String _tablSearchQuery = '';
  final _tableSearchCtrl = TextEditingController();

  dynamic _selectedPeriodo;
  dynamic _selectedVivienda;

  final _lecturaAnteriorCtrl = TextEditingController();
  final _lecturaActualCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadZonas();
    _lecturaActualCtrl.addListener(() => setState(() {}));
    _tableSearchCtrl.addListener(() {
      setState(() => _tablSearchQuery = _tableSearchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _lecturaAnteriorCtrl.dispose();
    _lecturaActualCtrl.dispose();
    _observacionesCtrl.dispose();
    _tableSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final results = await Future.wait([
        _dio.get('/periodos'),
        _dio.get('/viviendas'),
      ]);
      if (!mounted) return;
      setState(() {
        _periodos  = results[0].data is List ? results[0].data : [];
        _viviendas = results[1].data is List ? results[1].data : [];
        if (_periodos.isNotEmpty) {
          _selectedPeriodo = _periodos.firstWhere((p) => p['estado'] == 'abierto', orElse: () => _periodos.first);
        }
        _loadingData = false;
        _tablePeriodo = _selectedPeriodo;
        _loadLecturasList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _dataError = e.toString(); _loadingData = false; });
    }
  }

  Future<void> _cargarLecturaAnterior() async {
    if (_selectedVivienda == null || _selectedPeriodo == null) return;
    try {
      final resp = await _dio.get('/lecturas/vivienda/${_selectedVivienda['id']}');
      if (!mounted) return;
      final lecturas = resp.data as List;
      
      // Buscamos si ya existe lectura para el periodo seleccionado
      final lecturaActualPeriodo = lecturas.firstWhere(
        (l) => l['periodo_id'] == _selectedPeriodo['id'],
        orElse: () => null,
      );

      if (lecturaActualPeriodo != null) {
        // Editando lectura existente
        _lecturaAnteriorCtrl.text = lecturaActualPeriodo['lectura_anterior'].toString();
        _lecturaActualCtrl.text = lecturaActualPeriodo['lectura_actual'].toString();
        _observacionesCtrl.text = lecturaActualPeriodo['observaciones'] ?? '';
      } else {
        // Nueva lectura para este periodo
        _lecturaActualCtrl.clear();
        _observacionesCtrl.clear();
        
        final isAnual = _selectedVivienda['tipo_lectura'] == 'anual';
        if (isAnual) {
          _lecturaAnteriorCtrl.text = _selectedVivienda['lectura_inicial'].toString();
        } else if (lecturas.isNotEmpty) {
          // La más reciente de periodos anteriores
          _lecturaAnteriorCtrl.text = lecturas.first['lectura_actual'].toString();
        } else {
          _lecturaAnteriorCtrl.text = "0";
        }
      }
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _lecturaAnteriorCtrl.text = "0";
      setState(() {});
    }
  }

  Future<void> _loadZonas() async {
    try {
      final resp = await _dio.get('/zones');
      if (!mounted) return;
      setState(() => _zonas = resp.data is List ? resp.data : []);
    } catch (_) {}
  }

  Future<void> _loadLecturasList() async {
    final periodo = _tablePeriodo ?? _selectedPeriodo;
    if (periodo == null) return;
    setState(() => _loadingLecturas = true);
    try {
      final params = <String, dynamic>{'periodo_id': periodo['id']};
      if (_selectedZonaId != null) params['zona_id'] = _selectedZonaId;
      final resp = await _dio.get('/lecturas', queryParameters: params);
      if (!mounted) return;
      setState(() {
        _lecturasList = resp.data is List ? resp.data : [];
        _loadingLecturas = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLecturas = false);
    }
  }

  List<dynamic> get _filteredLecturas {
    if (_tablSearchQuery.isEmpty) return _lecturasList;
    return _lecturasList.where((l) {
      final socio = (l['vivienda']?['socio']?['name'] ?? '').toString().toLowerCase();
      final codigo = (l['vivienda']?['codigo'] ?? '').toString().toLowerCase();
      return socio.contains(_tablSearchQuery) || codigo.contains(_tablSearchQuery);
    }).toList();
  }

  double get _consumo {
    final ant = double.tryParse(_lecturaAnteriorCtrl.text) ?? 0.0;
    final act = double.tryParse(_lecturaActualCtrl.text) ?? 0.0;
    return (act - ant).clamp(0, double.infinity);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVivienda == null || _selectedPeriodo == null) return;

    final data = {
      'vivienda_id':      _selectedVivienda['id'],
      'periodo_id':       _selectedPeriodo['id'],
      'lectura_anterior': double.tryParse(_lecturaAnteriorCtrl.text) ?? 0,
      'lectura_actual':   double.tryParse(_lecturaActualCtrl.text) ?? 0,
      'observaciones':    _observacionesCtrl.text.isEmpty ? null : _observacionesCtrl.text,
    };

    context.read<LecturaBloc>().add(SaveLecturaEvent(data));
  }
  Future<void> _showAbrirPeriodoDialog(BuildContext context) async {
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    String? selectedMes = 'Enero';
    String? selectedY = _selectedGestion;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDt) => AlertDialog(
          title: const Text('Abrir Nuevo Período'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedMes,
                isExpanded: true,
                items: meses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setDt(() => selectedMes = v),
              ),
              DropdownButton<String>(
                value: selectedY,
                isExpanded: true,
                items: _gestiones.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setDt(() => selectedY = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final nombre = '$selectedMes $selectedY';
                final mesIdx = meses.indexOf(selectedMes!) + 1;
                final ini = '$selectedY-${mesIdx.toString().padLeft(2, '0')}-01';
                final fin = DateTime(int.parse(selectedY!), mesIdx + 1, 0).toIso8601String().split('T')[0];

                try {
                  await _dio.post('/periodos', data: {
                    'nombre': nombre,
                    'gestion': selectedY,
                    'fecha_inicio': ini,
                    'fecha_fin': fin,
                    'estado': 'abierto',
                  });
                  Navigator.pop(ctx);
                  _loadInitialData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Abrir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirNuevoPeriodo(BuildContext context) async {
    // Logic to determine next month
    if (_periodos.isEmpty) return;
    final last = _periodos.first; // sorted by start_date desc
    final lastDate = DateTime.parse(last['fecha_fin']);
    final nextStart = lastDate.add(const Duration(days: 1));
    final nextEnd = DateTime(nextStart.year, nextStart.month + 1, 0);
    
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final nombre = '${meses[nextStart.month - 1]} ${nextStart.year}';

    try {
      await _dio.post('/periodos', data: {
        'nombre': nombre,
        'fecha_inicio': nextStart.toIso8601String().split('T')[0],
        'fecha_fin': nextEnd.toIso8601String().split('T')[0],
        'estado': 'abierto',
      });
      _loadInitialData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Período $nombre abierto correctamente'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());

    return BlocListener<LecturaBloc, LecturaState>(
      listener: (context, state) {
        if (state is LecturaSuccess && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!), backgroundColor: AppColors.success),
          );
          _loadLecturasList();
          // No limpiamos los campos para mantener la visualización
        } else if (state is LecturaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresar Lectura',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Registra el consumo mensual de una vivienda.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            if (_dataError != null) _buildAlert(_dataError!, AppColors.error, LucideIcons.alertCircle),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Gestión (Año)'),
                            DropdownButtonFormField<String>(
                              value: _selectedGestion,
                              items: _gestiones.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedGestion = v!;
                                  _selectedPeriodo = null;
                                });
                              },
                              decoration: _inputDec('2026'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Mes / Período'),
                            DropdownButtonFormField<dynamic>(
                              value: _selectedPeriodo,
                              items: _periodos
                                .where((p) => p['gestion'] == _selectedGestion)
                                .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p['nombre']),
                                )).toList(),
                              onChanged: (v) {
                                setState(() => _selectedPeriodo = v);
                                _cargarLecturaAnterior();
                              },
                              decoration: _inputDec('Seleccionar mes'),
                              validator: (v) => v == null ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _abrirNuevoPeriodo(context),
                      icon: const Icon(LucideIcons.plusCircle, size: 16),
                      label: const Text('Abrir Nuevo Período'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Socio / Vivienda'),
                  DropdownButtonFormField<dynamic>(
                    value: _selectedVivienda,
                    isExpanded: true,
                    items: _viviendas.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '${v['codigo']} - ${v['socio']?['name'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) {
                      setState(() => _selectedVivienda = v);
                      _cargarLecturaAnterior();
                    },
                    decoration: _inputDec('Seleccionar vivienda'),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Lectura Anterior (m³)'),
                        TextFormField(
                          controller: _lecturaAnteriorCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('0'),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ],
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Lectura Actual (m³)'),
                        TextFormField(
                          controller: _lecturaActualCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('0'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final act = double.tryParse(v) ?? 0;
                            final ant = double.tryParse(_lecturaAnteriorCtrl.text) ?? 0;
                            if (act < ant) return 'Debe ser ≥ anterior';
                            return null;
                          },
                        ),
                      ],
                    )),
                  ]),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.gauge, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Text('Consumo calculado: ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          '${_consumo.toStringAsFixed(1)} m³',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildLabel('Observaciones (opcional)'),
                  TextFormField(
                    controller: _observacionesCtrl,
                    maxLines: 2,
                    decoration: _inputDec('Ej: Fuga detectada...'),
                  ),

                  const SizedBox(height: 24),

                  BlocBuilder<LecturaBloc, LecturaState>(
                    builder: (context, state) {
                      final saving = state is LecturaLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving ? null : _guardar,
                          icon: saving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(LucideIcons.save),
                          label: Text(saving ? 'Guardando...' : 'Guardar Lectura'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Tabla de lecturas del período ──
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Lecturas del Período',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Lista de todas las lecturas registradas en el período seleccionado.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),

            // Filters row
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<dynamic>(
                  value: _tablePeriodo,
                  items: _periodos.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _tablePeriodo = v);
                    _loadLecturasList();
                  },
                  decoration: _inputDec('Período'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedZonaId,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todas las zonas')),
                    ..._zonas.map((z) => DropdownMenuItem<int?>(
                      value: z['id'] as int,
                      child: Text(z['name'] ?? z['nombre'] ?? 'Zona'),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedZonaId = v);
                    _loadLecturasList();
                  },
                  decoration: _inputDec('Zona'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _tableSearchCtrl,
                  decoration: _inputDec('Buscar socio o código...').copyWith(
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _tablSearchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _tableSearchCtrl.clear())
                        : null,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            if (_loadingLecturas)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_filteredLecturas.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(children: [
                  Icon(LucideIcons.fileQuestion, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('No hay lecturas en este período.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Socio', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Zona', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ant.', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Act.', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Consumo', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: List.generate(_filteredLecturas.length, (i) {
                        final l = _filteredLecturas[i];
                        final v = l['vivienda'] ?? {};
                        final consumo = (l['consumo'] as num?)?.toDouble() ?? 0;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith((states) =>
                              i.isEven ? Colors.white : Colors.grey.shade50),
                          cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(Text(v['codigo'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(v['socio']?['name'] ?? '')),
                            DataCell(Text(v['zona']?['name'] ?? v['zona']?['nombre'] ?? '-')),
                            DataCell(Text('${l['lectura_anterior']}')),
                            DataCell(Text('${l['lectura_actual']}')),
                            DataCell(Text(
                              '${consumo.toStringAsFixed(1)} m³',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: consumo > 30 ? AppColors.warning : AppColors.primary,
                              ),
                            )),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (!_loadingLecturas && _filteredLecturas.isNotEmpty)
              Text(
                '${_filteredLecturas.length} lectura(s) encontrada(s)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  );

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildAlert(String msg, Color color, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(color: color))),
    ]),
  );
}
