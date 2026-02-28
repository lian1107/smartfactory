import 'package:flutter/material.dart';
import '_sprint_placeholder.dart';

/// Sprint 3: 生产报工页面占位
class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SprintPlaceholder(
        title: '生产报工',
        icon: Icons.factory_rounded,
        color: Color(0xFF3B82F6),
        sprint: 'Sprint 3',
        description: '产线组长在此录入每个时段的产量和不良数，\n替代手写报表。',
      );
}
