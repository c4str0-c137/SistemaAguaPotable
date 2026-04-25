import 'package:equatable/equatable.dart';

abstract class SocioState extends Equatable {
  const SocioState();
  @override
  List<Object?> get props => [];
}

class SocioInitial extends SocioState {}
class SocioLoading extends SocioState {}
class SocioLoaded extends SocioState {
  final List<dynamic> socios;
  const SocioLoaded(this.socios);
  @override
  List<Object?> get props => [socios];
}
class SocioError extends SocioState {
  final String message;
  const SocioError(this.message);
  @override
  List<Object?> get props => [message];
}
class SocioSuccess extends SocioState {
  final String message;
  const SocioSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
