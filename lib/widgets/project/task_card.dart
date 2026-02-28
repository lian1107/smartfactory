import 'package:flutter/material.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/task.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? AppColors.error.withOpacity(0.5) : AppColors.border,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority dot + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: FormatUtils.priorityColor(task.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: task.status == 'done'
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == 'done'
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              // Bottom row: due date + status
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: isOverdue ? AppColors.error : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppDateUtils.formatDisplayDate(task.dueDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? AppColors.error : AppColors.textSecondary,
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  _StatusChip(status: task.status),
                ],
              ),
              // Tags
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: task.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = FormatUtils.statusColor(status);
    final label = FormatUtils.taskStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
