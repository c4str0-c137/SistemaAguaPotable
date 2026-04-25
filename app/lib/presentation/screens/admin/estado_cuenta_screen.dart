import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/core/utils/recibo_service.dart';
import 'package:sistema_control_agua/domain/entities/vivienda_entity.dart';
import 'package:sistema_control_agua/injection_container.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_event.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_state.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_event.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_state.dart';
import 'package:intl/intl.dart';

class EstadoCuentaScreen extends StatefulWidget {
  final dynamic vivienda; // Using dynamic to avoid strict entity typing issues for now

  const EstadoCuentaScreen({super.key, required this.vivienda});

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<LecturaBloc>()..add(GetLecturaHistoryEvent(widget.vivienda.id))),
        BlocProvider(create: (context) => sl<PagoBloc>()..add(GetPagoHistoryEvent(widget.vivienda.id))),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Estado de Cuenta: ${widget.vivienda.codigo}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Pagos Realizados'),
              Tab(text: 'Historial Lecturas'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPagosList(),
            _buildLecturasList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagosList() {
    return BlocBuilder<PagoBloc, PagoState>(
      builder: (context, state) {
        if (state is PagoLoading) return const Center(child: CircularProgressIndicator());
        if (state is PagoError) return Center(child: Text(state.message));
        if (state is PagoSuccess && state.history != null) {
          Widget _buildPaymentList(List<Map<String, dynamic>> pagos) {
            if (pagos.isEmpty) return _buildEmptyState(LucideIcons.wallet, 'No hay pagos registrados');

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: pagos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pago = pagos[index];
                final date = DateTime.parse(pago['fecha_pago']);
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.successLight,
                      child: Icon(LucideIcons.check, color: AppColors.success, size: 20),
                    ),
                    title: Text('Pago de ${DateFormat('MMMM yyyy', 'es').format(date)}'),
                    subtitle: Text('Bs. ${pago['monto_total']} — ${DateFormat('dd/MM/yyyy HH:mm').format(date)}'),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.printer, color: AppColors.primary),
                      onPressed: () => ReciboService.imprimirRecibo(pago),
                    ),
                  ),
                );
              },
            );
          }
          return _buildPaymentList(state.history ?? []);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLecturasList() {
    return BlocBuilder<LecturaBloc, LecturaState>(
      builder: (context, state) {
        if (state is LecturaLoading) return const Center(child: CircularProgressIndicator());
        if (state is LecturaError) return Center(child: Text(state.message));
        if (state is LecturaSuccess && state.history != null) {
          final history = state.history!;
          if (history.isEmpty) return _buildEmptyState(LucideIcons.gauge, 'No hay lecturas registradas');

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final l = history[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lectura: ${l.lecturaActual} m³', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('MMM yyyy').format(l.createdAt), style: const TextStyle(color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          _buildMiniStat('Anterior', '${l.lecturaAnterior}'),
                          _buildMiniStat('Consumo', '${l.consumo}', isBold: true),
                        ],
                      ),
                      if (l.observaciones != null) ...[
                        const SizedBox(height: 8),
                        Text('Obs: ${l.observaciones}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMiniStat(String label, String value, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
