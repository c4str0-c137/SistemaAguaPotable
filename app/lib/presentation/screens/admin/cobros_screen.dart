import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/injection_container.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_bloc.dart';
import 'package:sistema_control_agua/presentation/screens/admin/historial_pagos_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/ingreso_lectura_screen.dart';
import 'package:sistema_control_agua/presentation/screens/admin/registrar_pago_screen.dart';

class CobrosScreen extends StatefulWidget {
  const CobrosScreen({super.key});

  @override
  State<CobrosScreen> createState() => _CobrosScreenState();
}

class _CobrosScreenState extends State<CobrosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dio = sl<DioClient>().dio;

  int _pagosDelMes = 0;
  double _montoDelMes = 0;
  int _pendientes = 0;
  bool _loadingResumen = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadResumen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResumen() async {
    try {
      final resp = await _dio.get('/pagos/resumen');
      final d = resp.data;
      setState(() {
        _pagosDelMes  = d['pagos_del_mes'] ?? 0;
        _montoDelMes  = (d['monto_del_mes'] as num?)?.toDouble() ?? 0;
        _pendientes   = d['viviendas_pendientes'] ?? 0;
        _loadingResumen = false;
      });
    } catch (_) {
      setState(() => _loadingResumen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con estadísticas
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cobros y Lecturas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (!_loadingResumen)
                Row(
                  children: [
                    Expanded(child: _buildStat('Pagos del mes', '$_pagosDelMes',
                        LucideIcons.wallet, AppColors.success)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStat('Total recaudado',
                        'Bs. ${_montoDelMes.toStringAsFixed(2)}',
                        LucideIcons.badgeDollarSign, AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStat('Pendientes', '$_pendientes',
                        LucideIcons.alertCircle, AppColors.warning)),
                  ],
                )
              else
                const LinearProgressIndicator(),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(LucideIcons.wallet, size: 18), text: 'Registrar Pago'),
                  Tab(icon: Icon(LucideIcons.penTool, size: 18), text: 'Ingresar Lectura'),
                  Tab(icon: Icon(LucideIcons.history, size: 18), text: 'Historial'),
                ],
              ),
            ],
          ),
        ),

        // Contenido de tabs
        Expanded(
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<LecturaBloc>()),
              BlocProvider(create: (context) => sl<PagoBloc>()),
            ],
            child: TabBarView(
              controller: _tabController,
              children: const [
                RegistrarPagoScreen(),
                IngresoLecturaScreen(),
                HistorialPagosScreen(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
