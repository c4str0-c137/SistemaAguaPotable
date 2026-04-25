import 'package:sistema_control_agua/domain/entities/configuracion_entity.dart';

abstract class ConfiguracionRepository {
  Future<List<AjusteEntity>> getAjustes();
  Future<List<TarifaEntity>> getTarifas();
  Future<void> updateAjuste(String clave, dynamic valor);
  
  // Tarifas
  Future<void> updateTarifa(int id, Map<String, dynamic> data);
  
  // Rangos
  Future<void> createRango(Map<String, dynamic> data);
  Future<void> updateRango(int id, Map<String, dynamic> data);
  Future<void> deleteRango(int id);
}
