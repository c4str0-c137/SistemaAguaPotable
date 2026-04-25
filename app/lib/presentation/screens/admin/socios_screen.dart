import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/data/models/vivienda_model.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_event.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_state.dart';
import 'package:sistema_control_agua/presentation/screens/admin/vivienda_form_screen.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_event.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_state.dart';

class SociosScreen extends StatefulWidget {
  const SociosScreen({super.key});

  @override
  State<SociosScreen> createState() => _SociosScreenState();
}

class _SociosScreenState extends State<SociosScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<SocioBloc>().add(FetchSocios());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SocioBloc, SocioState>(
          listener: (context, state) {
            if (state is SocioSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
              );
            } else if (state is SocioError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            }
          },
        ),
        BlocListener<ViviendaBloc, ViviendaState>(
          listener: (context, state) {
            if (state is ViviendaOperationSuccess) {
              context.read<SocioBloc>().add(FetchSocios());
            }
          },
        ),
      ],
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  const Text('Gestión de Socios',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showSocioDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Nuevo Socio'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 48),
                    ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar socio por nombre o email...',
                    prefixIcon: const Icon(LucideIcons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            // Content
            Expanded(
              child: BlocBuilder<SocioBloc, SocioState>(
                builder: (context, state) {
                  if (state is SocioLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is SocioLoaded) {
                    return _buildSocioList(state.socios);
                  }
                  if (state is SocioError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return const Center(child: Text('Cargando socios...'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocioList(List<dynamic> socios) {
    final query = _searchController.text.toLowerCase();
    final filtered = socios.where((s) {
      final name = s['name']?.toString().toLowerCase() ?? '';
      final email = s['email']?.toString().toLowerCase() ?? '';
      return name.contains(query) || email.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No se encontraron socios.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final socio = filtered[index];
        final viviendas = socio['viviendas'] as List? ?? [];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(socio['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(socio['email'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Conexiones: ${socio['viviendas_count']}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      if (viviendas.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: viviendas.map((v) {
                              final alc = v['alcantarillado'] ?? 'ninguno';
                              final tipo = v['tipo_lectura'] ?? 'mensual';
                              
                              String tags = '';
                              if (alc == 'activo') tags += ' • Alc: Sí';
                              if (alc == 'inactivo') tags += ' • Alc: Inac';
                              if (tipo == 'anual') tags += ' • ANUAL';

                              return GestureDetector(
                                onLongPress: () => _confirmDeleteVivienda(context, v),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ViviendaFormScreen(
                                    vivienda: ViviendaModel.fromJson(v),
                                    socioId: socio['id'],
                                  )),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: tipo == 'anual' ? Colors.blue.shade50 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: tipo == 'anual' ? Colors.blue.shade200 : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    '${v['codigo'] ?? 'S/N'}$tags',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: tipo == 'anual' ? FontWeight.bold : FontWeight.normal,
                                      color: tipo == 'anual' ? Colors.blue : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle, color: AppColors.success, size: 22),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ViviendaFormScreen(socioId: socio['id'])),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.edit, size: 20, color: AppColors.textSecondary),
                      onPressed: () => _showSocioDialog(context, socio: socio),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
                      onPressed: () => _confirmDelete(context, socio),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSocioDialog(BuildContext context, {dynamic socio}) {
    final nameCtrl = TextEditingController(text: socio?['name'] ?? '');
    final emailCtrl = TextEditingController(text: socio?['email'] ?? '');
    final isEdit = socio != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar Socio' : 'Nuevo Socio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
            const SizedBox(height: 16),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo Electrónico')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final data = {
                'name': nameCtrl.text,
                'email': emailCtrl.text,
              };
              if (isEdit) {
                context.read<SocioBloc>().add(UpdateSocio(id: socio['id'], socio: data));
              } else {
                context.read<SocioBloc>().add(CreateSocio(data));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
            style: FilledButton.styleFrom(minimumSize: const Size(100, 40)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic socio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Socio'),
        content: Text('¿Está seguro de eliminar a ${socio['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<SocioBloc>().add(DeleteSocio(socio['id']));
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVivienda(BuildContext context, dynamic v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Conexión'),
        content: Text('¿Eliminar la conexión ${v['codigo']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<ViviendaBloc>().add(DeleteVivienda(v['id']));
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
