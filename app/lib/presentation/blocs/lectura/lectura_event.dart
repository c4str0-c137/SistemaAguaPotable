import 'package:equatable/equatable.dart';
import 'package:sistema_control_agua/domain/entities/lectura_entity.dart';

abstract class LecturaEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SaveLecturaEvent extends LecturaEvent {
  final Map<String, dynamic> data;
  SaveLecturaEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class GetLecturaHistoryEvent extends LecturaEvent {
  final int viviendaId;
  GetLecturaHistoryEvent(this.viviendaId);

  @override
  List<Object?> get props => [viviendaId];
}
