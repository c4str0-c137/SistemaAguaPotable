import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/vivienda_entity.dart';
import '../../../domain/repositories/vivienda_repository.dart';
import '../../models/vivienda_model.dart';

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
      throw Exception(e.response?.data['message'] ?? 'Error al cargar viviendas');
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
      throw Exception(e.response?.data['message'] ?? 'Error de conexión');
    }
  }
}
