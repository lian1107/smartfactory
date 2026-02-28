import 'package:flutter/material.dart';
import '_sprint_placeholder.dart';

/// Sprint 3: 维修记录页面占位
class RepairLogScreen extends StatelessWidget {
  const RepairLogScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SprintPlaceholder(
        title: '维修记录',
        icon: Icons.build_rounded,
        color: Color(0xFFEF4444),
        sprint: 'Sprint 3',
        description: '维修技术员在此记录故障原因和维修措施，\n形成维修知识库。',
      );
}
