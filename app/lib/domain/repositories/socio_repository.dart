abstract class SocioRepository {
  Future<List<dynamic>> getSocios();
  Future<void> createSocio(Map<String, dynamic> socio);
  Future<void> updateSocio(int id, Map<String, dynamic> socio);
  Future<void> deleteSocio(int id);
}
