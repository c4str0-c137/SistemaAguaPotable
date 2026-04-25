import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sistema_control_agua/domain/repositories/socio_repository.dart';
import 'socio_event.dart';
import 'socio_state.dart';

class SocioBloc extends Bloc<SocioEvent, SocioState> {
  final SocioRepository socioRepository;

  SocioBloc({required this.socioRepository}) : super(SocioInitial()) {
    print('SocioBloc: Constructor called.');
    on<FetchSocios>((event, emit) async {
      print('SocioBloc: Handling FetchSocios event...');
      emit(SocioLoading());
      try {
        final socios = await socioRepository.getSocios();
        print('SocioBloc: Fetched ${socios.length} socios.');
        emit(SocioLoaded(socios));
      } catch (e, stack) {
        print('SocioBloc: Error fetching socios: $e');
        print('SocioBloc: StackTrace: $stack');
        emit(SocioError(e.toString()));
      }
    });

    on<CreateSocio>((event, emit) async {
      emit(SocioLoading());
      try {
        await socioRepository.createSocio(event.socio);
        add(FetchSocios());
        emit(const SocioSuccess('Socio creado correctamente'));
      } catch (e) {
        emit(SocioError(e.toString()));
      }
    });

    on<UpdateSocio>((event, emit) async {
      emit(SocioLoading());
      try {
        await socioRepository.updateSocio(event.id, event.socio);
        add(FetchSocios());
        emit(const SocioSuccess('Socio actualizado correctamente'));
      } catch (e) {
        emit(SocioError(e.toString()));
      }
    });

    on<DeleteSocio>((event, emit) async {
      emit(SocioLoading());
      try {
        await socioRepository.deleteSocio(event.id);
        add(FetchSocios());
        emit(const SocioSuccess('Socio eliminado correctamente'));
      } catch (e) {
        emit(const SocioError('No se pudo eliminar el socio. Verifique si tiene conexiones activas.'));
      }
    });
  }
}
