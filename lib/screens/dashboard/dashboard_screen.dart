import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/project.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/task_providers.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';
import 'package:smartfactory/widgets/dashboard/stat_card.dart';
import 'package:smartfactory/widgets/project/health_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final myTasksAsync = ref.watch(myTasksProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('仪表盘'),
            if (profile != null)
              Text(
                '你好，${profile.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(projectListProvider.notifier).refresh();
              ref.read(myTasksProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(projectListProvider.notifier).refresh();
          ref.read(myTasksProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              projectsAsync.when(
                data: (projects) => myTasksAsync.when(
                  data: (myTasks) => _StatsGrid(
                    projects: projects,
                    myTaskCount: myTasks.length,
                    overdueTaskCount:
                        myTasks.where((t) => t.isOverdue).length,
                  ),
                  loading: () => const ShimmerCardList(count: 4, cardHeight: 100),
                  error: (e, _) => const SizedBox(),
                ),
                loading: () =>
                    const ShimmerCardList(count: 4, cardHeight: 100),
                error: (e, _) => ErrorState(error: e),
              ),
              const SizedBox(height: 24),

              // Active projects
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '进行中的项目',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/projects'),
                    child: const Text('查看全部'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              projectsAsync.when(
                data: (projects) {
                  final active = projects
                      .where((p) => p.status == 'active')
                      .take(5)
                      .toList();
                  if (active.isEmpty) {
                    return const Text(
                      '暂无进行中的项目',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  return Column(
                    children: active
                        .map((p) => _ProjectTile(project: p))
                        .toList(),
                  );
                },
                loading: () =>
                    const ShimmerCardList(count: 3, cardHeight: 80),
                error: (e, _) => ErrorState(error: e),
              ),

              const SizedBox(height: 24),

              // Overdue tasks
              myTasksAsync.when(
                data: (tasks) {
                  final overdue = tasks.where((t) => t.isOverdue).toList();
                  if (overdue.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '逾期任务 (${overdue.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...overdue.take(3).map(
                            (t) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.assignment_late,
                                  color: AppColors.error, size: 20),
                              title: Text(t.title),
                              subtitle: Text(
                                '截止: ${AppDateUtils.formatDisplayDate(t.dueDate)}',
                                style: const TextStyle(color: AppColors.error),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<Project> projects;
  final int myTaskCount;
  final int overdueTaskCount;

  const _StatsGrid({
    required this.projects,
    required this.myTaskCount,
    required this.overdueTaskCount,
  });

  @override
  Widget build(BuildContext context) {
    final active = projects.where((p) => p.status == 'active').length;
    final completed = projects.where((p) => p.status == 'completed').length;

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        StatCard(
          label: '进行中项目',
          value: '$active',
          icon: Icons.folder_open,
          color: AppColors.info,
        ),
        StatCard(
          label: '已完成项目',
          value: '$completed',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
        StatCard(
          label: '我的任务',
          value: '$myTaskCount',
          icon: Icons.assignment_outlined,
          color: AppColors.primary,
        ),
        StatCard(
          label: '逾期任务',
          value: '$overdueTaskCount',
          icon: Icons.warning_amber_outlined,
          color: overdueTaskCount > 0 ? AppColors.error : AppColors.success,
        ),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;

  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: FormatUtils.statusColor(project.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.folder,
            color: FormatUtils.statusColor(project.status),
            size: 20,
          ),
        ),
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: project.plannedEndDate != null
            ? Text(
                '截止: ${AppDateUtils.formatDisplayDate(project.plannedEndDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: project.isOverdue
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              )
            : null,
        trailing: HealthBadge(health: project.health),
        onTap: () => context.go('/projects/${project.id}'),
      ),
    );
  }
}
