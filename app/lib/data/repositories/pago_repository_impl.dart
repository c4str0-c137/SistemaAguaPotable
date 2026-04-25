import 'package:dio/dio.dart';
import '../../domain/entities/pago_entity.dart';
import '../../domain/repositories/pago_repository.dart';
import '../models/pago_model.dart';

class PagoRepositoryImpl implements PagoRepository {
  final Dio dio;

  PagoRepositoryImpl(this.dio);

  @override
  Future<Map<String, dynamic>> calcularDeuda(int viviendaId, int periodoId) async {
    final response = await dio.post('/pagos/calcular', data: {
      'vivienda_id': viviendaId,
      'periodo_id': periodoId,
    });
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> registrarPago(Map<String, dynamic> data) async {
    final response = await dio.post('/pagos', data: data);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getResumen() async {
    final response = await dio.get('/pagos/resumen');
    print('DEBUG: RESUMEN API RESPONSE: ${response.data}');
    return response.data;
  }

  @override
  Future<List<Map<String, dynamic>>> getPagosByVivienda(int viviendaId) async {
    final response = await dio.get('/pagos?vivienda_id=$viviendaId');
    return List<Map<String, dynamic>>.from(response.data);
  }
}
