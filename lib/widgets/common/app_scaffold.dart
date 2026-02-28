import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/profile.dart';
import 'package:smartfactory/providers/auth_provider.dart';

// ─── Nav data structures ──────────────────────────────────────

sealed class _NavEntry {
  const _NavEntry();
}

final class _NavItem extends _NavEntry {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

final class _NavGroup extends _NavEntry {
  final String label;
  final IconData icon;
  final List<_NavItem> children;

  const _NavGroup({
    required this.label,
    required this.icon,
    required this.children,
  });
}

// ─── Sidebar nav entries (all roles, wide layout) ─────────────

const _sidebarEntries = <_NavEntry>[
  _NavItem(
    label: '仪表盘',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: '/',
  ),
  _NavItem(
    label: '工作台',
    icon: Icons.work_outline,
    activeIcon: Icons.work_rounded,
    route: '/workspace',
  ),
  _NavItem(
    label: '项目',
    icon: Icons.folder_outlined,
    activeIcon: Icons.folder_rounded,
    route: '/projects',
  ),
  _NavGroup(
    label: '生产',
    icon: Icons.factory_outlined,
    children: [
      _NavItem(
        label: '生产报表',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        route: '/workshop/daily-report',
      ),
      _NavItem(
        label: '品质检验',
        icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check_rounded,
        route: '/workshop/quality',
      ),
      _NavItem(
        label: '来料检验',
        icon: Icons.inventory_outlined,
        activeIcon: Icons.inventory_rounded,
        route: '/workshop/incoming',
      ),
      _NavItem(
        label: '维修记录',
        icon: Icons.build_outlined,
        activeIcon: Icons.build_rounded,
        route: '/workshop/repair',
      ),
    ],
  ),
  _NavItem(
    label: 'AI 分析',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
    route: '/ai',
  ),
  _NavItem(
    label: '文档',
    icon: Icons.description_outlined,
    activeIcon: Icons.description_rounded,
    route: '/docs',
  ),
  _NavItem(
    label: '产品',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2_rounded,
    route: '/products',
  ),
  _NavItem(
    label: '设置',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    route: '/settings',
  ),
];

// ─── Mobile bottom nav (5 key items) ─────────────────────────

const _bottomNavItems = <_NavItem>[
  _NavItem(
    label: '仪表盘',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: '/',
  ),
  _NavItem(
    label: '生产',
    icon: Icons.factory_outlined,
    activeIcon: Icons.factory_rounded,
    route: '/workshop/daily-report',
  ),
  _NavItem(
    label: 'AI',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
    route: '/ai',
  ),
  _NavItem(
    label: '文档',
    icon: Icons.description_outlined,
    activeIcon: Icons.description_rounded,
    route: '/docs',
  ),
  _NavItem(
    label: '设置',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    route: '/settings',
  ),
];

int _selectedBottomIndex(String location) {
  if (location == '/') return 0;
  if (location.startsWith('/workshop/')) return 1;
  if (location.startsWith('/ai')) return 2;
  if (location.startsWith('/docs')) return 3;
  if (location.startsWith('/settings')) return 4;
  return 0;
}

// ─── AppScaffold ─────────────────────────────────────────────

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide =
        MediaQuery.of(context).size.width > AppConstants.breakpointDesktop;
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;

    if (isWide) {
      return _WideLayout(location: location, profile: profile, child: child);
    }

    return _NarrowLayout(location: location, child: child);
  }
}

// ─── Wide Layout ─────────────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  final String location;
  final Profile? profile;
  final Widget child;

  const _WideLayout({
    required this.location,
    required this.profile,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: AppConstants.sidebarWidth,
            child: _Sidebar(location: location, profile: profile),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  final String location;
  final Profile? profile;

  const _Sidebar({required this.location, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SmartFactory',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Nav entries
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: _sidebarEntries.map((entry) {
                return switch (entry) {
                  _NavItem() => _SidebarTile(
                      item: entry,
                      isSelected: entry.route == '/'
                          ? location == '/'
                          : location.startsWith(entry.route),
                      onTap: () => context.go(entry.route),
                    ),
                  _NavGroup() => _SidebarGroupTile(
                      group: entry,
                      location: location,
                      onChildTap: (route) => context.go(route),
                    ),
                };
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // User info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (profile?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? '...',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?.role ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  tooltip: '退出登录',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar group tile (expandable) ─────────────────────────

class _SidebarGroupTile extends StatelessWidget {
  final _NavGroup group;
  final String location;
  final ValueChanged<String> onChildTap;

  const _SidebarGroupTile({
    required this.group,
    required this.location,
    required this.onChildTap,
  });

  bool get _isActive =>
      group.children.any((c) => location.startsWith(c.route));

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _isActive,
        leading: Icon(
          group.icon,
          size: 20,
          color: _isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          group.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
            color: _isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 4),
        children: group.children.map((child) {
          final isSelected = location.startsWith(child.route);
          return _SidebarTile(
            item: child,
            isSelected: isSelected,
            onTap: () => onChildTap(child.route),
            isChild: true,
          );
        }).toList(),
      ),
    );
  }
}

// ─── Sidebar flat tile ────────────────────────────────────────

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isChild;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.isChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isChild ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                size: isChild ? 16 : 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: isChild ? 13 : 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Narrow Layout (bottom nav bar) ──────────────────────────

class _NarrowLayout extends StatelessWidget {
  final String location;
  final Widget child;

  const _NarrowLayout({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    final selectedIdx = _selectedBottomIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIdx,
        onDestinationSelected: (i) => context.go(_bottomNavItems[i].route),
        destinations: _bottomNavItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
