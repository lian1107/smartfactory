# Unified Nav + AI + Docs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Unify all roles onto one navigation, retheme workshop screens to light, add AI analysis module, add document management module.

**Architecture:** Remove WorkshopShell and role-based routing; all roles use AppScaffold with a single nav that has an expandable "生产" group; AI analysis calls Supabase Edge Function → Claude API; documents stored in new `documents` table.

**Tech Stack:** Flutter/Dart, go_router, flutter_riverpod, supabase_flutter, url_launcher (already in pubspec), json_annotation + build_runner (already in pubspec), Deno/TypeScript for Edge Function.

---

## Task 1: Fix role labels

**Files:**
- Modify: `lib/config/constants.dart`
- Modify: `lib/screens/settings/settings_screen.dart`

### Step 1: Fix constants.dart roleLabels map

In `lib/config/constants.dart`, find the `roleLabels` map and replace the three wrong values:

```dart
// BEFORE
static const Map<String, String> roleLabels = {
  'admin': '管理员',
  'leader': '项目负责人',
  'qc': '质检员',
  'technician': '技术员',
};

// AFTER
static const Map<String, String> roleLabels = {
  'admin': '管理员',
  'leader': '产线组长',
  'qc': '品质员',
  'technician': '维修技术员',
};
```

### Step 2: Fix settings_screen.dart dropdown items

In `lib/screens/settings/settings_screen.dart`, find `_UserTile`'s `DropdownButton` items and replace:

```dart
// BEFORE
items: const [
  DropdownMenuItem(value: 'admin', child: Text('管理员')),
  DropdownMenuItem(value: 'leader', child: Text('项目负责人')),
  DropdownMenuItem(value: 'qc', child: Text('质检员')),
  DropdownMenuItem(value: 'technician', child: Text('技术员')),
],

// AFTER
items: const [
  DropdownMenuItem(value: 'admin', child: Text('管理员')),
  DropdownMenuItem(value: 'leader', child: Text('产线组长')),
  DropdownMenuItem(value: 'qc', child: Text('品质员')),
  DropdownMenuItem(value: 'technician', child: Text('维修技术员')),
],
```

### Step 3: Verify

Run: `flutter analyze lib/config/constants.dart lib/screens/settings/settings_screen.dart`
Expected: No issues.

### Step 4: Commit

```bash
git add lib/config/constants.dart lib/screens/settings/settings_screen.dart
git commit -m "fix: correct role labels (产线组长, 品质员, 维修技术员)"
```

---

## Task 2: Unify router (remove role-based routing, add stub routes)

**Files:**
- Modify: `lib/config/router.dart`

### Step 1: Rewrite router.dart completely

Replace the entire content of `lib/config/router.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/screens/auth/login_screen.dart';
import 'package:smartfactory/screens/dashboard/dashboard_screen.dart';
import 'package:smartfactory/screens/workspace/workspace_screen.dart';
import 'package:smartfactory/screens/products/product_list_screen.dart';
import 'package:smartfactory/screens/products/product_form_screen.dart';
import 'package:smartfactory/screens/products/product_detail_screen.dart';
import 'package:smartfactory/screens/projects/project_list_screen.dart';
import 'package:smartfactory/screens/projects/project_form_screen.dart';
import 'package:smartfactory/screens/projects/project_detail_screen.dart';
import 'package:smartfactory/screens/settings/settings_screen.dart';
import 'package:smartfactory/screens/workshop/daily_report_screen.dart';
import 'package:smartfactory/screens/workshop/quality_check_screen.dart';
import 'package:smartfactory/screens/workshop/repair_log_screen.dart';
import 'package:smartfactory/screens/workshop/incoming_inspection_screen.dart';
import 'package:smartfactory/widgets/common/app_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    redirect: (context, state) {
      if (authState.isLoading) return null;

      final session = authState.valueOrNull?.session;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;
      final isLoginPage = loc == '/login';

      if (!isLoggedIn) {
        return isLoginPage ? null : '/login';
      }
      if (isLoginPage) return '/';

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ─── All authenticated routes under AppScaffold ────────
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/workspace',
            name: 'workspace',
            builder: (_, __) => const WorkspaceScreen(),
          ),
          GoRoute(
            path: '/projects',
            name: 'projects',
            builder: (_, __) => const ProjectListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'projects-new',
                builder: (_, __) => const ProjectFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'project-detail',
                builder: (_, state) => ProjectDetailScreen(
                  projectId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (_, __) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'products-new',
                builder: (_, __) => const ProductFormScreen(productId: null),
              ),
              GoRoute(
                path: ':id',
                name: 'product-detail',
                builder: (_, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'product-edit',
                    builder: (_, state) => ProductFormScreen(
                      productId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/workshop/daily-report',
            name: 'daily-report',
            builder: (_, __) => const DailyReportScreen(),
          ),
          GoRoute(
            path: '/workshop/quality',
            name: 'quality-check',
            builder: (_, __) => const QualityCheckScreen(),
          ),
          GoRoute(
            path: '/workshop/repair',
            name: 'repair-log',
            builder: (_, __) => const RepairLogScreen(),
          ),
          GoRoute(
            path: '/workshop/incoming',
            name: 'incoming-inspection',
            builder: (_, __) => const IncomingInspectionScreen(),
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            builder: (_, __) => const _PlaceholderScreen(title: 'AI 分析'),
          ),
          GoRoute(
            path: '/docs',
            name: 'docs',
            builder: (_, __) => const _PlaceholderScreen(title: '文档'),
          ),
          GoRoute(
            path: '/docs/new',
            name: 'docs-new',
            builder: (_, __) => const _PlaceholderScreen(title: '新建文档'),
          ),
          GoRoute(
            path: '/docs/:id',
            name: 'doc-detail',
            builder: (_, state) => _PlaceholderScreen(
              title: '文档详情 ${state.pathParameters['id']}',
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('页面不存在: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title — 开发中', style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
```

