import '../../../../domain/entities/vivienda_entity.dart';

abstract class ViviendaState {}

class ViviendaInitial extends ViviendaState {}

class ViviendaLoading extends ViviendaState {}

class ViviendasLoaded extends ViviendaState {
  final List<ViviendaEntity> viviendas;
  ViviendasLoaded({required this.viviendas});
}

class ViviendaOperationSuccess extends ViviendaState {
  final String message;
  ViviendaOperationSuccess({required this.message});
}

class ViviendaError extends ViviendaState {
  final String message;
  ViviendaError({required this.message});
}
