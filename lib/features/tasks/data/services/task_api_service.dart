import 'dart:math';

/// Simulates a backend REST API for tasks
/// Returns true on success, false on failure (with configurable failure rate)
class TaskApiService {
  final _random = Random();

  // Simulates 30% failure rate to demonstrate rollback/snackbar
  static const _failureRate = 0.3;

  Future<bool> addTask(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _random.nextDouble() > _failureRate;
  }

  Future<bool> editTask(String id, Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _random.nextDouble() > _failureRate;
  }

  Future<bool> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _random.nextDouble() > _failureRate;
  }
}
