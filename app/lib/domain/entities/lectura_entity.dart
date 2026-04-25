class LecturaEntity {
  final int id;
  final int viviendaId;
  final int periodoId;
  final double lecturaAnterior;
  final double lecturaActual;
  final double consumo;
  final String? observaciones;
  final DateTime createdAt;

  LecturaEntity({
    required this.id,
    required this.viviendaId,
    required this.periodoId,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.consumo,
    this.observaciones,
    required this.createdAt,
  });
}
