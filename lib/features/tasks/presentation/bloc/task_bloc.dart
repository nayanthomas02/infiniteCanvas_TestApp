import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final String title;
  final String description;
  AddTask({required this.title, required this.description});
  @override
  List<Object?> get props => [title, description];
}

class EditTask extends TaskEvent {
  final TaskEntity task;
  EditTask(this.task);
  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;
  DeleteTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class ToggleTask extends TaskEvent {
  final TaskEntity task;
  ToggleTask(this.task);
  @override
  List<Object?> get props => [task];
}

class SyncTasks extends TaskEvent {}

class ConnectivityChanged extends TaskEvent {
  final bool isOnline;
  ConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

// ─── State ───────────────────────────────────────────────────────────────────
class TaskState extends Equatable {
  final List<TaskEntity> tasks;
  final bool isLoading;
  final bool isSyncing;
  final bool isOnline;
  final String? syncError; // One-shot — consumed by BlocListener for Snackbar
  final int pendingCount;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.isOnline = true,
    this.syncError,
    this.pendingCount = 0,
  });

  TaskState copyWith({
    List<TaskEntity>? tasks,
    bool? isLoading,
    bool? isSyncing,
    bool? isOnline,
    String? syncError,
    bool clearSyncError = false,
    int? pendingCount,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }

  @override
  List<Object?> get props =>
      [tasks, isLoading, isSyncing, isOnline, syncError, pendingCount];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;
  final _uuid = const Uuid();
  StreamSubscription<List<TaskEntity>>? _taskSub;

  TaskBloc({required this.repository}) : super(const TaskState()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<EditTask>(_onEditTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTask>(_onToggleTask);
    on<SyncTasks>(_onSyncTasks);
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach<List<TaskEntity>>(
      repository.watchAllTasks(),
      onData: (tasks) {
        final pending = tasks.where((t) => !t.isSynced).length;
        return state.copyWith(
          tasks: tasks,
          isLoading: false,
          pendingCount: pending,
          clearSyncError: true,
        );
      },
      onError: (_, __) => state.copyWith(isLoading: false),
    );
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    final now = DateTime.now();
    final task = TaskEntity(
      id: _uuid.v4(),
      title: event.title,
      description: event.description,
      isDone: false,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );
    await repository.addTask(task);
  }

  Future<void> _onEditTask(EditTask event, Emitter<TaskState> emit) async {
    await repository.editTask(event.task);
  }

  Future<void> _onToggleTask(ToggleTask event, Emitter<TaskState> emit) async {
    final updated = event.task.copyWith(isDone: !event.task.isDone);
    await repository.editTask(updated);
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    await repository.deleteTask(event.taskId);
  }

  Future<void> _onSyncTasks(SyncTasks event, Emitter<TaskState> emit) async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true, clearSyncError: true));
    try {
      await repository.syncPendingActions();
      emit(state.copyWith(isSyncing: false));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      ));
    }
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
    if (event.isOnline) {
      add(SyncTasks());
    }
  }

  @override
  Future<void> close() {
    _taskSub?.cancel();
    return super.close();
  }
}
