class AppConstants {
  AppConstants._();

  // Layout breakpoints
  static const double breakpointDesktop = 840.0;
  static const double sidebarWidth = 240.0;
  static const double sidebarRailWidth = 72.0;

  // Pagination
  static const int pageSize = 20;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'MM月dd日';
  static const String displayDateTimeFormat = 'MM月dd日 HH:mm';

  // Task priority labels
  static const Map<String, String> priorityLabels = {
    'low': '低',
    'medium': '中',
    'high': '高',
    'urgent': '紧急',
  };

  // Task status labels
  static const Map<String, String> taskStatusLabels = {
    'todo': '待处理',
    'in_progress': '进行中',
    'done': '已完成',
    'blocked': '受阻',
  };

  // Project status labels
  static const Map<String, String> projectStatusLabels = {
    'active': '进行中',
    'on_hold': '暂停',
    'completed': '已完成',
    'cancelled': '已取消',
  };

  // Health labels
  static const Map<String, String> healthLabels = {
    'green': '正常',
    'yellow': '注意',
    'red': '风险',
  };

  // User role labels
  static const Map<String, String> roleLabels = {
    'admin': '管理员',
    'leader': '项目负责人',
    'qc': '质检员',
    'technician': '技术员',
  };
}
