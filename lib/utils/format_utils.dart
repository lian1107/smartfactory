import 'package:flutter/material.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/config/constants.dart';

class FormatUtils {
  FormatUtils._();

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'low':
        return AppColors.priorityLow;
      case 'medium':
        return AppColors.priorityMedium;
      case 'high':
        return AppColors.priorityHigh;
      case 'urgent':
        return AppColors.priorityUrgent;
      default:
        return AppColors.priorityMedium;
    }
  }

  static Color healthColor(String health) {
    switch (health) {
      case 'green':
        return AppColors.healthGreen;
      case 'yellow':
        return AppColors.healthYellow;
      case 'red':
        return AppColors.healthRed;
      default:
        return AppColors.healthGreen;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'active':
      case 'in_progress':
        return AppColors.info;
      case 'completed':
      case 'done':
        return AppColors.success;
      case 'on_hold':
      case 'blocked':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static String priorityLabel(String priority) =>
      AppConstants.priorityLabels[priority] ?? priority;

  static String taskStatusLabel(String status) =>
      AppConstants.taskStatusLabels[status] ?? status;

  static String projectStatusLabel(String status) =>
      AppConstants.projectStatusLabels[status] ?? status;

  static String healthLabel(String health) =>
      AppConstants.healthLabels[health] ?? health;

  static String roleLabel(String role) =>
      AppConstants.roleLabels[role] ?? role;

  /// Parse hex color string (e.g. '#2563EB') to Color
  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return null;
  }
}
