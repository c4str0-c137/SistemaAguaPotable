import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/vivienda/vivienda_bloc.dart';
import '../../blocs/vivienda/vivienda_event.dart';
import '../../blocs/vivienda/vivienda_state.dart';
import '../../../injection_container.dart';

class ViviendaListScreen extends StatelessWidget {
  const ViviendaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ViviendaBloc>()..add(FetchViviendas()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestionar Conexiones'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () => sl<ViviendaBloc>().add(FetchViviendas()),
            ),
          ],
        ),
        body: BlocBuilder<ViviendaBloc, ViviendaState>(
          builder: (context, state) {
            if (state is ViviendaLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is ViviendaError) {
              return Center(child: Text(state.message));
            }
            
            if (state is ViviendasLoaded) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.viviendas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final vivienda = state.viviendas[index];
                  final hasGPS = vivienda.latitude != null && vivienda.longitude != null;
                  
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.home, color: AppColors.primary),
                      ),
                      title: Text(
                        vivienda.socioName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Código: ${vivienda.codigo} - Zona: ${vivienda.zonaName}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                hasGPS ? LucideIcons.mapPin : LucideIcons.mapPinOff,
                                size: 14,
                                color: hasGPS ? AppColors.success : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasGPS ? 'GPS Registrado' : 'Sin Ubicación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasGPS ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.edit2),
                        onPressed: () => _showGPSEditDialog(context, vivienda),
                      ),
                    ),
                  );
                },
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showGPSEditDialog(BuildContext context, vivienda) {
    final latController = TextEditingController(text: vivienda.latitude?.toString() ?? '');
    final longController = TextEditingController(text: vivienda.longitude?.toString() ?? '');

    showDialog(
      context: context,
      builder: (diagContext) => AlertDialog(
        title: Text('Editar Ubicación: ${vivienda.codigo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitud', hintText: '-17.412345'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: longController,
              decoration: const InputDecoration(labelText: 'Longitud', hintText: '-66.123456'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(diagContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lon = double.tryParse(longController.text);
              if (lat != null && lon != null) {
                context.read<ViviendaBloc>().add(
                  UpdateViviendaGPS(id: vivienda.id, latitude: lat, longitude: lon),
                );
                Navigator.pop(diagContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