### Step 2: Verify

Run: `flutter analyze lib/config/router.dart`
Expected: No issues (the WorkshopShell import is gone, all routes exist).

### Step 3: Commit

```bash
git add lib/config/router.dart
git commit -m "refactor: unify all routes under AppScaffold, remove role-based routing"
```

---

## Task 3: Rewrite AppScaffold with unified nav + expandable 生产 group

**Files:**
- Modify: `lib/widgets/common/app_scaffold.dart`

### Step 1: Replace entire app_scaffold.dart

```dart
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
      // Remove the default ExpansionTile divider lines
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
```

### Step 2: Verify

Run: `flutter analyze lib/widgets/common/app_scaffold.dart`
Expected: No issues.

### Step 3: Commit

```bash
git add lib/widgets/common/app_scaffold.dart
git commit -m "feat: unified nav for all roles with expandable 生产 group"
```

---

## Task 4: Retheme workshop screens and production widgets to light theme

**Files:**
- Modify: `lib/screens/workshop/daily_report_screen.dart`
- Modify: `lib/screens/workshop/quality_check_screen.dart`
- Modify: `lib/screens/workshop/repair_log_screen.dart`
- Modify: `lib/screens/workshop/incoming_inspection_screen.dart`
- Modify: `lib/widgets/production/big_number_field.dart`
- Modify: `lib/widgets/production/shift_selector.dart`

**Color mapping rules:**

| Find (dark) | Replace (light) |
|---|---|
| `Color(0xFF0F172A)` | `Colors.transparent` |
| `Color(0xFF1E293B)` | `Colors.white` |
| `Color(0xFF334155)` | `AppColors.border` |
| `Color(0xFF94A3B8)` | `AppColors.textSecondary` |
| `Colors.white` (text/icon color only) | `AppColors.textPrimary` |
| `Colors.white70` | `AppColors.textSecondary` |
| `Colors.white54` | `AppColors.textSecondary` |
| `Colors.white38` | `AppColors.textDisabled` |
| `Colors.white24` | `AppColors.textDisabled` |
| `dropdownColor: Color(0xFF1E293B)` | _(remove this line entirely)_ |
| `style: TextStyle(color: Colors.white, ...)` in dropdown | `style: TextStyle(color: AppColors.textPrimary, ...)` |
| `hintStyle: TextStyle(color: Colors.white38...)` | `hintStyle: TextStyle(color: AppColors.textDisabled...)` |
| `fillColor: Color(0xFF1E293B)` | _(remove, theme default is white)_ |
| `border: OutlineInputBorder(... Color(0xFF334155))` in InputDecoration | _(remove, theme default handles borders)_ |
| `enabledBorder: OutlineInputBorder(... Color(0xFF334155))` | _(remove)_ |

**Do NOT change:**
- `Color(0xFF10B981)` — keep (green for success/pass status)
- `Color(0xFFEF4444)` — keep (red for fail status)
- `Color(0xFF3B82F6)` in focusedBorder — this is AppColors.primary, can leave or change to `AppColors.primary`
- `AppColors.primary` references — keep as-is

