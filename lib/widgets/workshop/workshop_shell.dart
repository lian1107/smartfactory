import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

const _kSidebarWidth = 220.0;
const _kBreakpoint = 700.0;

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

const _kNavItems = [
  _NavItem(label: '生产报工', icon: Icons.factory_rounded,   route: '/workshop/daily-report'),
  _NavItem(label: '品质检验', icon: Icons.verified_rounded,  route: '/workshop/quality'),
  _NavItem(label: '来料检验', icon: Icons.inventory_rounded, route: '/workshop/incoming'),
  _NavItem(label: '维修记录', icon: Icons.build_rounded,     route: '/workshop/repair'),
];

/// Persistent shell for all /workshop/* routes.
/// Wide (≥700 px): fixed sidebar + content.
/// Narrow (<700 px): top AppBar with Drawer.
class WorkshopShell extends ConsumerWidget {
  const WorkshopShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile  = ref.watch(currentProfileProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;
    final isWide   = MediaQuery.sizeOf(context).width >= _kBreakpoint;

    final sidebar = _WorkshopSidebar(profile: profile, location: location);

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Row(
          children: [
            SizedBox(width: _kSidebarWidth, child: sidebar),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF334155)),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(_titleFor(location)),
        centerTitle: false,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B),
        child: sidebar,
      ),
      body: child,
    );
  }

  static String _titleFor(String location) {
    for (final item in _kNavItems) {
      if (location.startsWith(item.route)) return item.label;
    }
    return 'SmartFactory 车间端';
  }
}

// ─── Sidebar ──────────────────────────────────────────────────

class _WorkshopSidebar extends ConsumerWidget {
  const _WorkshopSidebar({required this.profile, required this.location});

  final Profile? profile;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (profile != null) _buildUserInfo(),
          const Divider(height: 1, thickness: 1, color: Color(0xFF334155)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: _kNavItems.map((item) {
                return _SidebarTile(
                  item: item,
                  isActive: location.startsWith(item.route),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF334155)),
          _buildSignOut(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.precision_manufacturing,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'SmartFactory\n车间端',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final name = profile!.displayName;
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.25),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _roleLabel(profile!.role),
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOut(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.logout, color: Color(0xFF64748B), size: 18),
          title: const Text('退出登录',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () async =>
              ref.read(authNotifierProvider.notifier).signOut(),
        ),
      ),
    );
  }

  static String _roleLabel(String role) {
    const map = {
      'admin': '管理员',
      'leader': '产线组长',
      'qc': '品质员',
      'technician': '维修技术员',
    };
    return map[role] ?? role;
  }
}

// ─── Sidebar tile ─────────────────────────────────────────────

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          item.icon,
          color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          context.go(item.route);
          // Close drawer on mobile if open
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.isDrawerOpen == true) {
            scaffold!.closeDrawer();
          }
        },
      ),
    );
  }
}
