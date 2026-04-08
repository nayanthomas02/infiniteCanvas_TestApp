import '../entities/task_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> watchAllTasks();
  Future<void> addTask(TaskEntity task);
  Future<void> editTask(TaskEntity task);
  Future<void> deleteTask(String taskId);
  Future<void> syncPendingActions();
}
