import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sistema_control_agua/domain/repositories/configuracion_repository.dart';
import 'package:sistema_control_agua/domain/entities/configuracion_entity.dart';
import 'package:sistema_control_agua/presentation/blocs/configuracion/configuracion_event.dart';
import 'package:sistema_control_agua/presentation/blocs/configuracion/configuracion_state.dart';

class ConfiguracionBloc extends Bloc<ConfiguracionEvent, ConfiguracionState> {
  final ConfiguracionRepository repository;

  ConfiguracionBloc(this.repository) : super(ConfiguracionInitial()) {
    on<FetchConfiguracionEvent>((event, emit) async {
      emit(ConfiguracionLoading());
      try {
        final results = await Future.wait([
          repository.getAjustes(),
          repository.getTarifas(),
        ]);
        emit(ConfiguracionLoaded(
          ajustes: results[0] as List<AjusteEntity>,
          tarifas: results[1] as List<TarifaEntity>,
        ));
      } catch (e) {
        emit(ConfiguracionError(e.toString()));
      }
    });

    on<UpdateAjusteEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.updateAjuste(event.clave, event.valor);
        emit(ConfiguracionUpdateSuccess());
        add(FetchConfiguracionEvent());
      } catch (e) {
        emit(ConfiguracionError(e.toString()));
        if (currentState is ConfiguracionLoaded) emit(currentState);
      }
    });

    on<UpdateTarifaEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.updateTarifa(event.id, event.data);
        emit(ConfiguracionUpdateSuccess());
        add(FetchConfiguracionEvent());
      } catch (e) {
        emit(ConfiguracionError(e.toString()));
        if (currentState is ConfiguracionLoaded) emit(currentState);
      }
    });

    on<AddRangoEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.createRango(event.data);
        emit(ConfiguracionUpdateSuccess());
        add(FetchConfiguracionEvent());
      } catch (e) {
        emit(ConfiguracionError(e.toString()));
        if (currentState is ConfiguracionLoaded) emit(currentState);
      }
    });

    on<UpdateRangoEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.updateRango(event.id, event.data);
        emit(ConfiguracionUpdateSuccess());
        add(FetchConfiguracionEvent());
      } catch (e) {
        emit(ConfiguracionError(e.toString()));
        if (currentState is ConfiguracionLoaded) emit(currentState);
      }
    });

    on<DeleteRangoEvent>((event, emit) async {
      final currentState = state;
      try {
        await repository.deleteRango(event.id);
        emit(ConfiguracionUpdateSuccess());
        add(FetchConfiguracionEvent());
      } catch (e) {
        emit(ConfiguracionError(e.toString()));
        if (currentState is ConfiguracionLoaded) emit(currentState);
      }
    });
  }
}
