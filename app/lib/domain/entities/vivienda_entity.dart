class ViviendaEntity {
  final int id;
  final String codigo;
  final String direccion;
  final String socioName;
  final String zonaName;
  final int userId;
  final int zoneId;
  final int tarifaId;
  final double? latitude;
  final double? longitude;
  final String alcantarillado;
  final String tipoLectura;
  final double lecturaInicial;

  const ViviendaEntity({
    required this.id,
    required this.codigo,
    required this.direccion,
    required this.socioName,
    required this.zonaName,
    required this.userId,
    required this.zoneId,
    required this.tarifaId,
    required this.alcantarillado,
    required this.tipoLectura,
    required this.lecturaInicial,
    this.latitude,
    this.longitude,
  });
}
