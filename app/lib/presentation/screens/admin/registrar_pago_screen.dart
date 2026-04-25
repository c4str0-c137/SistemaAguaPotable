import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/core/utils/recibo_service.dart';
import 'package:sistema_control_agua/injection_container.dart';

class RegistrarPagoScreen extends StatefulWidget {
  const RegistrarPagoScreen({super.key});

  @override
  State<RegistrarPagoScreen> createState() => _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends State<RegistrarPagoScreen> {
  final _dio = sl<DioClient>().dio;

  // Data
  List<dynamic> _periodos = [];
  List<dynamic> _socios = [];
  List<dynamic> _paymentMethods = [];
  bool _loadingData = true;
  String? _dataError;

  // Selection
  dynamic _selectedPeriodo;
  dynamic _selectedSocio;
  dynamic _selectedPaymentMethod;

  // Already paid vivienda IDs for the current period
  final Set<int> _pagadosIds = {};

  // Socio search
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Connections for selected socio
  List<dynamic> _viviendas = [];
  // Debts calculated per vivienda id
  final Map<int, Map<String, dynamic>> _deudas = {};
  // Selected viviendas for payment
  final Set<int> _selectedViviendaIds = {};
  bool _calculando = false;
  bool _pagando = false;
 
  // Dynamic extra charges
  final List<_ExtraChargeEntry> _extraChargeEntries = [];

  void _addExtraCharge({String desc = '', String monto = '0'}) {
    setState(() {
      _extraChargeEntries.add(_ExtraChargeEntry(
        descController: TextEditingController(text: desc),
        montoController: TextEditingController(text: monto),
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _searchQuery) {
        setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final entry in _extraChargeEntries) {
      entry.descController.dispose();
      entry.montoController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final results = await Future.wait([
        _dio.get('/periodos'),
        _dio.get('/socios'),
        _dio.get('/payment-methods'),
      ]);
      if (!mounted) return;
      setState(() {
        _periodos       = results[0].data is List ? results[0].data : [];
        _socios         = results[1].data is List ? results[1].data : [];
        _paymentMethods = results[2].data is List ? results[2].data : [];
        if (_periodos.isNotEmpty) {
          _selectedPeriodo = _periodos.firstWhere(
            (p) => p['estado'] == 'abierto', orElse: () => _periodos.first);
        }
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _paymentMethods.first;
        }
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _dataError = e.toString(); _loadingData = false; });
    }
  }

  Future<void> _onSocioSelected(dynamic socio) async {
    setState(() {
      _selectedSocio = socio;
      _viviendas = [];
      _deudas.clear();
      _selectedViviendaIds.clear();
    });
    try {
      // Load viviendas and paid IDs in parallel
      final results = await Future.wait([
        _dio.get('/viviendas', queryParameters: {'user_id': socio['id']}),
        if (_selectedPeriodo != null)
          _dio.get('/pagos/pagados-en-periodo', queryParameters: {'periodo_id': _selectedPeriodo['id']})
        else
          Future.value(null),
      ]);
      if (!mounted) return;
      final all = results[0]?.data is List ? results[0]!.data as List : [];
      final paidRaw = results[1]?.data;
      final paidIds = (paidRaw is List ? paidRaw : []).map((e) => e as int).toSet();
      final unpaid = all.where((v) => !paidIds.contains(v['id'] as int)).toList();
      setState(() {
        _viviendas = unpaid;
        _pagadosIds.addAll(paidIds);
        for (final v in _viviendas) {
          _selectedViviendaIds.add(v['id'] as int);
        }
      });
    } catch (_) {}
  }

  /// Re-load paid IDs when period changes
  Future<void> _refreshPagadosIds() async {
    if (_selectedPeriodo == null) return;
    try {
      final resp = await _dio.get('/pagos/pagados-en-periodo',
          queryParameters: {'periodo_id': _selectedPeriodo['id']});
      if (!mounted) return;
      final ids = (resp.data as List).map((e) => e as int).toSet();
      setState(() {
        _pagadosIds.clear();
        _pagadosIds.addAll(ids);
        // Remove paid connections from current viviendas list
        _viviendas = _viviendas.where((v) => !ids.contains(v['id'] as int)).toList();
        _selectedViviendaIds.removeWhere((id) => ids.contains(id));
      });
    } catch (_) {}
  }

  Future<void> _calcularDeudas() async {
    if (_selectedPeriodo == null || _selectedViviendaIds.isEmpty) return;
    setState(() { _calculando = true; _deudas.clear(); });
    for (final vId in _selectedViviendaIds) {
      try {
        final resp = await _dio.post('/pagos/calcular', data: {
          'vivienda_id': vId,
          'periodo_id':  _selectedPeriodo['id'],
        });
        if (!mounted) return;
        setState(() => _deudas[vId] = Map<String, dynamic>.from(resp.data));
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().contains('404')
            ? 'Sin lectura en este período'
            : e.toString();
        setState(() => _deudas[vId] = {'error': msg});
      }
    }
    if (mounted) setState(() => _calculando = false);
  }

  Future<void> _pagarTodos() async {
    if (_deudas.isEmpty) return;
    setState(() => _pagando = true);
    final pagados = <String>[];
    final errores = <String>[];

    for (final entry in _deudas.entries) {
      final deuda = entry.value;
      if (deuda.containsKey('error')) continue;
      try {
        final otrosDetalles = _extraChargeEntries.map((e) {
          final mStr = e.montoController.text.replaceAll(',', '.');
          final m = double.tryParse(mStr) ?? 0;
          if (m <= 0) return null;
          return {
            'tipo': 'cargo_extra',
            'monto': m,
            'descripcion': e.descController.text.isEmpty ? 'Cargo adicional' : e.descController.text,
          };
        }).where((e) => e != null).cast<Map<String, dynamic>>().toList();

        final totalExtrasPorConexion = otrosDetalles.fold<double>(0, (sum, c) => sum + (c['monto'] as double));

        final resp = await _dio.post('/pagos', data: {
          'vivienda_id':       deuda['vivienda_id'],
          'periodo_id':        _selectedPeriodo['id'],
          'payment_method_id': _selectedPaymentMethod?['id'],
          'monto_total':       (deuda['monto_total'] as num) + totalExtrasPorConexion,
          'monto_fijo':        deuda['monto_fijo'],
          'costo_consumo':     deuda['costo_consumo'],
          'multa':             deuda['multa'],
          'monto_alcantarillado': deuda['monto_alcantarillado'],
          'lectura_anterior':  deuda['lectura_anterior'],
          'lectura_actual':    deuda['lectura_actual'],
          'consumo':           deuda['consumo'],
          'desgloce_rangos':   deuda['desgloce_rangos'],
          'otros_detalles':    otrosDetalles,
        });
        if (!mounted) return;
        pagados.add(deuda['codigo'] ?? 'Conexión');
        // Print receipt
        if (resp.data != null) ReciboService.imprimirRecibo(resp.data);
      } catch (e) {
        if (!mounted) return;
        errores.add('${deuda['codigo']}: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _pagando = false;
      _deudas.clear();
      _selectedViviendaIds.clear();
      for (final e in _extraChargeEntries) {
        e.descController.dispose();
        e.montoController.dispose();
      }
      _extraChargeEntries.clear();
    });

    if (_selectedSocio != null) {
      _onSocioSelected(_selectedSocio);
    }

    final msg = pagados.isNotEmpty
        ? 'Pagado: ${pagados.join(', ')}'
        : 'No se pudo registrar ningún pago';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: pagados.isNotEmpty ? AppColors.success : AppColors.error,
    ));
  }

  List<dynamic> get _filteredSocios {
    if (_searchQuery.isEmpty) return _socios;
    return _socios.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final code = (s['ci'] ?? s['codigo'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || code.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar Pago',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Busca al socio y selecciona las conexiones a pagar.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          if (_dataError != null) _buildAlert(_dataError!, AppColors.error, LucideIcons.alertCircle),

          // Período
          _buildLabel('Período'),
          DropdownButtonFormField<dynamic>(
            value: _selectedPeriodo,
            items: _periodos.map((p) => DropdownMenuItem(
              value: p, child: Text('${p['nombre']} (${p['estado']})'),
            )).toList(),
            onChanged: (v) => setState(() {
              _selectedPeriodo = v;
              _deudas.clear();
              _refreshPagadosIds();
            }),
            decoration: _inputDec('Seleccionar período'),
          ),
          const SizedBox(height: 16),

          // Método de pago
          _buildLabel('Método de Pago'),
          DropdownButtonFormField<dynamic>(
            value: _selectedPaymentMethod,
            items: _paymentMethods.map((m) => DropdownMenuItem(
              value: m, child: Text(m['name']),
            )).toList(),
            onChanged: (v) => setState(() => _selectedPaymentMethod = v),
            decoration: _inputDec('Seleccionar método'),
          ),
          const SizedBox(height: 24),

          // Búsqueda de socio
          _buildLabel('Buscar Socio'),
          TextField(
            controller: _searchCtrl,
            decoration: _inputDec('Nombre o CI del socio...').copyWith(
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _searchCtrl.clear())
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          // Socio list
          if (_searchQuery.isNotEmpty || _selectedSocio != null)
            ..._buildSocioList(),

          // Connections for selected socio
          if (_selectedSocio != null && _viviendas.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                _buildLabel('Conexiones de ${_selectedSocio['name']}'),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selectedViviendaIds.length == _viviendas.length) {
                      _selectedViviendaIds.clear();
                    } else {
                      _selectedViviendaIds.addAll(_viviendas.map((v) => v['id'] as int));
                    }
                  }),
                  child: Text(_selectedViviendaIds.length == _viviendas.length
                      ? 'Deseleccionar todas' : 'Seleccionar todas'),
                ),
              ],
            ),
            ..._viviendas.map((v) {
              final id = v['id'] as int;
              final deuda = _deudas[id];
              final isSelected = _selectedViviendaIds.contains(id);
              final isAnual = v['tipo_lectura'] == 'anual';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) => setState(() {
                    if (val == true) _selectedViviendaIds.add(id);
                    else _selectedViviendaIds.remove(id);
                  }),
                  title: Row(children: [
                    Text(v['codigo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (isAnual)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text('ANUAL', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  subtitle: deuda != null
                    ? deuda.containsKey('error')
                        ? Row(children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(deuda['error']!, style: const TextStyle(color: AppColors.warning, fontSize: 11)),
                          ])
                        : Text('Consumo: ${deuda['consumo']} m³ · Total: Bs. ${deuda['monto_total']}',
                            style: const TextStyle(fontSize: 12))
                    : Text(v['zona']?['name'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),

            const SizedBox(height: 16),

            // Summary if debts calculated
            if (_deudas.isNotEmpty) ...[
              _buildExtraChargesSection(),
              const SizedBox(height: 16),
              _buildDeudaSummary(),
            ],

            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _calculando || _selectedViviendaIds.isEmpty ? null : _calcularDeudas,
                  icon: _calculando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.calculator),
                  label: Text(_calculando ? 'Calculando...' : 'Calcular Deuda'),
                ),
              ),
              if (_deudas.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pagando ? null : _pagarTodos,
                    icon: _pagando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.wallet),
                    label: Text(_pagando ? 'Registrando...' : 'Confirmar Pago(s)'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSocioList() {
    final filtered = _filteredSocios.take(8).toList();
    if (filtered.isEmpty) return [
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No se encontraron socios.', style: TextStyle(color: AppColors.textSecondary)),
      ),
    ];

    return filtered.map((s) {
      final isSelected = _selectedSocio?['id'] == s['id'];
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        color: isSelected ? AppColors.primary.withOpacity(0.04) : null,
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              (s['name'] ?? '?')[0].toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(s['ci'] ?? s['email'] ?? '', style: const TextStyle(fontSize: 11)),
          trailing: isSelected ? const Icon(LucideIcons.checkCircle, color: AppColors.primary) : null,
          onTap: () => _onSocioSelected(s),
        ),
      );
    }).toList();
  }

  Widget _buildExtraChargesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.plusCircle, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Cargos Adicionales (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            const Spacer(),
            if (_extraChargeEntries.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.cleaning_services, size: 16, color: Colors.orange),
                onPressed: () => setState(() {
                  for (final e in _extraChargeEntries) {
                    e.descController.dispose();
                    e.montoController.dispose();
                  }
                  _extraChargeEntries.clear();
                }),
                tooltip: 'Limpiar todos',
              ),
            TextButton.icon(
              onPressed: () => _addExtraCharge(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar cargo', style: TextStyle(fontSize: 12)),
            ),
          ]),
          if (_extraChargeEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Use a stable list of widgets
            ..._extraChargeEntries.map((charge) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                key: ValueKey(charge),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: charge.descController,
                        decoration: _inputDec('Descripción (Ej: Aporte...)').copyWith(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: charge.montoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDec('0').copyWith(
                          prefixText: 'Bs. ',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() {
                        charge.descController.dispose();
                        charge.montoController.dispose();
                        _extraChargeEntries.remove(charge);
                      }),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  final resp = await _dio.get('/ajustes');
                  final ajustes = resp.data as List;
                  final montoConexion = ajustes.firstWhere((a) => a['clave'] == 'monto_conexion', orElse: () => {'valor': '1500'})['valor'];
                  _addExtraCharge(desc: 'Costo de Conexión', monto: montoConexion.toString());
                } catch (_) {
                  _addExtraCharge(desc: 'Costo de Conexión', monto: '1500');
                }
              },
              icon: const Icon(LucideIcons.plug, size: 14),
              label: const Text('Cargar Monto Conexión Predeterminado', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Nota: Estos cargos se aplicarán a CADA conexión seleccionada.', 
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildDeudaSummary() {
    final validas = _deudas.values.where((d) => !d.containsKey('error')).toList();
    if (validas.isEmpty) return const SizedBox.shrink();
    
    final totalExtrasPorConexion = _extraChargeEntries.fold<double>(0, (sum, c) => sum + (double.tryParse(c.montoController.text) ?? 0));
    
    final subtotal = validas.fold<double>(0, (sum, d) => sum + (d['monto_total'] as num).toDouble());
    final totalExtras = totalExtrasPorConexion * validas.length;
    final totalGeneral = subtotal + totalExtras;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalle de Cobros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 20),
          ...validas.map((d) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection header
              Row(children: [
                const Icon(LucideIcons.home, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(d['codigo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Text(d['tarifa_nombre'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const Spacer(),
                if (d['is_anual'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                    child: const Text('ANUAL', style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 6),

              // Reading info
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Lectura: ${d['lectura_anterior']} → ${d['lectura_actual']} m³',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('Consumo: ${d['consumo']} m³',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),

              // Range breakdown
              if ((d['desgloce_rangos'] as List? ?? []).isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(children: const [
                        Expanded(child: Text('Rango', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Text('m³', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        SizedBox(width: 12),
                        Text('Bs/m³', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        SizedBox(width: 12),
                        SizedBox(width: 55, child: Text('Subtotal', textAlign: TextAlign.end, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                      ]),
                      const SizedBox(height: 4),
                      ...(d['desgloce_rangos'] as List).map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(children: [
                          Expanded(child: Text(
                            '${(r['desde'] as num).toInt()} – ${r['hasta'] == null ? '∞' : (r['hasta'] as num).toInt()} m³',
                            style: const TextStyle(fontSize: 11),
                          )),
                          Text('${r['metros']}', style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 12),
                          Text('${r['precio_metro']}', style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 12),
                          SizedBox(width: 55, child: Text('Bs.${r['subtotal']}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ]),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Charges
              if ((d['monto_fijo'] as num) > 0)
                _summaryRow(
                  d['is_anual'] == true ? 'Cargo Anual (incl. 60 m³)' : 'Cargo Fijo',
                  'Bs. ${d['monto_fijo']}',
                ),
              _summaryRow('Costo Consumo', 'Bs. ${d['costo_consumo']}'),
              if ((d['monto_alcantarillado'] as num? ?? 0) > 0)
                _summaryRow('Alcantarillado', 'Bs. ${d['monto_alcantarillado']}'),
              if ((d['multa'] as num? ?? 0) > 0)
                _summaryRow('Mora', 'Bs. ${d['multa']}', color: AppColors.error),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total conexión', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Bs. ${d['monto_total']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ]),
              const Divider(height: 16),
            ],
          )),

          // Grand total
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL A PAGAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Bs. ${totalGeneral.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primary)),
          ]),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 12, color: color ?? AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(color: color))),
    ]),
  );
}

class _ExtraChargeEntry {
  final TextEditingController descController;
  final TextEditingController montoController;

  _ExtraChargeEntry({
    required this.descController,
    required this.montoController,
  });
}
