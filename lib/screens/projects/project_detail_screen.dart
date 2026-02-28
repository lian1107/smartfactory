import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/project.dart';
import 'package:smartfactory/models/project_phase.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/realtime_providers.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';
import 'package:smartfactory/widgets/common/confirm_dialog.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';
import 'package:smartfactory/widgets/project/health_badge.dart';
import 'package:smartfactory/widgets/project/kanban_board.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to realtime task updates
    ref.watch(taskRealtimeSubscriptionProvider(projectId));

    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final phasesAsync = ref.watch(projectPhasesProvider(projectId));

    return projectAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingState(),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(error: err),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorState(error: '项目不存在'),
          );
        }
        return _ProjectView(
          project: project,
          phasesAsync: phasesAsync,
        );
      },
    );
  }
}

class _ProjectView extends ConsumerWidget {
  final Project project;
  final AsyncValue<List<ProjectPhase>> phasesAsync;

  const _ProjectView({
    required this.project,
    required this.phasesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: const TextStyle(fontSize: 17),
            ),
            Row(
              children: [
                HealthBadge(health: project.health, showLabel: false),
                const SizedBox(width: 4),
                Text(
                  FormatUtils.projectStatusLabel(project.status),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (canEdit(profile?.role))
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, ref, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('编辑项目'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: project.status == 'active' ? 'hold' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        project.status == 'active'
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(project.status == 'active' ? '暂停项目' : '恢复项目'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18,
                          color: AppColors.success),
                      SizedBox(width: 8),
                      Text('标记完成'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('删除项目',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Project summary bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (project.plannedEndDate != null) ...[
                  const Icon(Icons.calendar_today_outlined, size: 14,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '截止: ${AppDateUtils.formatDisplayDate(project.plannedEndDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: project.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                const Spacer(),
                phasesAsync.when(
                  data: (phases) => Text(
                    '${phases.length} 个阶段',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Kanban board
          Expanded(
            child: phasesAsync.when(
              loading: () => const ShimmerKanban(),
              error: (err, _) => ErrorState(error: err),
              data: (phases) => phases.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_kanban_outlined,
                              size: 48, color: AppColors.textDisabled),
                          SizedBox(height: 12),
                          Text(
                            '该项目没有阶段',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : KanbanBoard(
                      projectId: project.id,
                      phases: phases,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        // TODO: implement project edit screen
        break;
      case 'hold':
        await ref
            .read(projectRepositoryProvider)
            .updateProject(project.id, {'status': 'on_hold'});
        ref.invalidate(projectDetailProvider(project.id));
        break;
      case 'activate':
        await ref
            .read(projectRepositoryProvider)
            .updateProject(project.id, {'status': 'active'});
        ref.invalidate(projectDetailProvider(project.id));
        break;
      case 'complete':
        final ok = await ConfirmDialog.show(
          context,
          title: '标记完成',
          message: '确认将项目"${project.title}"标记为已完成？',
        );
        if (ok) {
          await ref.read(projectRepositoryProvider).updateProject(
                project.id,
                {'status': 'completed', 'actual_end_date': DateTime.now().toIso8601String().substring(0, 10)},
              );
          ref.invalidate(projectDetailProvider(project.id));
        }
        break;
      case 'delete':
        final ok = await ConfirmDialog.show(
          context,
          title: '删除项目',
          message: '确认删除项目"${project.title}"？所有任务将被一并删除，此操作不可撤销。',
          confirmLabel: '删除',
          isDestructive: true,
        );
        if (ok && context.mounted) {
          await ref
              .read(projectRepositoryProvider)
              .deleteProject(project.id);
          ref.read(projectListProvider.notifier).refresh();
          if (context.mounted) context.go('/projects');
        }
        break;
    }
  }
}
