import '../../entities/vivienda_entity.dart';

abstract class ViviendaRepository {
  Future<List<ViviendaEntity>> getViviendas();
  Future<ViviendaEntity> updateGPS(int id, double latitude, double longitude);
}
