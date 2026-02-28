import 'package:flutter/material.dart';
import '_sprint_placeholder.dart';

/// Sprint 3: 来料检验页面占位
class IncomingInspectionScreen extends StatelessWidget {
  const IncomingInspectionScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SprintPlaceholder(
        title: '来料检验',
        icon: Icons.inventory_rounded,
        color: Color(0xFF3B82F6),
        sprint: 'Sprint 3',
        description: 'QC 在此记录供应商物料的来料检验结果，\n可拍照记录问题物料。',
      );
}
