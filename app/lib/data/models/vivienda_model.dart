import '../../../domain/entities/vivienda_entity.dart';

class ViviendaModel extends ViviendaEntity {
  const ViviendaModel({
    required super.id,
    required super.codigo,
    required super.direccion,
    required super.socioName,
    required super.zonaName,
    super.latitude,
    super.longitude,
  });

  factory ViviendaModel.fromJson(Map<String, dynamic> json) {
    return ViviendaModel(
      id: json['id'],
      codigo: json['codigo'],
      direccion: json['direccion'],
      socioName: json['socio']?['name'] ?? 'Sin asignar',
      zonaName: json['zona']?['name'] ?? 'Sin zona',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'direccion': direccion,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
