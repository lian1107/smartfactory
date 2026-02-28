import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/models/task_comment.dart';
import 'package:smartfactory/providers/task_providers.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaskDetailSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync =
        ref.watch(taskCommentsProvider(widget.task.id));
    final mediaQuery = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Title
                  Text(
                    widget.task.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  // Meta chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.flag_outlined,
                        label: FormatUtils.priorityLabel(widget.task.priority),
                        color: FormatUtils.priorityColor(widget.task.priority),
                      ),
                      _MetaChip(
                        icon: Icons.circle_outlined,
                        label: FormatUtils.taskStatusLabel(widget.task.status),
                        color: FormatUtils.statusColor(widget.task.status),
                      ),
                      if (widget.task.dueDate != null)
                        _MetaChip(
                          icon: Icons.calendar_today_outlined,
                          label: AppDateUtils.formatDisplayDate(
                              widget.task.dueDate),
                          color: widget.task.isOverdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                    ],
                  ),
                  if (widget.task.description != null &&
                      widget.task.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '描述',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.task.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Comments section
                  Row(
                    children: [
                      const Text(
                        '评论',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      commentsAsync.when(
                        data: (comments) => Text(
                          '(${comments.length})',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  commentsAsync.when(
                    data: (comments) => comments.isEmpty
                        ? const Text(
                            '暂无评论',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          )
                        : Column(
                            children: comments
                                .map((c) => _CommentTile(comment: c))
                                .toList(),
                          ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('加载失败: $e'),
                  ),
                  const SizedBox(height: 16),
                  // Add comment
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(
                            hintText: '添加评论...',
                            isDense: true,
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _submitting ? null : _submitComment,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(taskCommentsProvider(widget.task.id).notifier)
          .addComment(text);
      _commentCtrl.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final TaskComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              comment.authorId.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorId.substring(0, 8),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.formatRelative(comment.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
