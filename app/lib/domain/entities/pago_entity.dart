class PagoEntity {
  final int id;
  final int viviendaId;
  final int? paymentMethodId;
  final double montoTotal;
  final DateTime fechaPago;
  final String? referencia;

  PagoEntity({
    required this.id,
    required this.viviendaId,
    this.paymentMethodId,
    required this.montoTotal,
    required this.fechaPago,
    this.referencia,
  });
}
