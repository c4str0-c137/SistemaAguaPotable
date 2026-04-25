import 'package:sistema_control_agua/domain/entities/vivienda_entity.dart';

abstract class ViviendaRepository {
  Future<List<ViviendaEntity>> getViviendas();
  Future<ViviendaEntity> updateGPS(int id, double latitude, double longitude);
  Future<void> createVivienda(Map<String, dynamic> data);
  Future<void> updateVivienda(int id, Map<String, dynamic> data);
  Future<void> deleteVivienda(int id);
}
