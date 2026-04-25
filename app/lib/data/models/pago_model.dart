import '../../domain/entities/pago_entity.dart';

class PagoModel extends PagoEntity {
  PagoModel({
    required super.id,
    required super.viviendaId,
    super.paymentMethodId,
    required super.montoTotal,
    required super.fechaPago,
    super.referencia,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: json['id'],
      viviendaId: json['vivienda_id'],
      paymentMethodId: json['payment_method_id'],
      montoTotal: (json['monto_total'] as num).toDouble(),
      fechaPago: DateTime.parse(json['fecha_pago']),
      referencia: json['referencia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vivienda_id': viviendaId,
      'payment_method_id': paymentMethodId,
      'monto_total': montoTotal,
      'fecha_pago': fechaPago.toIso8601String(),
      'referencia': referencia,
    };
  }
}
