import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sistema_control_agua/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      emit(Authenticated(user: user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthBloc: Iniciando login para ${event.email}');
    try {
      final user = await authRepository.login(event.email, event.password);
      if (user != null) {
        print('AuthBloc: Login exitoso para ${user.name}');
        emit(Authenticated(user: user));
      } else {
        print('AuthBloc: Login fallido (user null)');
        emit(AuthError(message: 'Login fallido: Credenciales incorrectas'));
      }
    } catch (e) {
      print('AuthBloc: Error en login: $e');
      String msg = e.toString();
      if (msg.contains('Exception: ')) msg = msg.replaceAll('Exception: ', '');
      emit(AuthError(message: 'Error: $msg'));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(Unauthenticated());
  }
}
