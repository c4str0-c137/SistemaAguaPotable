import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sistema_control_agua/core/theme/app_theme.dart';
import 'package:sistema_control_agua/presentation/screens/auth/login_screen.dart';
import 'package:sistema_control_agua/presentation/screens/auth/splash_screen.dart';
import 'package:sistema_control_agua/presentation/screens/home/home_screen.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_event.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_state.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_event.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_event.dart';
import 'package:sistema_control_agua/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const AguaControlApp());
}

class AguaControlApp extends StatelessWidget {
  const AguaControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(AppStarted())),
        BlocProvider(create: (_) => di.sl<SocioBloc>()..add(FetchSocios())),
        BlocProvider(create: (_) => di.sl<ViviendaBloc>()..add(FetchViviendas())),
      ],
      child: MaterialApp(
        title: 'Agua Control',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return _buildHome(state);
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthState state) {
    if (state is Authenticated) {
      return const HomeScreen();
    }
    if (state is AuthInitial) {
      return const SplashScreen();
    }
    // Para Unauthenticated, AuthLoading o AuthError, mostramos el login
    // excepto si es la carga inicial (AuthInitial)
    return const LoginScreen();
  }
}