### Step 1: Retheme big_number_field.dart

Replace entire file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfactory/config/theme.dart';

/// 大字号数字输入框，适合车间手机操作
class BigNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isRequired;

  const BigNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint ?? '0',
            hintStyle: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? '请填写$label' : null
              : null,
        ),
      ],
    );
  }
}
```

### Step 2: Retheme shift_selector.dart

Replace entire file:

```dart
import 'package:flutter/material.dart';
import 'package:smartfactory/config/theme.dart';

enum Shift { early, mid, late }

extension ShiftExt on Shift {
  String get label {
    switch (this) {
      case Shift.early:
        return '早班';
      case Shift.mid:
        return '中班';
      case Shift.late:
        return '晚班';
    }
  }

  String get value {
    switch (this) {
      case Shift.early:
        return 'early';
      case Shift.mid:
        return 'mid';
      case Shift.late:
        return 'late';
    }
  }

  String get timeRange {
    switch (this) {
      case Shift.early:
        return '08:00-12:00';
      case Shift.mid:
        return '13:00-17:00';
      case Shift.late:
        return '18:00-21:00';
    }
  }

  /// 返回该班次的时段列表，每项为 [start, end] 小时数
  List<List<int>> get slots {
    switch (this) {
      case Shift.early:
        return [
          [8, 9],
          [9, 10],
          [10, 11],
          [11, 12]
        ];
      case Shift.mid:
        return [
          [13, 14],
          [14, 15],
          [15, 16],
          [16, 17]
        ];
      case Shift.late:
        return [
          [18, 19],
          [19, 20],
          [20, 21]
        ];
    }
  }
}

class ShiftSelector extends StatelessWidget {
  final Shift selected;
  final ValueChanged<Shift> onChanged;

