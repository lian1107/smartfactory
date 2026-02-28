import 'package:flutter/material.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/project_phase.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/utils/format_utils.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  final ProjectPhase phase;
  final List<Task> tasks;
  final void Function(Task task)? onTaskTap;
  final void Function(String taskId, String phaseId, int orderIndex)? onTaskDropped;
  final VoidCallback? onAddTask;

  const KanbanColumn({
    super.key,
    required this.phase,
    required this.tasks,
    this.onTaskTap,
    this.onTaskDropped,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final color = FormatUtils.parseColor(phase.color) ?? AppColors.textSecondary;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phase.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Droppable task area
          Expanded(
            child: DragTarget<Task>(
              onWillAcceptWithDetails: (details) =>
                  details.data.phaseId != phase.id,
              onAcceptWithDetails: (details) {
                final task = details.data;
                onTaskDropped?.call(task.id, phase.id, tasks.length);
              },
              builder: (context, candidateData, rejectedData) {
                final isDragOver = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isDragOver
                        ? color.withOpacity(0.05)
                        : AppColors.surfaceVariant,
                    border: Border.all(
                      color: isDragOver
                          ? color.withOpacity(0.4)
                          : AppColors.border,
                      width: isDragOver ? 2 : 1,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      ...tasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LongPressDraggable<Task>(
                            data: task,
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 260,
                                child: TaskCard(task: task),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCard(task: task),
                            ),
                            child: TaskCard(
                              task: task,
                              onTap: () => onTaskTap?.call(task),
                            ),
                          ),
                        ),
                      ),
                      if (isDragOver)
                        Container(
                          height: 60,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withOpacity(0.4),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '放在这里',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Add task button
          if (onAddTask != null)
            TextButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加任务'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
