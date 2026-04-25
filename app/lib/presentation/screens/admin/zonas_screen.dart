import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/core/theme/app_colors.dart';
import 'package:sistema_control_agua/injection_container.dart';

class ZonasScreen extends StatefulWidget {
  const ZonasScreen({super.key});

  @override
  State<ZonasScreen> createState() => _ZonasScreenState();
}

class _ZonasScreenState extends State<ZonasScreen> {
  List<dynamic> _zonas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchZonas();
  }

  Future<void> _fetchZonas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = sl<DioClient>().dio;
      final response = await dio.get('/zones');
      if (response.statusCode == 200) {
        setState(() { _zonas = response.data; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text('Zonas de Distribución',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: AppColors.primary),
                onPressed: _fetchZonas,
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
                  : _zonas.isEmpty
                      ? const Center(child: Text('No hay zonas registradas'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _zonas.length,
                          itemBuilder: (context, index) {
                            final zona = _zonas[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(LucideIcons.mapPin, color: AppColors.info),
                                ),
                                title: Text(
                                  zona['name'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(zona['description'] ?? ''),
                                trailing: Text(
                                  'ID: ${zona['id']}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