  const ShiftSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Shift.values.map((shift) {
        final isSelected = shift == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(shift),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      shift.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.timeRange,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

### Step 3: Retheme daily_report_screen.dart

Open `lib/screens/workshop/daily_report_screen.dart`. Apply the color mapping rules from the table above. Pay special attention to:
- The product dropdown: remove `dropdownColor`, change text `color: Colors.white` → `AppColors.textPrimary`, remove `fillColor` and dark border overrides from `InputDecoration`
- Any `TextStyle(color: Colors.white...)` used as label/hint text → change to `AppColors.textPrimary` or `AppColors.textSecondary`
- Status colors (`Color(0xFF10B981)` green, `Color(0xFFEF4444)` red) → keep unchanged

### Step 4: Retheme quality_check_screen.dart

Same mapping rules. Apply to `lib/screens/workshop/quality_check_screen.dart`.

### Step 5: Retheme repair_log_screen.dart

Same mapping rules. Apply to `lib/screens/workshop/repair_log_screen.dart`.

### Step 6: Retheme incoming_inspection_screen.dart

Same mapping rules. Apply to `lib/screens/workshop/incoming_inspection_screen.dart`.

### Step 7: Verify

Run: `flutter analyze lib/screens/workshop/ lib/widgets/production/`
Expected: No issues.

### Step 8: Commit

```bash
git add lib/screens/workshop/ lib/widgets/production/
git commit -m "style: retheme workshop screens and production widgets to light theme"
```

---

## Task 5: Delete dead code

**Files:**
- Delete: `lib/widgets/workshop/workshop_shell.dart`
- Delete: `lib/screens/workshop/workshop_home_screen.dart`
- Delete: `lib/screens/workshop/_sprint_placeholder.dart` (if it exists and is no longer needed)

### Step 1: Check for lingering imports

Run:
```bash
grep -rn "workshop_shell\|workshop_home_screen\|_sprint_placeholder" lib/
```
Expected: No results (router.dart was already cleaned up in Task 2).

### Step 2: Delete files

```bash
rm lib/widgets/workshop/workshop_shell.dart
rm lib/screens/workshop/workshop_home_screen.dart
rm -f lib/screens/workshop/_sprint_placeholder.dart
```

### Step 3: Verify

Run: `flutter analyze lib/`
Expected: No issues.

### Step 4: Commit

```bash
git add -u lib/
git commit -m "chore: delete WorkshopShell and workshop home screen (no longer needed)"
```

---

## Task 6: canEdit permission utility + hide create/edit buttons for non-admin

**Files:**
- Modify: `lib/config/constants.dart`
- Modify: `lib/screens/projects/project_list_screen.dart`
- Modify: `lib/screens/products/product_list_screen.dart`
- Modify: `lib/screens/projects/project_detail_screen.dart`
- Modify: `lib/screens/products/product_detail_screen.dart`

### Step 1: Add canEdit to constants.dart

In `lib/config/constants.dart`, after the `AppConstants` class (or inside it as a static method), add:

```dart
// Top-level helper — only admin can create/edit/delete
bool canEdit(String? role) => role == 'admin';
```

Add this at the top level of the file (outside the class), after all imports.

### Step 2: Update project_list_screen.dart

Open `lib/screens/projects/project_list_screen.dart`. It uses Riverpod, so add a `ref.watch(currentProfileProvider).valueOrNull` to get the profile.

Find the `floatingActionButton:` widget (line ~46) and the empty-state "新建项目" button (line ~129). Wrap each with a conditional:

```dart
// At the top of the build method, add:
final profile = ref.watch(currentProfileProvider).valueOrNull;

// Wrap FAB:
floatingActionButton: canEdit(profile?.role)
    ? FloatingActionButton.extended(
        onPressed: () => context.go('/projects/new'),
        // ... existing FAB content unchanged
      )
    : null,

// Wrap empty-state button:
if (canEdit(profile?.role))
  ElevatedButton(
    onPressed: () => context.go('/projects/new'),
    // ... existing button content unchanged
  ),
```

If the widget is not already a ConsumerWidget/ConsumerStatefulWidget, add `ref` access. The file should already be using Riverpod for data fetching.

### Step 3: Update product_list_screen.dart

Same pattern as Step 2 for `lib/screens/products/product_list_screen.dart`. Wrap FAB and empty-state button with `canEdit(profile?.role)`.

### Step 4: Update project_detail_screen.dart

Open `lib/screens/projects/project_detail_screen.dart`. Find any edit/delete buttons (IconButton with edit/delete icons, or ElevatedButton for editing). Wrap them:

```dart
if (canEdit(profile?.role))
  IconButton(
    icon: const Icon(Icons.edit_outlined),
    onPressed: () => context.go('/projects/${widget.projectId}/edit'),
  ),
```

### Step 5: Update product_detail_screen.dart

Same pattern for `lib/screens/products/product_detail_screen.dart`.

### Step 6: Verify

Run: `flutter analyze lib/`
Expected: No issues.

### Step 7: Commit

```bash
git add lib/config/constants.dart lib/screens/projects/ lib/screens/products/
git commit -m "feat: add canEdit() permission guard, hide edit/create buttons for non-admin"
```

---

## Task 7: Documents database migration

**Files:**
- Create: `supabase/migrations/014_documents.sql`

### Step 1: Create migration file

```sql
-- 014_documents.sql
create table if not exists public.documents (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  type        text not null check (type in ('feishu', 'file', 'note')),
  url         text,
  file_path   text,
  content     text,
  category    text check (category in ('作业指导书', '质量标准', '设备手册', '其他')),
  tags        text[] default '{}',
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Updated_at trigger
create trigger documents_updated_at
  before update on public.documents
  for each row execute function public.handle_updated_at();

-- RLS
alter table public.documents enable row level security;

-- All authenticated users can read
create policy "documents_select" on public.documents
  for select to authenticated using (true);

-- Only admin can insert/update/delete
create policy "documents_insert" on public.documents
  for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "documents_update" on public.documents
  for update to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "documents_delete" on public.documents
  for delete to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );
```

**Note:** Check `supabase/migrations/` for an existing `handle_updated_at` function. If it doesn't exist (check `001_profiles_and_auth.sql`), replace the trigger with:
```sql
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
```
Add this function definition before the trigger creation.

### Step 2: Apply migration to Supabase

Run in Supabase SQL editor (or via CLI):
```bash
# If using Supabase CLI:
supabase db push
# OR paste the SQL directly into Supabase dashboard > SQL editor
```

### Step 3: Commit

```bash
git add supabase/migrations/014_documents.sql
git commit -m "feat: add documents table migration"
```

---

## Task 8: Document model, repository, provider, codegen

**Files:**
- Create: `lib/models/document.dart`
- Create: `lib/repositories/document_repository.dart`
- Create: `lib/providers/document_providers.dart`
- Generated (auto): `lib/models/document.g.dart`

### Step 1: Create lib/models/document.dart

```dart
import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

@JsonSerializable()
class Document {
  final String id;
  final String title;
  final String? description;
  final String type; // 'feishu' | 'file' | 'note'
  final String? url;
  @JsonKey(name: 'file_path')
  final String? filePath;
  final String? content;
  final String? category;
  final List<String>? tags;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.url,
    this.filePath,
    this.content,
    this.category,
    this.tags,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentToJson(this);
}
```

### Step 2: Run code generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: Creates `lib/models/document.g.dart` with no errors.

### Step 3: Create lib/repositories/document_repository.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/document.dart';

class DocumentRepository {
  final SupabaseClient _client;

  DocumentRepository(this._client);

  Future<List<Document>> fetchDocuments({
    String? category,
    String? search,
  }) async {
    var query = _client.from('documents').select();

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return data.map<Document>((e) => Document.fromJson(e)).toList();
  }

  Future<Document?> fetchDocument(String id) async {
    final data = await _client
        .from('documents')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Document.fromJson(data);
  }

  Future<Document> createDocument(Map<String, dynamic> payload) async {
    final data = await _client
        .from('documents')
        .insert(payload)
        .select()
        .single();
    return Document.fromJson(data);
  }

  Future<Document> updateDocument(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client
        .from('documents')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Document.fromJson(data);
  }

  Future<void> deleteDocument(String id) async {
    await _client.from('documents').delete().eq('id', id);
  }
}
```

### Step 4: Create lib/providers/document_providers.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/models/document.dart';
import 'package:smartfactory/repositories/document_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(Supabase.instance.client);
});

typedef _DocListParams = ({String? category, String? search});

final documentsProvider =
    FutureProvider.family<List<Document>, _DocListParams>(
  (ref, params) async {
    final repo = ref.watch(documentRepositoryProvider);
    return repo.fetchDocuments(
      category: params.category,
      search: params.search,
    );
  },
);

final documentDetailProvider =
    FutureProvider.family<Document?, String>((ref, id) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.fetchDocument(id);
});
```

### Step 5: Verify

Run: `flutter analyze lib/models/document.dart lib/repositories/document_repository.dart lib/providers/document_providers.dart`
Expected: No issues.

### Step 6: Commit

```bash
git add lib/models/document.dart lib/models/document.g.dart lib/repositories/document_repository.dart lib/providers/document_providers.dart
git commit -m "feat: add Document model, repository, and providers"
```

---

## Task 9: Document screens (list, form, detail)

**Files:**
- Create: `lib/screens/docs/doc_list_screen.dart`
- Create: `lib/screens/docs/doc_form_screen.dart`
- Create: `lib/screens/docs/doc_detail_screen.dart`
- Modify: `lib/config/router.dart` (replace placeholder builders with real screens)

### Step 1: Create lib/screens/docs/doc_list_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/document.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/document_providers.dart';

class DocListScreen extends ConsumerStatefulWidget {
  const DocListScreen({super.key});

  @override
  ConsumerState<DocListScreen> createState() => _DocListScreenState();
}

class _DocListScreenState extends ConsumerState<DocListScreen> {
  String? _selectedCategory;
  String _search = '';
  final _searchCtrl = TextEditingController();

  static const _categories = ['作业指导书', '质量标准', '设备手册', '其他'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final params = (category: _selectedCategory, search: _search);
    final docsAsync = ref.watch(documentsProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('文档'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: '搜索文档标题...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: '全部',
                        selected: _selectedCategory == null,
                        onTap: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      ...(_categories.map((c) => _CategoryChip(
                            label: c,
                            selected: _selectedCategory == c,
                            onTap: () =>
                                setState(() => _selectedCategory = c),
                          ))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canEdit(profile?.role)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/docs/new'),
              icon: const Icon(Icons.add),
              label: const Text('新建文档'),
            )
          : null,
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  const Text('暂无文档',
                      style: TextStyle(color: AppColors.textSecondary)),
                  if (canEdit(profile?.role)) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/docs/new'),
                      child: const Text('新建文档'),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _DocCard(
              doc: docs[i],
              onTap: () => context.go('/docs/${docs[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Document doc;
  final VoidCallback onTap;

  const _DocCard({required this.doc, required this.onTap});

  IconData get _typeIcon {
    return switch (doc.type) {
      'feishu' => Icons.open_in_new,
      'file' => Icons.attach_file,
      _ => Icons.article_outlined,
    };
  }

  String get _typeLabel {
    return switch (doc.type) {
      'feishu' => '飞书文档',
      'file' => '上传文件',
      _ => '在线笔记',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_typeIcon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${doc.category ?? '未分类'} · $_typeLabel',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textDisabled),
      ),
    );
  }
}
```

### Step 2: Create lib/screens/docs/doc_form_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/providers/document_providers.dart';

class DocFormScreen extends ConsumerStatefulWidget {
  final String? docId;

  const DocFormScreen({super.key, this.docId});

  @override
  ConsumerState<DocFormScreen> createState() => _DocFormScreenState();
}

class _DocFormScreenState extends ConsumerState<DocFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _type = 'feishu';
  String? _category;
  bool _submitting = false;
  bool _loaded = false;

  static const _categories = ['作业指导书', '质量标准', '设备手册', '其他'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && widget.docId != null) {
      _loadDoc();
    }
  }

  Future<void> _loadDoc() async {
    _loaded = true;
    final doc = await ref
        .read(documentRepositoryProvider)
        .fetchDocument(widget.docId!);
    if (doc != null && mounted) {
      setState(() {
        _titleCtrl.text = doc.title;
        _descCtrl.text = doc.description ?? '';
        _urlCtrl.text = doc.url ?? '';
        _contentCtrl.text = doc.content ?? '';
        _type = doc.type;
        _category = doc.category;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'type': _type,
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        if (_type == 'feishu') 'url': _urlCtrl.text.trim(),
        if (_type == 'note') 'content': _contentCtrl.text,
        if (_category != null) 'category': _category,
        if (widget.docId == null)
          'created_by': Supabase.instance.client.auth.currentUser?.id,
      };

      final repo = ref.read(documentRepositoryProvider);
      if (widget.docId != null) {
        await repo.updateDocument(widget.docId!, payload);
      } else {
        await repo.createDocument(payload);
      }

      ref.invalidate(documentsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId != null ? '编辑文档' : '新建文档'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'feishu', label: Text('飞书链接')),
                ButtonSegment(value: 'file', label: Text('上传文件')),
                ButtonSegment(value: 'note', label: Text('在线笔记')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '标题 *'),
              validator: (v) =>
                  v == null || v.isEmpty ? '请填写标题' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: '分类'),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),

            if (_type == 'feishu') ...[
              TextFormField(
                controller: _urlCtrl,
                decoration:
                    const InputDecoration(labelText: '飞书文档链接 *'),
                keyboardType: TextInputType.url,
                validator: (v) =>
                    v == null || v.isEmpty ? '请填写飞书链接' : null,
              ),
            ] else if (_type == 'file') ...[
              const Card(
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('文件上传'),
                  subtitle: Text('即将支持，敬请期待'),
                  dense: true,
                ),
              ),
            ] else if (_type == 'note') ...[
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: '笔记内容',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Create lib/screens/docs/doc_detail_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/document.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/document_providers.dart';

class DocDetailScreen extends ConsumerWidget {
  final String docId;

  const DocDetailScreen({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(documentDetailProvider(docId));
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return docAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('加载失败: $e'))),
      data: (doc) {
        if (doc == null) {
          return const Scaffold(
              body: Center(child: Text('文档不存在')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(doc.title),
            actions: [
              if (canEdit(profile?.role))
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑',
                  onPressed: () =>
                      context.go('/docs/new', extra: doc.id),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Category + type badges
              Row(
                children: [
                  if (doc.category != null)
                    _Badge(label: doc.category!, color: AppColors.primary),
                  const SizedBox(width: 8),
                  _Badge(
                    label: _typeLabel(doc.type),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (doc.description != null) ...[
                Text(doc.description!,
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 16),

              // Type-specific content
              if (doc.type == 'feishu' && doc.url != null)
                _FeishuCard(url: doc.url!),
              if (doc.type == 'note' && doc.content != null)
                _NoteContent(content: doc.content!),
              if (doc.type == 'file')
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.attach_file),
                    title: Text('文件'),
                    subtitle: Text('文件下载即将支持'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'feishu' => '飞书文档',
      'file' => '上传文件',
      _ => '在线笔记',
    };
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FeishuCard extends StatelessWidget {
  final String url;

  const _FeishuCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.open_in_new,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '飞书文档',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              url,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('在飞书中打开'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteContent extends StatelessWidget {
  final String content;

  const _NoteContent({required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: const TextStyle(
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
```

### Step 4: Wire up router with real screens

In `lib/config/router.dart`, add imports for the new doc screens and replace the placeholder builders:

```dart
// Add these imports at the top of router.dart:
import 'package:smartfactory/screens/docs/doc_list_screen.dart';
import 'package:smartfactory/screens/docs/doc_form_screen.dart';
import 'package:smartfactory/screens/docs/doc_detail_screen.dart';

// Replace:
GoRoute(
  path: '/docs',
  name: 'docs',
  builder: (_, __) => const _PlaceholderScreen(title: '文档'),
),
GoRoute(
  path: '/docs/new',
  name: 'docs-new',
  builder: (_, __) => const _PlaceholderScreen(title: '新建文档'),
),
GoRoute(
  path: '/docs/:id',
  name: 'doc-detail',
  builder: (_, state) => _PlaceholderScreen(
    title: '文档详情 ${state.pathParameters['id']}',
  ),
),

// With:
GoRoute(
  path: '/docs',
  name: 'docs',
  builder: (_, __) => const DocListScreen(),
),
GoRoute(
  path: '/docs/new',
  name: 'docs-new',
  builder: (_, __) => const DocFormScreen(),
),
GoRoute(
  path: '/docs/:id',
  name: 'doc-detail',
  builder: (_, state) => DocDetailScreen(
    docId: state.pathParameters['id']!,
  ),
),
```

### Step 5: Verify

Run: `flutter analyze lib/screens/docs/ lib/config/router.dart`
Expected: No issues.

### Step 6: Commit

```bash
git add lib/screens/docs/ lib/config/router.dart
git commit -m "feat: add document management screens (list, form, detail)"
```

---

## Task 10: AI Supabase Edge Function

**Files:**
- Create: `supabase/functions/ai-analyze/index.ts`

### Step 1: Create directory and file

```bash
mkdir -p supabase/functions/ai-analyze
```

Create `supabase/functions/ai-analyze/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { type, data } = await req.json();

    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      throw new Error("ANTHROPIC_API_KEY not configured");
    }

    let prompt = "";
    if (type === "project") {
      prompt = `你是一个智能工厂管理助手。请分析以下项目数据，用中文给出简洁的进度评估、风险提示和改善建议（3-5句话）：\n${JSON.stringify(data, null, 2)}`;
    } else if (type === "production") {
      prompt = `你是一个智能工厂管理助手。请分析以下生产数据，用中文给出简洁的质量趋势分析和改善建议（3-5句话）：\n${JSON.stringify(data, null, 2)}`;
    } else {
      throw new Error(`Unknown analysis type: ${type}`);
    }

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 400,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Claude API error: ${errText}`);
    }

    const result = await response.json();
    const summary = result.content?.[0]?.text ?? "分析暂时不可用";

    return new Response(JSON.stringify({ summary }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
```

### Step 2: Set Anthropic API key as Supabase secret

In the Supabase dashboard → Project Settings → Edge Functions → Secrets, add:
- Key: `ANTHROPIC_API_KEY`
- Value: your Anthropic API key (starts with `sk-ant-...`)

OR via CLI:
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-YOUR_KEY_HERE
```

### Step 3: Deploy the Edge Function

```bash
supabase functions deploy ai-analyze
```

### Step 4: Commit

```bash
git add supabase/functions/ai-analyze/
git commit -m "feat: add AI analyze Edge Function (Claude Haiku)"
```

---

## Task 11: AI Flutter screen

**Files:**
- Create: `lib/screens/ai/ai_screen.dart`
- Modify: `lib/config/router.dart` (replace /ai placeholder)

### Step 1: Create lib/screens/ai/ai_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartfactory/config/theme.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _projectSummary;
  String? _productionSummary;
  bool _projectLoading = false;
  bool _productionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _analyzeProjects() async {
    setState(() => _projectLoading = true);
    try {
      final client = Supabase.instance.client;
      final projects = await client
          .from('projects')
          .select('id, name, status, deadline, description')
          .limit(20);

      final tasks = await client
          .from('tasks')
          .select('id, status, project_id')
          .limit(100);

      final result = await client.functions.invoke(
        'ai-analyze',
        body: {
          'type': 'project',
          'data': {
            'projects': projects,
            'task_summary': {
              'total': tasks.length,
              'done': (tasks as List).where((t) => t['status'] == 'done').length,
              'overdue': (tasks).where((t) => t['status'] == 'overdue').length,
            },
          },
        },
      );
      final summary = result.data['summary'] as String? ?? '暂无分析结果';
      setState(() => _projectSummary = summary);
    } catch (e) {
      setState(() => _projectSummary = 'AI 分析暂时不可用，请检查网络或联系管理员。');
    } finally {
      setState(() => _projectLoading = false);
    }
  }

  Future<void> _analyzeProduction() async {
    setState(() => _productionLoading = true);
    try {
      final client = Supabase.instance.client;
      final reports = await client
          .from('daily_reports')
          .select('date, shift, total_output, defect_count')
          .order('date', ascending: false)
          .limit(30);

      final quality = await client
          .from('quality_records')
          .select('inspection_date, result, defect_count')
          .order('inspection_date', ascending: false)
          .limit(30);

      final result = await client.functions.invoke(
        'ai-analyze',
        body: {
          'type': 'production',
          'data': {
            'recent_reports': reports,
            'recent_quality': quality,
          },
        },
      );
      final summary = result.data['summary'] as String? ?? '暂无分析结果';
      setState(() => _productionSummary = summary);
    } catch (e) {
      setState(() => _productionSummary = 'AI 分析暂时不可用，请检查网络或联系管理员。');
    } finally {
      setState(() => _productionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '项目分析'),
            Tab(text: '生产分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AnalysisTab(
            title: '项目分析',
            description: '分析项目完成率、逾期任务和风险项目，生成 AI 洞察报告。',
            summary: _projectSummary,
            loading: _projectLoading,
            onAnalyze: _analyzeProjects,
            emptyIcon: Icons.folder_outlined,
          ),
          _AnalysisTab(
            title: '生产分析',
            description: '分析近期产量趋势、不良率和高频故障，生成 AI 洞察报告。',
            summary: _productionSummary,
            loading: _productionLoading,
            onAnalyze: _analyzeProduction,
            emptyIcon: Icons.factory_outlined,
          ),
        ],
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final String title;
  final String description;
  final String? summary;
  final bool loading;
  final VoidCallback onAnalyze;
  final IconData emptyIcon;

  const _AnalysisTab({
    required this.title,
    required this.description,
    required this.summary,
    required this.loading,
    required this.onAnalyze,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onAnalyze,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow, size: 18),
                    label: Text(loading ? '分析中...' : '生成分析'),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (summary != null) ...[
          const SizedBox(height: 16),
          Card(
            color: AppColors.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'AI 洞察',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary!,
                    style: const TextStyle(
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (summary == null && !loading) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(emptyIcon, size: 64, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                const Text(
                  '点击「生成分析」查看 AI 洞察',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
```

### Step 2: Wire up router

In `lib/config/router.dart`, add import and replace the `/ai` placeholder:

```dart
// Add import:
import 'package:smartfactory/screens/ai/ai_screen.dart';

// Replace:
GoRoute(
  path: '/ai',
  name: 'ai',
  builder: (_, __) => const _PlaceholderScreen(title: 'AI 分析'),
),

// With:
GoRoute(
  path: '/ai',
  name: 'ai',
  builder: (_, __) => const AiScreen(),
),
```

### Step 3: Verify

Run: `flutter analyze lib/screens/ai/ lib/config/router.dart`
Expected: No issues.

### Step 4: Commit

```bash
git add lib/screens/ai/ lib/config/router.dart
git commit -m "feat: add AI analysis screen with project and production tabs"
```

---

## Task 12: Full verification

### Step 1: Run flutter analyze

```bash
flutter analyze lib/
```
Expected: `No issues found!`

If there are issues, fix them (look at the error message, it will point to the file and line).

### Step 2: Run the app and smoke test

```bash
flutter run -d chrome --web-port 8099
```

Verify the following manually:
1. Login → lands on dashboard `/`
2. Sidebar shows: 仪表盘, 工作台, 项目, 生产(expandable), AI 分析, 文档, 产品, 设置
3. Click 生产 → expands to show 4 sub-items, click 生产报表 → opens DailyReportScreen with light theme (white background, dark text)
4. Click AI 分析 → two tabs (项目分析, 生产分析), click "生成分析" → shows loading then AI summary
5. Click 文档 → document list (empty), click 新建文档 (admin only) → form with type selector
6. Settings page → role dropdown shows 产线组长, 品质员, 维修技术员

### Step 3: Final commit if needed

If any small fixes were made during verification:
```bash
git add -p
git commit -m "fix: final smoke-test corrections"
```
