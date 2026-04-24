class ViviendaEntity {
  final int id;
  final String codigo;
  final String direccion;
  final String socioName;
  final String zonaName;
  final double? latitude;
  final double? longitude;

  const ViviendaEntity({
    required this.id,
    required this.codigo,
    required this.direccion,
    required this.socioName,
    required this.zonaName,
    this.latitude,
    this.longitude,
  });
}
