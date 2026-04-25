import 'package:sistema_control_agua/domain/entities/vivienda_entity.dart';

class ViviendaModel extends ViviendaEntity {
  const ViviendaModel({
    required super.id,
    required super.codigo,
    required super.direccion,
    required super.socioName,
    required super.zonaName,
    required super.userId,
    required super.zoneId,
    required super.tarifaId,
    required super.alcantarillado,
    required super.tipoLectura,
    required super.lecturaInicial,
    super.latitude,
    super.longitude,
  });

  factory ViviendaModel.fromJson(Map<String, dynamic> json) {
    return ViviendaModel(
      id: json['id'],
      codigo: json['codigo'],
      direccion: json['direccion'] ?? '',
      socioName: json['socio']?['name'] ?? 'Sin asignar',
      zonaName: json['zona']?['name'] ?? 'Sin zona',
      userId: json['user_id'] ?? 0,
      zoneId: json['zone_id'] ?? 0,
      tarifaId: json['tarifa_id'] ?? 0,
      alcantarillado: json['alcantarillado'] ?? 'ninguno',
      tipoLectura: json['tipo_lectura'] ?? 'mensual',
      lecturaInicial: double.tryParse(json['lectura_inicial']?.toString() ?? '0') ?? 0,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'direccion': direccion,
      'user_id': userId,
      'zone_id': zoneId,
      'tarifa_id': tarifaId,
      'alcantarillado': alcantarillado,
      'tipo_lectura': tipoLectura,
      'lectura_inicial': lecturaInicial,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
