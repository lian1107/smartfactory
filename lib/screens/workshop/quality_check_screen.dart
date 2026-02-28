import 'package:flutter/material.dart';
import '_sprint_placeholder.dart';

/// Sprint 3: 品质检验页面占位
class QualityCheckScreen extends StatelessWidget {
  const QualityCheckScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SprintPlaceholder(
        title: '品质检验',
        icon: Icons.verified_rounded,
        color: Color(0xFF10B981),
        sprint: 'Sprint 3',
        description: 'QC 在此勾选不良类型和数量，\n替代正字计数法手写记录。',
      );
}
