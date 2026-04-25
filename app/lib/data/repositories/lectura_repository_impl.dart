import 'package:dio/dio.dart';
import '../../domain/entities/lectura_entity.dart';
import '../../domain/repositories/lectura_repository.dart';
import '../models/lectura_model.dart';
import '../../../core/network/dio_client.dart';

class LecturaRepositoryImpl implements LecturaRepository {
  final Dio dio;

  LecturaRepositoryImpl(this.dio);

  @override
  Future<List<LecturaEntity>> getLecturasByVivienda(int viviendaId) async {
    final response = await dio.get('/lecturas/vivienda/$viviendaId');
    return (response.data as List)
        .map((json) => LecturaModel.fromJson(json))
        .toList();
  }

  @override
  Future<LecturaEntity> saveLectura(Map<String, dynamic> data) async {
    final response = await dio.post('/lecturas', data: data);
    return LecturaModel.fromJson(response.data);
  }
}
