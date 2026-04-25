import 'package:equatable/equatable.dart';
import 'package:sistema_control_agua/domain/entities/lectura_entity.dart';

abstract class LecturaState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LecturaInitial extends LecturaState {}

class LecturaLoading extends LecturaState {}

class LecturaSuccess extends LecturaState {
  final LecturaEntity? lectura;
  final List<LecturaEntity>? history;
  final String? message;

  LecturaSuccess({this.lectura, this.history, this.message});

  @override
  List<Object?> get props => [lectura, history, message];
}

class LecturaError extends LecturaState {
  final String message;
  LecturaError(this.message);

  @override
  List<Object?> get props => [message];
}
