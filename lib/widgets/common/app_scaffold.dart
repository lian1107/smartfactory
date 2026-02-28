import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/profile.dart';
import 'package:smartfactory/providers/auth_provider.dart';

class _NavItem {
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

// Office/admin navigation items
const _officeNavItems = [
  _NavItem(
    label: '仪表盘',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    route: '/',
  ),
  _NavItem(
    label: '工作台',
    icon: Icons.work_outline,
    activeIcon: Icons.work,
    route: '/workspace',
  ),
  _NavItem(
    label: '项目',
    icon: Icons.folder_outlined,
    activeIcon: Icons.folder,
    route: '/projects',
  ),
  _NavItem(
    label: '产品',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    route: '/products',
  ),
  _NavItem(
    label: '设置',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    route: '/settings',
  ),
];

// Used by workshop-role users who can still access office pages (workspace/projects)
const _workshopOfficeNavItems = [
  _NavItem(
    label: '车间',
    icon: Icons.factory_outlined,
    activeIcon: Icons.factory,
    route: '/workshop',
  ),
  _NavItem(
    label: '工作台',
    icon: Icons.work_outline,
    activeIcon: Icons.work,
    route: '/workspace',
  ),
  _NavItem(
    label: '项目',
    icon: Icons.folder_outlined,
    activeIcon: Icons.folder,
    route: '/projects',
  ),
];

const _workshopRoles = {'leader', 'qc', 'technician'};

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  List<_NavItem> _navItemsFor(String? role) {
    if (role != null && _workshopRoles.contains(role)) {
      return _workshopOfficeNavItems;
    }
    return _officeNavItems;
  }

  int _selectedIndex(BuildContext context, List<_NavItem> items) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < items.length; i++) {
      final route = items[i].route;
      if (route == '/') {
        if (location == '/') return i;
      } else {
        if (location.startsWith(route)) return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide =
        MediaQuery.of(context).size.width > AppConstants.breakpointDesktop;
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final navItems = _navItemsFor(profile?.role);
    final selectedIdx = _selectedIndex(context, navItems);

    if (isWide) {
      return _WideLayout(
        selectedIndex: selectedIdx,
        navItems: navItems,
        profile: profile,
        child: child,
      );
    }

    return _NarrowLayout(
      selectedIndex: selectedIdx,
      navItems: navItems,
      child: child,
    );
  }
}

// ─── Wide Layout (NavigationRail) ────────────────────────────
class _WideLayout extends ConsumerWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Profile? profile;
  final Widget child;

  const _WideLayout({
    required this.selectedIndex,
    required this.navItems,
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
            child: _Sidebar(
              selectedIndex: selectedIndex,
              navItems: navItems,
              profile: profile,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Profile? profile;

  const _Sidebar({
    required this.selectedIndex,
    required this.navItems,
    required this.profile,
  });

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
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final isSelected = i == selectedIndex;
                return _SidebarTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => context.go(item.route),
                );
              },
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

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Narrow Layout (BottomNavigationBar) ─────────────────────
class _NarrowLayout extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final Widget child;

  const _NarrowLayout({
    required this.selectedIndex,
    required this.navItems,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(navItems[i].route),
        destinations: navItems
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
