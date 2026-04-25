import 'package:equatable/equatable.dart';
import 'package:sistema_control_agua/domain/entities/pago_entity.dart';

abstract class PagoState extends Equatable {
  const PagoState();

  @override
  List<Object?> get props => [];
}

class PagoInitial extends PagoState {}

class PagoLoading extends PagoState {}

class PagoCalculando extends PagoState {}

class PagoSuccess extends PagoState {
  final Map<String, dynamic>? deuda;
  final PagoEntity? pago;
  final Map<String, dynamic>? resumen;
  final List<Map<String, dynamic>>? history;
  final Map<String, dynamic>? rawData;
  final String? message;

  PagoSuccess({this.deuda, this.pago, this.resumen, this.history, this.rawData, this.message});

  @override
  List<Object?> get props => [deuda, pago, resumen, history, rawData, message];
}

class PagoError extends PagoState {
  final String message;
  PagoError(this.message);

  @override
  List<Object?> get props => [message];
}
