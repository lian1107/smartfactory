import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/profile.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/utils/date_utils.dart';
import 'package:smartfactory/utils/format_utils.dart';

class WorkshopHomeScreen extends ConsumerWidget {
  const WorkshopHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // dark bg for workshop
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkshopHeader(profile: profile, now: now),
            Expanded(
              child: _WorkshopGrid(profile: profile),
            ),
            _WorkshopFooter(profile: profile),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────
class _WorkshopHeader extends StatelessWidget {
  final Profile? profile;
  final DateTime now;

  const _WorkshopHeader({required this.profile, required this.now});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // Brand icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.precision_manufacturing,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmartFactory 车间端',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppDateUtils.formatDisplayDate(now),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // User info
          if (profile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  profile!.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  FormatUtils.roleLabel(profile!.role),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Main Grid ───────────────────────────────────────────────
class _WorkshopGrid extends ConsumerWidget {
  final Profile? profile;

  const _WorkshopGrid({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = profile?.role ?? '';

    // Define tiles based on role
    final tiles = _tilesForRole(role);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.05,
        ),
        itemCount: tiles.length,
        itemBuilder: (_, i) => _WorkshopTile(tile: tiles[i]),
      ),
    );
  }

  List<_TileData> _tilesForRole(String role) {
    // 产线组长 (leader)
    final leaderTiles = [
      _TileData(
        label: '生产报工',
        icon: Icons.factory_rounded,
        color: const Color(0xFF3B82F6),
        route: '/workshop/daily-report',
        description: '录入当班产量',
      ),
      _TileData(
        label: '不良记录',
        icon: Icons.warning_rounded,
        color: const Color(0xFFF59E0B),
        route: '/workshop/quality',
        description: '记录生产不良',
      ),
      _TileData(
        label: '我的任务',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF8B5CF6),
        route: '/workspace',
        description: '查看分配任务',
      ),
      _TileData(
        label: '项目进度',
        icon: Icons.view_kanban_rounded,
        color: const Color(0xFF10B981),
        route: '/projects',
        description: '查看看板状态',
      ),
    ];

    // QC 品质员
    final qcTiles = [
      _TileData(
        label: '品质检验',
        icon: Icons.verified_rounded,
        color: const Color(0xFF10B981),
        route: '/workshop/quality',
        description: '记录检验结果',
      ),
      _TileData(
        label: '来料检验',
        icon: Icons.inventory_rounded,
        color: const Color(0xFF3B82F6),
        route: '/workshop/incoming',
        description: '进料品质检验',
      ),
      _TileData(
        label: '不良代码',
        icon: Icons.list_alt_rounded,
        color: const Color(0xFFF59E0B),
        route: '/workshop/defect-codes',
        description: '查询不良代码',
      ),
      _TileData(
        label: '我的任务',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF8B5CF6),
        route: '/workspace',
        description: '查看分配任务',
      ),
    ];

    // 维修技术员 (technician)
    final technicianTiles = [
      _TileData(
        label: '维修记录',
        icon: Icons.build_rounded,
        color: const Color(0xFFEF4444),
        route: '/workshop/repair',
        description: '录入维修信息',
      ),
      _TileData(
        label: '维修历史',
        icon: Icons.history_rounded,
        color: const Color(0xFF6366F1),
        route: '/workshop/repair-history',
        description: '查看维修记录',
      ),
      _TileData(
        label: '我的任务',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF8B5CF6),
        route: '/workspace',
        description: '查看分配任务',
      ),
      _TileData(
        label: '项目进度',
        icon: Icons.view_kanban_rounded,
        color: const Color(0xFF10B981),
        route: '/projects',
        description: '查看看板状态',
      ),
    ];

    switch (role) {
      case 'qc':
        return qcTiles;
      case 'technician':
        return technicianTiles;
      default: // leader
        return leaderTiles;
    }
  }
}

class _TileData {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final String description;

  const _TileData({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    required this.description,
  });
}

class _WorkshopTile extends StatelessWidget {
  final _TileData tile;

  const _WorkshopTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(tile.route),
        splashColor: tile.color.withOpacity(0.2),
        highlightColor: tile.color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tile.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tile.color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  tile.icon,
                  color: tile.color,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                tile.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tile.description,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────
class _WorkshopFooter extends ConsumerWidget {
  final Profile? profile;

  const _WorkshopFooter({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Network status indicator (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  '在线',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sign out
          TextButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout, size: 16, color: Color(0xFF64748B)),
            label: const Text(
              '退出',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
