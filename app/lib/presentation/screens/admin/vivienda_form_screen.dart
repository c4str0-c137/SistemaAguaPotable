import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/domain/entities/vivienda_entity.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_event.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_state.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:get_it/get_it.dart';

class ViviendaFormScreen extends StatefulWidget {
  final int? socioId;
  final ViviendaEntity? vivienda;

  const ViviendaFormScreen({super.key, this.socioId, this.vivienda});

  @override
  State<ViviendaFormScreen> createState() => _ViviendaFormScreenState();
}

class _ViviendaFormScreenState extends State<ViviendaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _direccionController = TextEditingController();
  
  List<dynamic> _socios = [];
  List<dynamic> _zonas = [];
  List<dynamic> _tarifas = [];
  
  int? _selectedSocioId;
  int? _selectedZonaId;
  int? _selectedTarifaId;
  String _selectedAlcantarillado = 'ninguno'; // Add this line
  String _selectedTipoLectura = 'mensual';
  final _lecturaInicialController = TextEditingController(text: '0');
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _selectedSocioId = widget.socioId ?? widget.vivienda?.userId;
    if (widget.vivienda != null) {
      _codigoController.text = widget.vivienda!.codigo;
      _direccionController.text = widget.vivienda!.direccion ?? '';
      _selectedZonaId = widget.vivienda!.zoneId;
      _selectedTarifaId = widget.vivienda!.tarifaId;
      _selectedAlcantarillado = widget.vivienda!.alcantarillado; // Add this line
      _selectedTipoLectura = widget.vivienda!.tipoLectura;
      _lecturaInicialController.text = widget.vivienda!.lecturaInicial.toString();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dio = GetIt.I<DioClient>().dio;
      final results = await Future.wait([
        dio.get('/socios'),
        dio.get('/zones'),
        dio.get('/tarifas'),
      ]);
      if (!mounted) return;
      setState(() {
        _socios = results[0].data;
        _zonas = results[1].data;
        _tarifas = results[2].data;
        
        if (_tarifas.isNotEmpty && _selectedTarifaId == null) {
          _selectedTarifaId = _tarifas.first['id'];
        }
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar datos auxiliares')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vivienda == null ? 'Nueva Conexión' : 'Editar Conexión'),
      ),
      body: BlocListener<ViviendaBloc, ViviendaState>(
        listener: (context, state) {
          if (state is ViviendaOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            Navigator.pop(context);
          } else if (state is ViviendaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: _loadingData 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Socio'),
                    DropdownButtonFormField<int>(
                      value: _selectedSocioId,
                      items: _socios.map((s) => DropdownMenuItem(
                        value: s['id'] as int,
                        child: Text(s['name']),
                      )).toList(),
                      onChanged: widget.socioId != null ? null : (v) => setState(() => _selectedSocioId = v),
                      decoration: const InputDecoration(hintText: 'Seleccione un socio'),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Zona'),
                    DropdownButtonFormField<int>(
                      value: _selectedZonaId,
                      items: _zonas.map((z) => DropdownMenuItem(
                        value: z['id'] as int,
                        child: Text(z['name']),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedZonaId = v),
                      decoration: const InputDecoration(hintText: 'Seleccione zona'),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Tarifa'),
                    DropdownButtonFormField<int>(
                      value: _selectedTarifaId,
                      items: _tarifas.map((t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text('${t['nombre']} (${t['monto_fijo']} Bs)'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedTarifaId = v),
                      decoration: const InputDecoration(hintText: 'Seleccione tarifa'),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Servicio de Alcantarillado'),
                    DropdownButtonFormField<String>(
                      value: _selectedAlcantarillado,
                      items: const [
                        DropdownMenuItem(value: 'ninguno', child: Text('No tiene (0 Bs)')),
                        DropdownMenuItem(value: 'activo', child: Text('Tiene activo (8 Bs)')),
                        DropdownMenuItem(value: 'inactivo', child: Text('Tiene inactivo (5 Bs)')),
                      ],
                      onChanged: (v) => setState(() => _selectedAlcantarillado = v!),
                      decoration: const InputDecoration(hintText: 'Seleccione estado'),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Tipo de Cobro'),
                    DropdownButtonFormField<String>(
                      value: _selectedTipoLectura,
                      items: const [
                        DropdownMenuItem(value: 'mensual', child: Text('Mensual (por periodos)')),
                        DropdownMenuItem(value: 'anual', child: Text('Anual (acumulado)')),
                      ],
                      onChanged: (v) => setState(() => _selectedTipoLectura = v!),
                      decoration: const InputDecoration(hintText: 'Seleccione tipo'),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedTipoLectura == 'anual') ...[
                      _buildLabel('Lectura Inicial (para Cobro Anual)'),
                      TextFormField(
                        controller: _lecturaInicialController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ej. 120.0',
                          suffixText: 'm³',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildLabel('Código de Conexión'),
                    TextFormField(
                      controller: _codigoController,
                      decoration: const InputDecoration(hintText: 'Ej: TR-001'),
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Dirección / Referencia'),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(hintText: 'Sector Prol. Villazón Km 5'),
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Guardar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'user_id': _selectedSocioId,
        'zone_id': _selectedZonaId,
        'tarifa_id': _selectedTarifaId,
        'codigo': _codigoController.text,
        'direccion': _direccionController.text,
        'alcantarillado': _selectedAlcantarillado, // Add this line
        'tipo_lectura': _selectedTipoLectura,
        'lectura_inicial': double.tryParse(_lecturaInicialController.text) ?? 0,
      };

      if (widget.vivienda != null) {
        context.read<ViviendaBloc>().add(UpdateVivienda(id: widget.vivienda!.id, data: data));
      } else {
        context.read<ViviendaBloc>().add(CreateVivienda(data));
      }
    }
  }
}
