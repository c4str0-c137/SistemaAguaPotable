import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/lectura_repository.dart';
import 'lectura_event.dart';
import 'lectura_state.dart';

class LecturaBloc extends Bloc<LecturaEvent, LecturaState> {
  final LecturaRepository lecturaRepository;

  LecturaBloc({required this.lecturaRepository}) : super(LecturaInitial()) {
    on<SaveLecturaEvent>((event, emit) async {
      emit(LecturaLoading());
      try {
        final lectura = await lecturaRepository.saveLectura(event.data);
        emit(LecturaSuccess(lectura: lectura, message: 'Lectura guardada correctamente'));
      } catch (e) {
        emit(LecturaError('Error al guardar la lectura: $e'));
      }
    });

    on<GetLecturaHistoryEvent>((event, emit) async {
      emit(LecturaLoading());
      try {
        final history = await lecturaRepository.getLecturasByVivienda(event.viviendaId);
        emit(LecturaSuccess(history: history));
      } catch (e) {
        emit(LecturaError('Error al obtener el historial: $e'));
      }
    });
  }
}
