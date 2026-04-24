import 'data/repositories/vivienda_repository_impl.dart';
import 'domain/repositories/vivienda_repository.dart';
import 'presentation/blocs/vivienda/vivienda_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  
  // Features - Vivienda
  sl.registerFactory(() => ViviendaBloc(viviendaRepository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dioClient: sl(), prefs: sl()),
  );
  sl.registerLazySingleton<ViviendaRepository>(
    () => ViviendaRepositoryImpl(dioClient: sl()),
  );

  // Core
  sl.registerLazySingleton(() => DioClient());

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
