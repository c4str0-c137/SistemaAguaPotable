import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/pago_repository.dart';
import 'pago_event.dart';
import 'pago_state.dart';

class PagoBloc extends Bloc<PagoEvent, PagoState> {
  final PagoRepository pagoRepository;

  PagoBloc({required this.pagoRepository}) : super(PagoInitial()) {
    on<CalcularDeudaEvent>((event, emit) async {
      emit(PagoCalculando());
      try {
        final deuda = await pagoRepository.calcularDeuda(event.viviendaId, event.periodoId);
        emit(PagoSuccess(deuda: deuda));
      } catch (e) {
        emit(PagoError('Error al calcular la deuda: $e'));
      }
    });

    on<RegistrarPagoEvent>((event, emit) async {
      emit(PagoLoading());
      try {
        final rawData = await pagoRepository.registrarPago(event.data);
        emit(PagoSuccess(
          rawData: rawData,
          message: 'Pago registrado con éxito',
        ));
      } catch (e) {
        emit(PagoError('Error al registrar pago: $e'));
      }
    });

    on<GetResumenEvent>((event, emit) async {
      emit(PagoLoading());
      try {
        final resumen = await pagoRepository.getResumen();
        emit(PagoSuccess(resumen: resumen));
      } catch (e) {
        emit(PagoError('Error al obtener el resumen: $e'));
      }
    });

    on<GetPagoHistoryEvent>((event, emit) async {
      emit(PagoLoading());
      try {
        final history = await pagoRepository.getPagosByVivienda(event.viviendaId);
        emit(PagoSuccess(history: history));
      } catch (e) {
        emit(PagoError('Error al obtener el historial de pagos: $e'));
      }
    });
  }
}
