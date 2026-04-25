import '../entities/pago_entity.dart';

abstract class PagoRepository {
  Future<Map<String, dynamic>> calcularDeuda(int viviendaId, int periodoId);
  Future<Map<String, dynamic>> registrarPago(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getResumen();
  Future<List<Map<String, dynamic>>> getPagosByVivienda(int viviendaId);
}
