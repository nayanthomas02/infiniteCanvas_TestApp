import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskEntity copyWith({
    String? title,
    String? description,
    bool? isDone,
    bool? isSynced,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, description, isDone, isSynced];
}
