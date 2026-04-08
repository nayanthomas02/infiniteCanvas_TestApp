import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Table: tasks ─────────────────────────────────────────────────────────────
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Table: pending_actions ───────────────────────────────────────────────────
class PendingActions extends Table {
  TextColumn get id => text()();
  TextColumn get actionType => text()(); // 'ADD' | 'EDIT' | 'DELETE'
  TextColumn get payload => text()();    // JSON string
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────────────
@DriftDatabase(tables: [Tasks, PendingActions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'perf_task_app_db');
  }

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<void> upsertTask(TasksCompanion task) =>
      into(tasks).insertOnConflictUpdate(task);

  Future<void> deleteTask(String taskId) =>
      (delete(tasks)..where((t) => t.id.equals(taskId))).go();

  Future<List<Task>> getUnsyncedTasks() =>
      (select(tasks)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markTaskSynced(String taskId) => (update(tasks)
        ..where((t) => t.id.equals(taskId)))
      .write(const TasksCompanion(isSynced: Value(true)));

  // ── Pending Actions ────────────────────────────────────────────────────────

  Future<void> insertPendingAction(PendingActionsCompanion action) =>
      into(pendingActions).insert(action);

  Future<List<PendingAction>> getAllPendingActions() =>
      (select(pendingActions)
            ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
          .get();

  Future<void> deletePendingAction(String actionId) =>
      (delete(pendingActions)..where((a) => a.id.equals(actionId))).go();

  Future<void> clearAllPendingActions() => delete(pendingActions).go();
}
