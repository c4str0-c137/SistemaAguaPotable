import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/domain/entities/configuracion_entity.dart';
import 'package:sistema_control_agua/injection_container.dart';
import 'package:sistema_control_agua/presentation/blocs/configuracion/configuracion_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/configuracion/configuracion_event.dart';
import 'package:sistema_control_agua/presentation/blocs/configuracion/configuracion_state.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ConfiguracionBloc>()..add(FetchConfiguracionEvent()),
      child: BlocListener<ConfiguracionBloc, ConfiguracionState>(
        listener: (context, state) {
          if (state is ConfiguracionUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ajuste actualizado'), backgroundColor: AppColors.success),
            );
          } else if (state is ConfiguracionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<ConfiguracionBloc, ConfiguracionState>(
          builder: (context, state) {
            if (state is ConfiguracionLoading) return const Center(child: CircularProgressIndicator());
            
            if (state is ConfiguracionLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configuración del Sistema',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('Gestión Actual',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: const Icon(LucideIcons.calendar, color: AppColors.primary),
                        title: const Text('Año de Gestión'),
                        subtitle: const Text('Año actual para filtros y procesos'),
                        trailing: DropdownButton<String>(
                          value: '2026',
                          items: ['2025', '2026', '2027'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (val) {
                            // TODO: Cambiar gestión global
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader(context, 'Tarifas de Consumo', LucideIcons.badgeDollarSign),
                    const SizedBox(height: 12),
                    if (state.tarifas.isEmpty)
                      const Text('No hay tarifas configuradas.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ...state.tarifas.map((t) => _buildTarifaCard(context, t)),
                    const SizedBox(height: 24),

                    _buildSectionHeader(context, 'Parámetros del Sistema', LucideIcons.sliders),
                    const SizedBox(height: 4),
                    const Text('Toca un parámetro para editarlo.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    if (state.ajustes.isEmpty)
                      const Text('No hay ajustes configurados.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ...state.ajustes.map((a) => _buildAjusteTile(context, a)),
                  ],
                ),
              );
            }

            if (state is ConfiguracionError) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<ConfiguracionBloc>().add(FetchConfiguracionEvent()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) =>
      Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const Spacer(),
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.textSecondary),
          onPressed: () => context.read<ConfiguracionBloc>().add(FetchConfiguracionEvent()),
        ),
      ]);

  Widget _buildTarifaCard(BuildContext context, TarifaEntity tarifa) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tarifa.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Cargo fijo: Bs. ${tarifa.montoFijo}', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.edit3, size: 20, color: AppColors.primary),
                onPressed: () => _showManageRangesDialog(context, tarifa),
                tooltip: 'Gestionar Rangos',
              ),
            ],
          ),
          if (tarifa.rangos.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Rangos de Consumo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tarifa.rangos.map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.desde.toInt()}-${r.hasta?.toInt() ?? '∞'}: ${r.precioMetro} Bs/m³',
                  style: const TextStyle(fontSize: 11),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    ),
  );

  void _showManageRangesDialog(BuildContext context, TarifaEntity tarifa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gestionar Rangos: ${tarifa.nombre}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Cargo Fijo (Base)', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: TextEditingController(text: tarifa.montoFijo.toString()),
                      onSubmitted: (v) {
                        context.read<ConfiguracionBloc>().add(UpdateTarifaEvent(
                          id: tarifa.id,
                          data: {'monto_fijo': double.tryParse(v) ?? tarifa.montoFijo},
                        ));
                      },
                      textAlign: TextAlign.end,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: ' Bs'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Row(
                children: [
                  Expanded(child: Text('Rangos de Consumo', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              ...tarifa.rangos.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text('${r.desde.toInt()} - ${r.hasta?.toInt() ?? '∞'} m³')),
                    Text('Bs. ${r.precioMetro}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                      onPressed: () => context.read<ConfiguracionBloc>().add(DeleteRangoEvent(id: r.id)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showAddRangoDialog(context, tarifa.id),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Agregar Rango'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showAddRangoDialog(BuildContext context, int tarifaId) {
    final desdeCtrl = TextEditingController();
    final hastaCtrl = TextEditingController();
    final precioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Rango'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: desdeCtrl, decoration: const InputDecoration(labelText: 'Desde'), keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: hastaCtrl, decoration: const InputDecoration(labelText: 'Hasta'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: 'Precio por m³'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<ConfiguracionBloc>().add(AddRangoEvent(data: {
                'tarifa_id': tarifaId,
                'desde': double.tryParse(desdeCtrl.text) ?? 0,
                'hasta': hastaCtrl.text.isEmpty ? null : double.tryParse(hastaCtrl.text),
                'precio_metro': double.tryParse(precioCtrl.text) ?? 0,
              }));
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAjusteTile(BuildContext context, AjusteEntity ajuste) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ListTile(
      leading: const Icon(LucideIcons.settings2, color: AppColors.textSecondary),
      title: Text(ajuste.descripcion ?? ajuste.clave,
          style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ajuste.valor.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
          const SizedBox(width: 8),
          const Icon(LucideIcons.pencil, size: 14, color: AppColors.textSecondary),
        ],
      ),
      onTap: () => _showEditDialog(context, ajuste),
    ),
  );

  Future<void> _showEditDialog(BuildContext context, AjusteEntity ajuste) async {
    final ctrl = TextEditingController(text: ajuste.valor.toString());
    final bloc = context.read<ConfiguracionBloc>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ajuste.descripcion ?? ajuste.clave),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Valor actual: ${ajuste.valor}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                bloc.add(UpdateAjusteEvent(clave: ajuste.clave, valor: ctrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
