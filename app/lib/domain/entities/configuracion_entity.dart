class AjusteEntity {
  final String clave;
  final dynamic valor;
  final String? descripcion;

  AjusteEntity({required this.clave, required this.valor, this.descripcion});
}

class TarifaEntity {
  final int id;
  final String nombre;
  final double montoFijo;
  final List<RangoEntity> rangos;

  TarifaEntity({
    required this.id, 
    required this.nombre, 
    required this.montoFijo, 
    required this.rangos
  });
}

class RangoEntity {
  final int id;
  final int tarifaId;
  final double desde;
  final double? hasta;
  final double precioMetro;

  RangoEntity({
    required this.id, 
    required this.tarifaId, 
    required this.desde, 
    this.hasta, 
    required this.precioMetro
  });
}
