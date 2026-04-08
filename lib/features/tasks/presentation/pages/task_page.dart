import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/task_bloc.dart';
import '../cubit/connectivity_cubit.dart';
import '../widgets/task_item_tile.dart';
import '../widgets/add_edit_task_dialog.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── Listen for connectivity changes → push to TaskBloc ────────
        BlocListener<ConnectivityCubit, ConnectivityState>(
          listener: (context, state) {
            context
                .read<TaskBloc>()
                .add(ConnectivityChanged(state.isOnline));
          },
        ),
        // ── Listen for sync error → show Snackbar side effect ─────────
        BlocListener<TaskBloc, TaskState>(
          listenWhen: (prev, curr) =>
              curr.syncError != null && curr.syncError != prev.syncError,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.sync_problem_rounded,
                        color: Color(0xFFCF6679), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.syncError ?? 'Sync failed',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: const Color(0xFF6C63FF),
                  onPressed: () =>
                      context.read<TaskBloc>().add(SyncTasks()),
                ),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ─────────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: const Text('Task Manager'),
                  actions: [
                    // Sync status indicator
                    if (state.isSyncing)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      )
                    else if (state.pendingCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Tooltip(
                          message: '${state.pendingCount} unsynced item(s)',
                          child: Badge(
                            label: Text('${state.pendingCount}'),
                            backgroundColor: const Color(0xFFFF9800),
                            child: const Icon(Icons.sync_rounded,
                                color: Colors.white54),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () =>
                          context.read<TaskBloc>().add(SyncTasks()),
                      icon: const Icon(Icons.cloud_sync_rounded),
                      tooltip: 'Force sync',
                    ),
                  ],
                ),

                // ── Offline Banner ───────────────────────────────────
                SliverToBoxAdapter(
                  child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
                    builder: (context, connState) {
                      if (connState.isOnline) return const SizedBox.shrink();
                      return _OfflineBanner();
                    },
                  ),
                ),

                // ── Stats Row ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _StatsRow(state: state),
                ),

                // ── Empty state ──────────────────────────────────────
                if (state.tasks.isEmpty && !state.isLoading)
                  const SliverFillRemaining(
                    child: _EmptyState(),
                  ),

                // ── Task List ────────────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = state.tasks[index];
                      return TaskItemTile(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: () => context
                            .read<TaskBloc>()
                            .add(ToggleTask(task)),
                        onDelete: () => context
                            .read<TaskBloc>()
                            .add(DeleteTask(task.id)),
                        onEdit: () => _showEditDialog(context, task),
                      );
                    },
                    childCount: state.tasks.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Task'),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTaskDialog(
        onSave: (title, desc) {
          context.read<TaskBloc>().add(AddTask(
                title: title,
                description: desc,
              ));
        },
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, task) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTaskDialog(
        initialTitle: task.title,
        initialDescription: task.description,
        onSave: (title, desc) {
          ctx.read<TaskBloc>().add(EditTask(
                task.copyWith(title: title, description: desc),
              ));
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCF6679).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCF6679).withAlpha(80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Color(0xFFCF6679), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You\'re offline. Changes will sync when connection restores.',
              style:
                  TextStyle(color: Color(0xFFCF6679), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TaskState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.tasks.length;
    final done = state.tasks.where((t) => t.isDone).length;
    final pending = state.pendingCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _Stat(label: 'Total', value: '$total', icon: Icons.list_alt_rounded, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          _Stat(label: 'Done', value: '$done', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF03DAC6)),
          const SizedBox(width: 10),
          _Stat(label: 'Pending Sync', value: '$pending', icon: Icons.pending_actions_rounded, color: const Color(0xFFFF9800)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 56,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 20),
          const Text('No tasks yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap the button below to add your first task', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
