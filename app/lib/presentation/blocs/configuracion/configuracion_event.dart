import 'package:equatable/equatable.dart';

abstract class ConfiguracionEvent extends Equatable {
  const ConfiguracionEvent();

  @override
  List<Object?> get props => [];
}

class FetchConfiguracionEvent extends ConfiguracionEvent {}

class UpdateAjusteEvent extends ConfiguracionEvent {
  final String clave;
  final dynamic valor;

  const UpdateAjusteEvent({required this.clave, required this.valor});

  @override
  List<Object?> get props => [clave, valor];
}

class UpdateTarifaEvent extends ConfiguracionEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateTarifaEvent({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class AddRangoEvent extends ConfiguracionEvent {
  final Map<String, dynamic> data;

  const AddRangoEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

class UpdateRangoEvent extends ConfiguracionEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateRangoEvent({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class DeleteRangoEvent extends ConfiguracionEvent {
  final int id;

  const DeleteRangoEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
