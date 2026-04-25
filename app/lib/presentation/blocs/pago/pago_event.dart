import 'package:equatable/equatable.dart';
import 'package:sistema_control_agua/domain/entities/pago_entity.dart';

abstract class PagoEvent extends Equatable {
  const PagoEvent();

  @override
  List<Object?> get props => [];
}

class CalcularDeudaEvent extends PagoEvent {
  final int viviendaId;
  final int periodoId;
  CalcularDeudaEvent({required this.viviendaId, required this.periodoId});

  @override
  List<Object?> get props => [viviendaId, periodoId];
}

class RegistrarPagoEvent extends PagoEvent {
  final Map<String, dynamic> data;
  RegistrarPagoEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class GetResumenEvent extends PagoEvent {}

class GetPagoHistoryEvent extends PagoEvent {
  final int viviendaId;
  GetPagoHistoryEvent(this.viviendaId);

  @override
  List<Object?> get props => [viviendaId];
}
