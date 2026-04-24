import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/vivienda_repository.dart';
import 'vivienda_event.dart';
import 'vivienda_state.dart';

class ViviendaBloc extends Bloc<ViviendaEvent, ViviendaState> {
  final ViviendaRepository viviendaRepository;

  ViviendaBloc({required this.viviendaRepository}) : super(ViviendaInitial()) {
    on<FetchViviendas>(_onFetchViviendas);
    on<UpdateViviendaGPS>(_onUpdateViviendaGPS);
  }

  Future<void> _onFetchViviendas(FetchViviendas event, Emitter<ViviendaState> emit) async {
    emit(ViviendaLoading());
    try {
      final viviendas = await viviendaRepository.getViviendas();
      emit(ViviendasLoaded(viviendas: viviendas));
    } catch (e) {
      emit(ViviendaError(message: e.toString()));
    }
  }

  Future<void> _onUpdateViviendaGPS(UpdateViviendaGPS event, Emitter<ViviendaState> emit) async {
    emit(ViviendaLoading());
    try {
      await viviendaRepository.updateGPS(event.id, event.latitude, event.longitude);
      emit(ViviendaOperationSuccess(message: 'GPS actualizado correctamente'));
      add(FetchViviendas()); // Refresh list
    } catch (e) {
      emit(ViviendaError(message: e.toString()));
    }
  }
}
