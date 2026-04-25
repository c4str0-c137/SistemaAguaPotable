import 'package:equatable/equatable.dart';
import 'package:sistema_control_agua/domain/entities/configuracion_entity.dart';

abstract class ConfiguracionState extends Equatable {
  const ConfiguracionState();

  @override
  List<Object?> get props => [];
}

class ConfiguracionInitial extends ConfiguracionState {}

class ConfiguracionLoading extends ConfiguracionState {}

class ConfiguracionLoaded extends ConfiguracionState {
  final List<AjusteEntity> ajustes;
  final List<TarifaEntity> tarifas;

  ConfiguracionLoaded({required this.ajustes, required this.tarifas});

  @override
  List<Object?> get props => [ajustes, tarifas];
}

class ConfiguracionError extends ConfiguracionState {
  final String message;

  ConfiguracionError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConfiguracionUpdateSuccess extends ConfiguracionState {}
