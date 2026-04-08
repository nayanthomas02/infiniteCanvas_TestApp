import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../features/canvas/data/repositories/canvas_repository_impl.dart';
import '../../features/canvas/data/services/mock_api_service.dart';
import '../../features/canvas/domain/repositories/canvas_repository.dart';
import '../../features/canvas/presentation/bloc/canvas_bloc.dart';
import '../../features/tasks/data/database/app_database.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/data/services/task_api_service.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/presentation/bloc/task_bloc.dart';
import '../../features/tasks/presentation/cubit/connectivity_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ────────────────────────────────────────────────
  sl.registerSingleton<Dio>(Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )));

  // ─── Database ────────────────────────────────────────────────
  sl.registerSingleton<AppDatabase>(AppDatabase());

  // ─── Services ────────────────────────────────────────────────
  sl.registerLazySingleton<MockApiService>(() => MockApiService());
  sl.registerLazySingleton<TaskApiService>(() => TaskApiService());

  // ─── Repositories ────────────────────────────────────────────
  sl.registerLazySingleton<CanvasRepository>(
    () => CanvasRepositoryImpl(sl<MockApiService>()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      db: sl<AppDatabase>(),
      apiService: sl<TaskApiService>(),
    ),
  );

  // ─── BLoCs / Cubits ──────────────────────────────────────────
  sl.registerFactory<CanvasBloc>(
    () => CanvasBloc(repository: sl<CanvasRepository>()),
  );
  sl.registerFactory<TaskBloc>(
    () => TaskBloc(repository: sl<TaskRepository>()),
  );
  sl.registerFactory<ConnectivityCubit>(
    () => ConnectivityCubit(),
  );
}
