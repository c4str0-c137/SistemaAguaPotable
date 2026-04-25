import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sistema_control_agua/domain/repositories/vivienda_repository.dart';
import 'vivienda_event.dart';
import 'vivienda_state.dart';

class ViviendaBloc extends Bloc<ViviendaEvent, ViviendaState> {
  final ViviendaRepository viviendaRepository;

  ViviendaBloc({required this.viviendaRepository}) : super(ViviendaInitial()) {
    on<FetchViviendas>(_onFetchViviendas);
    on<UpdateViviendaGPS>(_onUpdateViviendaGPS);
    on<CreateVivienda>(_onCreateVivienda);
    on<UpdateVivienda>(_onUpdateVivienda);
    on<DeleteVivienda>(_onDeleteVivienda);
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
      add(FetchViviendas());
    } catch (e) {
      emit(ViviendaError(message: e.toString()));
    }
  }

  Future<void> _onCreateVivienda(CreateVivienda event, Emitter<ViviendaState> emit) async {
    emit(ViviendaLoading());
    try {
      await viviendaRepository.createVivienda(event.data);
      emit(ViviendaOperationSuccess(message: 'Vivienda registrada correctamente'));
      add(FetchViviendas());
    } catch (e) {
      emit(ViviendaError(message: e.toString()));
    }
  }

  Future<void> _onUpdateVivienda(UpdateVivienda event, Emitter<ViviendaState> emit) async {
    emit(ViviendaLoading());
    try {
      await viviendaRepository.updateVivienda(event.id, event.data);
      emit(ViviendaOperationSuccess(message: 'Vivienda actualizada correctamente'));
      add(FetchViviendas());
    } catch (e) {
      emit(ViviendaError(message: e.toString()));
    }
  }

  Future<void> _onDeleteVivienda(DeleteVivienda event, Emitter<ViviendaState> emit) async {
    emit(ViviendaLoading());
    try {
      await viviendaRepository.deleteVivienda(event.id);
      emit(ViviendaOperationSuccess(message: 'Vivienda eliminada correctamente'));
      add(FetchViviendas());
    } catch (e) {
      emit(ViviendaError(message: 'No se pudo eliminar la vivienda. Verifique si tiene historial.'));
    }
  }
}
