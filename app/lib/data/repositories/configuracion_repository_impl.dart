import 'package:dio/dio.dart';
import 'package:sistema_control_agua/domain/entities/configuracion_entity.dart';
import 'package:sistema_control_agua/domain/repositories/configuracion_repository.dart';

class ConfiguracionRepositoryImpl implements ConfiguracionRepository {
  final Dio dio;

  ConfiguracionRepositoryImpl(this.dio);

  @override
  Future<List<AjusteEntity>> getAjustes() async {
    final response = await dio.get('/ajustes');
    return (response.data as List).map((json) => AjusteEntity(
      clave: json['clave'],
      valor: json['valor'],
      descripcion: json['descripcion'],
    )).toList();
  }

  @override
  Future<List<TarifaEntity>> getTarifas() async {
    final response = await dio.get('/tarifas');
    return (response.data as List).map((json) {
      final rangosJson = json['rangos'] as List? ?? [];
      return TarifaEntity(
        id: json['id'],
        nombre: json['nombre'],
        montoFijo: double.tryParse(json['monto_fijo'].toString()) ?? 0.0,
        rangos: rangosJson.map((r) => RangoEntity(
          id: r['id'],
          tarifaId: r['tarifa_id'],
          desde: double.tryParse(r['desde'].toString()) ?? 0.0,
          hasta: r['hasta'] != null ? double.tryParse(r['hasta'].toString()) : null,
          precioMetro: double.tryParse(r['precio_metro'].toString()) ?? 0.0,
        )).toList(),
      );
    }).toList();
  }

  @override
  Future<void> updateAjuste(String clave, dynamic valor) async {
    await dio.put('/ajustes/$clave', data: {'valor': valor});
  }

  @override
  Future<void> updateTarifa(int id, Map<String, dynamic> data) async {
    await dio.put('/tarifas/$id', data: data);
  }

  @override
  Future<void> createRango(Map<String, dynamic> data) async {
    await dio.post('/tarifa-rangos', data: data);
  }

  @override
  Future<void> updateRango(int id, Map<String, dynamic> data) async {
    await dio.put('/tarifa-rangos/$id', data: data);
  }

  @override
  Future<void> deleteRango(int id) async {
    await dio.delete('/tarifa-rangos/$id');
  }
}
