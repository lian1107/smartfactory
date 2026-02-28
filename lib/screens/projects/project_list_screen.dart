import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/project.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';
import 'package:smartfactory/widgets/common/empty_state.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';
import 'package:smartfactory/widgets/project/health_badge.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('项目管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(projectListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: canEdit(profile?.role)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/projects/new'),
              icon: const Icon(Icons.add),
              label: const Text('新建项目'),
            )
          : null,
      body: Column(
        children: [
          // Search + filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '搜索项目名称...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                              ref
                                  .read(projectListProvider.notifier)
                                  .setFilter(search: '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    setState(() {});
                    ref
                        .read(projectListProvider.notifier)
                        .setFilter(search: v);
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '全部',
                        isSelected: _statusFilter.isEmpty,
                        onTap: () => _setFilter(''),
                      ),
                      _FilterChip(
                        label: '进行中',
                        isSelected: _statusFilter == 'active',
                        onTap: () => _setFilter('active'),
                      ),
                      _FilterChip(
                        label: '暂停',
                        isSelected: _statusFilter == 'on_hold',
                        onTap: () => _setFilter('on_hold'),
                      ),
                      _FilterChip(
                        label: '已完成',
                        isSelected: _statusFilter == 'completed',
                        onTap: () => _setFilter('completed'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: projectsAsync.when(
              loading: () => const ShimmerCardList(),
              error: (err, _) => ErrorState(
                error: err,
                onRetry: () =>
                    ref.read(projectListProvider.notifier).refresh(),
              ),
              data: (projects) {
                if (projects.isEmpty) {
                  return EmptyState(
                    message: '暂无项目',
                    subMessage: '点击右下角按钮创建第一个项目',
                    icon: Icons.folder_outlined,
                    action: canEdit(profile?.role)
                        ? ElevatedButton(
                            onPressed: () => context.go('/projects/new'),
                            child: const Text('新建项目'),
                          )
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(projectListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _ProjectCard(project: projects[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _setFilter(String status) {
    setState(() => _statusFilter = status);
    ref.read(projectListProvider.notifier).setFilter(status: status);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final statusColor = FormatUtils.statusColor(project.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/projects/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HealthBadge(health: project.health),
                ],
              ),
              if (project.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  project.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      FormatUtils.projectStatusLabel(project.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (project.plannedEndDate != null) ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: project.isOverdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppDateUtils.formatDisplayDate(project.plannedEndDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: project.isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
