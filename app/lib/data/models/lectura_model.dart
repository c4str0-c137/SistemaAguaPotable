import '../../domain/entities/lectura_entity.dart';

class LecturaModel extends LecturaEntity {
  LecturaModel({
    required super.id,
    required super.viviendaId,
    required super.periodoId,
    required super.lecturaAnterior,
    required super.lecturaActual,
    required super.consumo,
    super.observaciones,
    required super.createdAt,
  });

  factory LecturaModel.fromJson(Map<String, dynamic> json) {
    return LecturaModel(
      id: json['id'],
      viviendaId: json['vivienda_id'],
      periodoId: json['periodo_id'],
      lecturaAnterior: (json['lectura_anterior'] as num).toDouble(),
      lecturaActual: (json['lectura_actual'] as num).toDouble(),
      consumo: (json['consumo'] as num).toDouble(),
      observaciones: json['observaciones'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vivienda_id': viviendaId,
      'periodo_id': periodoId,
      'lectura_anterior': lecturaAnterior,
      'lectura_actual': lecturaActual,
      'consumo': consumo,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
