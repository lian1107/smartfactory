import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/providers/task_providers.dart';
import 'package:smartfactory/providers/realtime_providers.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';
import 'package:smartfactory/widgets/common/empty_state.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';
import 'package:smartfactory/widgets/project/task_detail_sheet.dart';

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to realtime updates for my tasks
    ref.watch(myTaskRealtimeSubscriptionProvider);

    final tasksAsync = ref.watch(myTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的工作台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(myTasksProvider.notifier).refresh(),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const ShimmerCardList(),
        error: (err, _) => ErrorState(
          error: err,
          onRetry: () => ref.read(myTasksProvider.notifier).refresh(),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const EmptyState(
              message: '暂无待办任务',
              subMessage: '你没有被分配的未完成任务',
              icon: Icons.check_circle_outline,
            );
          }

          final now = DateTime.now();
          final overdue = tasks.where((t) => t.isOverdue).toList();
          final todayTasks = tasks
              .where((t) => !t.isOverdue && t.isDueToday)
              .toList();
          final thisWeek = tasks
              .where((t) =>
                  !t.isOverdue && !t.isDueToday && AppDateUtils.isDueThisWeek(t.dueDate))
              .toList();
          final upcoming = tasks
              .where((t) =>
                  !t.isOverdue &&
                  !t.isDueToday &&
                  !AppDateUtils.isDueThisWeek(t.dueDate))
              .toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(myTasksProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (overdue.isNotEmpty) ...[
                  _GroupHeader(
                    title: '逾期',
                    count: overdue.length,
                    color: AppColors.error,
                    icon: Icons.warning_amber_rounded,
                  ),
                  ...overdue.map((t) => _TaskTile(task: t)),
                  const SizedBox(height: 16),
                ],
                if (todayTasks.isNotEmpty) ...[
                  _GroupHeader(
                    title: '今天',
                    count: todayTasks.length,
                    color: AppColors.warning,
                    icon: Icons.today,
                  ),
                  ...todayTasks.map((t) => _TaskTile(task: t)),
                  const SizedBox(height: 16),
                ],
                if (thisWeek.isNotEmpty) ...[
                  _GroupHeader(
                    title: '本周',
                    count: thisWeek.length,
                    color: AppColors.info,
                    icon: Icons.date_range,
                  ),
                  ...thisWeek.map((t) => _TaskTile(task: t)),
                  const SizedBox(height: 16),
                ],
                if (upcoming.isNotEmpty) ...[
                  _GroupHeader(
                    title: '后续',
                    count: upcoming.length,
                    color: AppColors.textSecondary,
                    icon: Icons.schedule,
                  ),
                  ...upcoming.map((t) => _TaskTile(task: t)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _GroupHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final Task task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = FormatUtils.priorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => TaskDetailSheet.show(context, task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Priority dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '截止: ${AppDateUtils.formatDisplayDate(task.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isOverdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Quick status toggle
              _StatusToggle(task: task),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusToggle extends ConsumerWidget {
  final Task task;

  const _StatusToggle({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = task.status == 'done';
    return IconButton(
      icon: Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isDone ? AppColors.success : AppColors.textDisabled,
      ),
      onPressed: () async {
        await ref.read(myTasksProvider.notifier).updateTask(
          task.id,
          {'status': isDone ? 'in_progress' : 'done'},
        );
      },
    );
  }
}
