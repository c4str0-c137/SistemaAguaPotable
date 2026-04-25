import '../entities/lectura_entity.dart';

abstract class LecturaRepository {
  Future<List<LecturaEntity>> getLecturasByVivienda(int viviendaId);
  Future<LecturaEntity> saveLectura(Map<String, dynamic> data);
}
