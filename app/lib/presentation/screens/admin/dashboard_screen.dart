import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/core/utils/recibo_service.dart';
import 'package:sistema_control_agua/injection_container.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_event.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PagoBloc>()..add(GetResumenEvent()),
      child: BlocBuilder<PagoBloc, PagoState>(
        builder: (context, state) {
          if (state is PagoLoading) return const Center(child: CircularProgressIndicator());
          
          if (state is PagoError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 48),
                 const SizedBox(height: 12),
                 Text('Error: ${state.message}'),
              ],
            ));
          }

          if (state is PagoSuccess && state.resumen != null) {
            final r = state.resumen!;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PagoBloc>().add(GetResumenEvent());
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dashboard',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Resumen ejecutivo del sistema de agua.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: () => ReciboService.imprimirReporteMensual(r),
                          icon: const Icon(LucideIcons.fileOutput, size: 18),
                          label: const Text('Exportar Reporte'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildMetricCard('Recaudado Mes', 'Bs. ${r['monto_del_mes']}',
                                    LucideIcons.badgeDollarSign, AppColors.success)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMetricCard('Pagos Mes', '${r['pagos_del_mes']}',
                                    LucideIcons.wallet, AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildMetricCard('Pendientes', '${r['viviendas_pendientes']}',
                                    LucideIcons.alertCircle, AppColors.warning)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildMetricCard('Total Viviendas', '${r['total_viviendas']}',
                                    LucideIcons.home, AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        );
                      }
                    ),

                    const SizedBox(height: 32),
                    const Text('Estado de Cobranza',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    _buildProgressSection('Meta de Recaudación', 
                      (r['viviendas_pagadas'] as num?)?.toDouble() ?? 0, 
                      (r['total_viviendas'] as num?)?.toDouble() ?? 0),
                    
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'Última actualización: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProgressSection(String title, double current, double total) {
    final percent = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${(percent * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text('$current de $total viviendas han pagado este mes.', 
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
