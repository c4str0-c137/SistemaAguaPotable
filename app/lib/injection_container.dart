import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/data/repositories/auth/auth_repository_impl.dart';
import 'package:sistema_control_agua/data/repositories/configuracion_repository_impl.dart';
import 'package:sistema_control_agua/data/repositories/lectura_repository_impl.dart';
import 'package:sistema_control_agua/data/repositories/pago_repository_impl.dart';
import 'package:sistema_control_agua/data/repositories/vivienda_repository_impl.dart';
import 'package:sistema_control_agua/domain/repositories/auth_repository.dart';
import 'package:sistema_control_agua/domain/repositories/configuracion_repository.dart';
import 'package:sistema_control_agua/domain/repositories/lectura_repository.dart';
import 'package:sistema_control_agua/domain/repositories/pago_repository.dart';
import 'package:sistema_control_agua/domain/repositories/vivienda_repository.dart';
import 'package:sistema_control_agua/presentation/blocs/auth/auth_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/configuracion/configuracion_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/lectura/lectura_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/pago/pago_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/vivienda/vivienda_bloc.dart';
import 'package:sistema_control_agua/presentation/blocs/socio/socio_bloc.dart';
import 'package:sistema_control_agua/domain/repositories/socio_repository.dart';
import 'package:sistema_control_agua/data/repositories/socio_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  
  // Features - Vivienda
  sl.registerFactory(() => ViviendaBloc(viviendaRepository: sl()));
  
  // Features - Lectura
  sl.registerFactory(() => LecturaBloc(lecturaRepository: sl()));
  sl.registerFactory(() => PagoBloc(pagoRepository: sl()));
  sl.registerFactory(() => ConfiguracionBloc(sl()));
  sl.registerFactory(() => SocioBloc(socioRepository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dioClient: sl(), prefs: sl()),
  );
  sl.registerLazySingleton<ViviendaRepository>(() => ViviendaRepositoryImpl(dioClient: sl()));
  sl.registerLazySingleton<LecturaRepository>(() => LecturaRepositoryImpl(sl<DioClient>().dio));
  sl.registerLazySingleton<PagoRepository>(() => PagoRepositoryImpl(sl<DioClient>().dio));
  sl.registerLazySingleton<ConfiguracionRepository>(() => ConfiguracionRepositoryImpl(sl<DioClient>().dio));
  sl.registerLazySingleton<SocioRepository>(() => SocioRepositoryImpl(dioClient: sl()));

  // Core
  sl.registerLazySingleton(() => DioClient());

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
