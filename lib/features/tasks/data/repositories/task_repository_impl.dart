import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../services/task_api_service.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../../core/constants/app_constants.dart';

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase db;
  final TaskApiService apiService;
  final _uuid = const Uuid();

  TaskRepositoryImpl({required this.db, required this.apiService});

  // ─── Map Drift model → Domain entity ─────────────────────────────────────
  TaskEntity _toEntity(Task t) => TaskEntity(
        id: t.id,
        title: t.title,
        description: t.description,
        isDone: t.isDone,
        isSynced: t.isSynced,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  // ─── Watch ───────────────────────────────────────────────────────────────
  @override
  Stream<List<TaskEntity>> watchAllTasks() =>
      db.watchAllTasks().map((list) => list.map(_toEntity).toList());

  // ─── Add (Optimistic) ────────────────────────────────────────────────────
  @override
  Future<void> addTask(TaskEntity task) async {
    // 1. Write to local DB immediately (optimistic)
    await db.upsertTask(TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      isDone: Value(task.isDone),
      isSynced: const Value(false),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
    ));

    // 2. Queue pending action
    await db.insertPendingAction(PendingActionsCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(AppConstants.pendingActionAdd),
      payload: Value(jsonEncode({
        'id': task.id,
        'title': task.title,
        'description': task.description,
      })),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ─── Edit (Optimistic) ───────────────────────────────────────────────────
  @override
  Future<void> editTask(TaskEntity task) async {
    // 1. Update locally
    await db.upsertTask(TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      isDone: Value(task.isDone),
      isSynced: const Value(false),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
    ));

    // 2. Queue pending action
    await db.insertPendingAction(PendingActionsCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(AppConstants.pendingActionEdit),
      payload: Value(jsonEncode({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'isDone': task.isDone,
      })),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ─── Delete (Optimistic) ─────────────────────────────────────────────────
  @override
  Future<void> deleteTask(String taskId) async {
    // 1. Delete locally
    await db.deleteTask(taskId);

    // 2. Queue pending action
    await db.insertPendingAction(PendingActionsCompanion(
      id: Value(_uuid.v4()),
      actionType: const Value(AppConstants.pendingActionDelete),
      payload: Value(jsonEncode({'id': taskId})),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ─── Sync (flush pending actions queue) ──────────────────────────────────
  @override
  Future<void> syncPendingActions() async {
    final pending = await db.getAllPendingActions();
    if (pending.isEmpty) return;

    final List<String> failedActionIds = [];

    for (final action in pending) {
      final payload = jsonDecode(action.payload) as Map<String, dynamic>;
      bool success = false;

      try {
        switch (action.actionType) {
          case AppConstants.pendingActionAdd:
            success = await apiService.addTask(payload);
            if (success) {
              await db.markTaskSynced(payload['id'] as String);
            }
            break;
          case AppConstants.pendingActionEdit:
            success =
                await apiService.editTask(payload['id'] as String, payload);
            if (success) {
              await db.markTaskSynced(payload['id'] as String);
            }
            break;
          case AppConstants.pendingActionDelete:
            success = await apiService.deleteTask(payload['id'] as String);
            break;
        }
      } catch (_) {
        success = false;
      }

      if (success) {
        await db.deletePendingAction(action.id);
      } else {
        failedActionIds.add(action.id);
      }
    }

    if (failedActionIds.isNotEmpty) {
      throw SyncException(
        'Failed to sync ${failedActionIds.length} action(s). Will retry on next connection.',
      );
    }
  }
}

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);
  @override
  String toString() => message;
}
