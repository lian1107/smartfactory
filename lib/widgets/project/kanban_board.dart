import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/models/project_phase.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/providers/task_providers.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/project/kanban_column.dart';
import 'package:smartfactory/widgets/project/task_detail_sheet.dart';

class KanbanBoard extends ConsumerWidget {
  final String projectId;
  final List<ProjectPhase> phases;

  const KanbanBoard({
    super.key,
    required this.projectId,
    required this.phases,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(projectTasksProvider(projectId));

    return tasksAsync.when(
      loading: () => const ShimmerKanban(),
      error: (err, _) => ErrorState(
        error: err,
        onRetry: () => ref
            .read(projectTasksProvider(projectId).notifier)
            .refresh(),
      ),
      data: (allTasks) {
        final sortedPhases = [...phases]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedPhases.map((phase) {
              final phaseTasks = allTasks
                  .where((t) => t.phaseId == phase.id)
                  .toList()
                ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

              return KanbanColumn(
                phase: phase,
                tasks: phaseTasks,
                onTaskTap: (task) => TaskDetailSheet.show(context, task),
                onTaskDropped: (taskId, newPhaseId, newOrderIndex) {
                  ref
                      .read(projectTasksProvider(projectId).notifier)
                      .optimisticMove(
                        taskId: taskId,
                        newPhaseId: newPhaseId,
                        newOrderIndex: newOrderIndex,
                      );
                },
                onAddTask: () => _showAddTaskDialog(context, ref, phase.id),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    String phaseId,
  ) async {
    final titleCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('添加任务'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            hintText: '任务标题',
            isDense: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(projectTasksProvider(projectId).notifier).createTask(
            phaseId: phaseId,
            title: titleCtrl.text.trim(),
          );
    }
  }
}
