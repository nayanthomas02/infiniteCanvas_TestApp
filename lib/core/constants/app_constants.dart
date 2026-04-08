class AppConstants {
  // Infinite Canvas
  static const int pageSize = 15;
  static const int imageCacheWidth = 600;
  static const double fastScrollVelocityThreshold = 3000.0;

  // Task Manager
  static const String pendingActionAdd = 'ADD';
  static const String pendingActionEdit = 'EDIT';
  static const String pendingActionDelete = 'DELETE';

  // Mock API
  static const int mockApiDelayMs = 800;
  static const double mockApiFailureRate = 0.3; // 30% failure for demo
}
