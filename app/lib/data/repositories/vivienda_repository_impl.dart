import 'package:dio/dio.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/domain/entities/vivienda_entity.dart';
import 'package:sistema_control_agua/domain/repositories/vivienda_repository.dart';
import 'package:sistema_control_agua/data/models/vivienda_model.dart';

class ViviendaRepositoryImpl implements ViviendaRepository {
  final DioClient dioClient;

  ViviendaRepositoryImpl({required this.dioClient});

  @override
  Future<List<ViviendaEntity>> getViviendas() async {
    try {
      final response = await dioClient.dio.get('/viviendas');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => ViviendaModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['message'] ?? 'Error al cargar viviendas');
      }
      throw Exception('Error del servidor (${e.response?.statusCode ?? "Error al cargar viviendas"})');
    }
  }

  @override
  Future<ViviendaEntity> updateGPS(int id, double latitude, double longitude) async {
    try {
      final response = await dioClient.dio.patch('/viviendas/$id', data: {
        'latitude': latitude,
        'longitude': longitude,
      });

      if (response.statusCode == 200) {
        return ViviendaModel.fromJson(response.data);
      }
      throw Exception('Error al actualizar GPS');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['message'] ?? 'Error de conexión');
      }
      throw Exception('Error del servidor (${e.response?.statusCode ?? "Error de conexión"})');
    }
  }

  @override
  Future<void> createVivienda(Map<String, dynamic> data) async {
    await dioClient.dio.post('/viviendas', data: data);
  }

  @override
  Future<void> updateVivienda(int id, Map<String, dynamic> data) async {
    await dioClient.dio.put('/viviendas/$id', data: data);
  }

  @override
  Future<void> deleteVivienda(int id) async {
    await dioClient.dio.delete('/viviendas/$id');
  }
}
