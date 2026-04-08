import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/task_entity.dart';

class TaskItemTile extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItemTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Deterministic avatar seed from task id
    final avatarSeed = task.id.hashCode.abs() % 1000;
    final avatarUrl = 'https://picsum.photos/seed/$avatarSeed/80/80';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: _DeleteBackground(),
        confirmDismiss: (_) async {
          onDelete();
          return false; // Let BLoC/stream handle the removal
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: task.isSynced
                  ? Colors.transparent
                  : const Color(0xFFFF9800).withAlpha(60),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: GestureDetector(
              onTap: onToggle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Avatar image
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF0D0D1A),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white24, size: 24),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF0D0D1A),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white24, size: 24),
                      ),
                    ),
                  ),
                  // Done overlay
                  if (task.isDone)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xBB03DAC6),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 22, color: Colors.black),
                    ),
                ],
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                color: task.isDone ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w600,
                decoration:
                    task.isDone ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white38,
              ),
            ),
            subtitle: task.description.isNotEmpty
                ? Text(
                    task.description,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sync indicator
                if (!task.isSynced)
                  const Tooltip(
                    message: 'Pending sync',
                    child: Icon(Icons.schedule_rounded,
                        size: 16, color: Color(0xFFFF9800)),
                  ),
                const SizedBox(width: 4),
                // Edit button
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Colors.white38),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCF6679).withAlpha(30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.delete_outline_rounded,
          color: Color(0xFFCF6679), size: 24),
    );
  }
}
