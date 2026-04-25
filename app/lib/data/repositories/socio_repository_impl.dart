import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/domain/repositories/socio_repository.dart';

class SocioRepositoryImpl implements SocioRepository {
  final DioClient dioClient;
  SocioRepositoryImpl({required this.dioClient});

  @override
  Future<List<dynamic>> getSocios() async {
    print('Fetching socios from API...');
    try {
      final response = await dioClient.dio.get('/socios');
      print('Socios API Response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Socios API Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createSocio(Map<String, dynamic> socio) async {
    await dioClient.dio.post('/socios', data: socio);
  }

  @override
  Future<void> updateSocio(int id, Map<String, dynamic> socio) async {
    await dioClient.dio.put('/socios/$id', data: socio);
  }

  @override
  Future<void> deleteSocio(int id) async {
    await dioClient.dio.delete('/socios/$id');
  }
}
