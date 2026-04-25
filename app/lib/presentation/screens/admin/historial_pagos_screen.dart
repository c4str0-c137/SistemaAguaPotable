import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/core/utils/recibo_service.dart';
import 'package:sistema_control_agua/injection_container.dart';

class HistorialPagosScreen extends StatefulWidget {
  const HistorialPagosScreen({super.key});

  @override
  State<HistorialPagosScreen> createState() => _HistorialPagosScreenState();
}

class _HistorialPagosScreenState extends State<HistorialPagosScreen> {
  final _dio = sl<DioClient>().dio;
  final _searchCtrl = TextEditingController();

  List<dynamic> _socios = [];
  List<dynamic> _pagos = [];
  dynamic _selectedSocio;
  bool _loadingSocios = true;
  bool _loadingPagos = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSocios();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSocios() async {
    try {
      final resp = await _dio.get('/socios');
      if (!mounted) return;
      setState(() { _socios = resp.data is List ? resp.data : []; _loadingSocios = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSocios = false);
    }
  }

  Future<void> _loadPagos(dynamic socio) async {
    setState(() { _selectedSocio = socio; _loadingPagos = true; _pagos = []; });
    try {
      final vivResp = await _dio.get('/viviendas', queryParameters: {'user_id': socio['id']});
      if (!mounted) return;
      final viviendas = vivResp.data is List ? vivResp.data as List : [];
      final List<dynamic> allPagos = [];
      for (final v in viviendas) {
        final pResp = await _dio.get('/pagos', queryParameters: {'vivienda_id': v['id']});
        if (!mounted) return;
        if (pResp.data is List) {
          for (final p in pResp.data) {
            allPagos.add({...p, '_codigo': v['codigo']});
          }
        }
      }
      allPagos.sort((a, b) => (b['fecha_pago'] ?? '').compareTo(a['fecha_pago'] ?? ''));
      if (mounted) setState(() { _pagos = allPagos; _loadingPagos = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPagos = false);
    }
  }

  List<dynamic> get _filteredSocios {
    if (_searchQuery.isEmpty) return _socios;
    return _socios.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final ci = (s['ci'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || ci.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de Pagos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Busca un socio para ver su historial de cobros.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Search
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Nombre o CI del socio...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _searchCtrl.clear())
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 8),

          // Socio list
          if (_loadingSocios)
            const Center(child: CircularProgressIndicator())
          else if (_searchQuery.isNotEmpty)
            ..._filteredSocios.take(6).map((s) {
              final isSelected = _selectedSocio?['id'] == s['id'];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                ),
                color: isSelected ? AppColors.primary.withOpacity(0.04) : null,
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text((s['name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(s['name'] ?? ''),
                  subtitle: Text(s['ci'] ?? '', style: const TextStyle(fontSize: 11)),
                  trailing: isSelected ? const Icon(LucideIcons.checkCircle, color: AppColors.primary) : null,
                  onTap: () => _loadPagos(s),
                ),
              );
            }),

          // Payment history
          if (_selectedSocio != null) ...[
            const SizedBox(height: 20),
            Row(children: [
              const Icon(LucideIcons.receipt, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Pagos de ${_selectedSocio['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            if (_loadingPagos)
              const Center(child: CircularProgressIndicator())
            else if (_pagos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Sin pagos registrados.')),
                ),
              )
            else
              ..._pagos.map((p) => _buildPagoCard(p)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(dynamic pago) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Pago'),
        content: Text(
          '¿Seguro que deseas eliminar este pago de Bs. ${pago['monto_total']}?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _dio.delete('/pagos/${pago['id']}');
      if (!mounted) return;
      setState(() => _pagos.removeWhere((p) => p['id'] == pago['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago eliminado.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildPagoCard(dynamic pago) {
    final detalles = pago['detalles'] as List? ?? [];
    final fecha = (pago['fecha_pago'] ?? '').toString().substring(0, 10);
    final codigo = pago['_codigo'] ?? pago['vivienda']?['codigo'] ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
        ),
        title: Row(children: [
          Expanded(child: Text(codigo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Text('Bs. ${pago['monto_total']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
        ]),
        subtitle: Text(fecha, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Detail rows
          ...detalles.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(d['descripcion'] ?? d['tipo'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Bs. ${d['monto']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          )),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ReciboService.imprimirRecibo(pago),
                icon: const Icon(LucideIcons.printer, size: 16),
                label: const Text('Reimprimir', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(pago),
              icon: const Icon(LucideIcons.trash2, size: 14),
              label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
