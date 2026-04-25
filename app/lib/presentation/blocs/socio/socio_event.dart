import 'package:equatable/equatable.dart';

abstract class SocioEvent extends Equatable {
  const SocioEvent();
  @override
  List<Object?> get props => [];
}

class FetchSocios extends SocioEvent {}

class CreateSocio extends SocioEvent {
  final Map<String, dynamic> socio;
  const CreateSocio(this.socio);
  @override
  List<Object?> get props => [socio];
}

class UpdateSocio extends SocioEvent {
  final int id;
  final Map<String, dynamic> socio;
  const UpdateSocio({required this.id, required this.socio});
  @override
  List<Object?> get props => [id, socio];
}

class DeleteSocio extends SocioEvent {
  final int id;
  const DeleteSocio(this.id);
  @override
  List<Object?> get props => [id];
}
