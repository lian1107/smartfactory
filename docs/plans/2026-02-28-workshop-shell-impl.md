# Workshop Shell Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the tile-grid workshop home screen with a persistent two-panel layout (sidebar + embedded form).

**Architecture:** A new `WorkshopShell` widget replaces `WorkshopHomeScreen` as the outer shell for all `/workshop/*` routes via go_router `ShellRoute`. On wide screens (≥700 px) it shows a fixed left sidebar; on narrow screens it shows a hamburger + `Drawer`. Each form screen loses its `Scaffold`/`AppBar` wrapper and returns a plain `ListView`. Submit success resets the form instead of popping the route.

**Tech Stack:** Flutter 3.41.2, Riverpod 2.x, go_router 13.x, Material 3 dark theme

---

### Task 1: Create WorkshopShell widget

**Files:**
- Create: `lib/widgets/workshop/workshop_shell.dart`

**Step 1: Create the file with this exact content**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/profile.dart';
import 'package:smartfactory/providers/auth_provider.dart';

const _kSidebarWidth = 220.0;
const _kBreakpoint = 700.0;

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem({required this.label, required this.icon, required this.route});
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
  final Widget child;
  const WorkshopShell({super.key, required this.child});

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
  final Profile? profile;
  final String location;

  const _WorkshopSidebar({required this.profile, required this.location});

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
  final _NavItem item;
  final bool isActive;

  const _SidebarTile({required this.item, required this.isActive});

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
```

**Step 2: Verify no syntax errors**

```
cd F:/编程/seuwu/smartfactory
/c/flutter/bin/flutter analyze lib/widgets/workshop/workshop_shell.dart
```

Expected: no errors

**Step 3: Commit**

```bash
git add lib/widgets/workshop/workshop_shell.dart
git commit -m "feat: add WorkshopShell two-panel layout widget"
```

---

### Task 2: Update router — ShellRoute + redirect

**Files:**
- Modify: `lib/config/router.dart`

**Step 1: Add WorkshopShell import at the top of the imports**

After line 15 (`import 'package:smartfactory/screens/workshop/incoming_inspection_screen.dart';`), add:

```dart
import 'package:smartfactory/widgets/workshop/workshop_shell.dart';
```

**Step 2: Update the global redirect function**

Find the block starting with:
```dart
// 2. Logged in + on /login → role-based home
if (isLoginPage) {
  final role = profileAsync.valueOrNull?.role;
  return _isWorkshopRole(role) ? '/workshop' : '/';
}
```

Replace it with:
```dart
// 2. Logged in + on /login → role-based home
if (isLoginPage) {
  final role = profileAsync.valueOrNull?.role;
  return _isWorkshopRole(role) ? '/workshop/daily-report' : '/';
}
```

Then find:
```dart
if (loc == '/') {
  final role = profileAsync.valueOrNull?.role;
  if (_isWorkshopRole(role)) return '/workshop';
}
```

Replace with:
```dart
if (loc == '/' || loc == '/workshop') {
  final role = profileAsync.valueOrNull?.role;
  if (_isWorkshopRole(role)) return '/workshop/daily-report';
}
```

Also remove the now-unused `isWorkshopPage` variable:
```dart
// Remove this line:
final isWorkshopPage = loc.startsWith('/workshop');
```

**Step 3: Replace the workshop GoRoute block with a ShellRoute**

Find and remove the entire existing workshop GoRoute block:
```dart
// ─── Workshop routes (standalone, dark theme) ──────────
// These live OUTSIDE the AppScaffold ShellRoute.
GoRoute(
  path: '/workshop',
  name: 'workshop-home',
  builder: (_, __) => const WorkshopHomeScreen(),
  routes: [
    GoRoute(
      path: 'daily-report',
      name: 'daily-report',
      builder: (_, __) => const DailyReportScreen(),
    ),
    GoRoute(
      path: 'quality',
      name: 'quality-check',
      builder: (_, __) => const QualityCheckScreen(),
    ),
    GoRoute(
      path: 'repair',
      name: 'repair-log',
      builder: (_, __) => const RepairLogScreen(),
    ),
    GoRoute(
      path: 'incoming',
      name: 'incoming-inspection',
      builder: (_, __) => const IncomingInspectionScreen(),
    ),
    // Placeholder for defect code reference (Sprint 3)
    GoRoute(
      path: 'defect-codes',
      name: 'workshop-defect-codes',
      builder: (_, __) => const _DefectCodesPlaceholder(),
    ),
    // Placeholder for repair history (Sprint 3)
    GoRoute(
      path: 'repair-history',
      name: 'repair-history',
      builder: (_, __) => const _RepairHistoryPlaceholder(),
    ),
  ],
),
```

Replace with:
```dart
// ─── Workshop routes (ShellRoute with persistent sidebar) ──
ShellRoute(
  builder: (context, state, child) => WorkshopShell(child: child),
  routes: [
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
      path: '/workshop/defect-codes',
      name: 'workshop-defect-codes',
      builder: (_, __) => const _DefectCodesPlaceholder(),
    ),
    GoRoute(
      path: '/workshop/repair-history',
      name: 'repair-history',
      builder: (_, __) => const _RepairHistoryPlaceholder(),
    ),
  ],
),
```

**Step 4: Remove WorkshopHomeScreen import** (no longer used as a route target)

Remove this line:
```dart
import 'package:smartfactory/screens/workshop/workshop_home_screen.dart';
```

**Step 5: Fix the placeholder widgets** — they currently have a Scaffold + AppBar + back button. Inside the ShellRoute the shell already provides navigation, so replace both placeholder `build()` methods with a simple body:

Find `_DefectCodesPlaceholder.build()`:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      title: const Text('不良代码'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => context.go('/workshop'),
      ),
    ),
    body: const Center(
      child: Text(
        'Sprint 3 开发中',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    ),
  );
}
```

Replace with:
```dart
@override
Widget build(BuildContext context) {
  return const Center(
    child: Text(
      'Sprint 3 开发中',
      style: TextStyle(color: Color(0xFF94A3B8)),
    ),
  );
}
```

Do the same for `_RepairHistoryPlaceholder.build()`.

**Step 6: Verify**

```
/c/flutter/bin/flutter analyze lib/config/router.dart
```

Expected: no errors (the `unused_local_variable` warning for `isWorkshopPage` should now be gone)

**Step 7: Commit**

```bash
git add lib/config/router.dart
git commit -m "feat: replace workshop GoRoute with ShellRoute using WorkshopShell"
```

---

### Task 3: Refactor DailyReportScreen

**Files:**
- Modify: `lib/screens/workshop/daily_report_screen.dart`

**Step 1: Replace the build() method**

Find the entire `build()` method (lines 83–192 approx.) and replace:

```dart
@override
Widget build(BuildContext context) {
  final productsAsync = ref.watch(productListProvider);

  return Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      title: const Text('生产报工'),
      centerTitle: false,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        // ... existing content
      ),
    ),
  );
}
```

With (remove Scaffold + AppBar, keep the Form + ListView):

```dart
@override
Widget build(BuildContext context) {
  final productsAsync = ref.watch(productListProvider);

  return Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _formatDate(DateTime.now()),
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // 班次选择
        const Text('选择班次',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        ShiftSelector(
          selected: _shift,
          onChanged: (s) {
            setState(() {
              _shift = s;
              _rebuildSlots(s);
            });
          },
        ),
        const SizedBox(height: 20),

        // 产品选择
        const Text('选择产品（可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        productsAsync.when(
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6), strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (products) => _ProductDropdown(
            products: products,
            value: _selectedProductId,
            onChanged: (id) =>
                setState(() => _selectedProductId = id),
          ),
        ),
        const SizedBox(height: 24),

        // 时段卡片
        const Text(
          '各时段产量',
          style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._slots.map((s) => TimeSlotCard(data: s)),
        const SizedBox(height: 24),

        // 提交按钮
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '提交报工',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}
```

**Step 2: Update the submit success handler in `_submit()`**

Find:
```dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('报工提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
  context.pop();
}
```

Replace with:
```dart
if (mounted) {
  setState(() {
    _shift = Shift.early;
    _selectedProductId = null;
    _rebuildSlots(Shift.early);
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('报工提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
}
```

**Step 3: Remove unused import** — `go_router` is no longer needed in this file (no `context.pop()`):

Remove:
```dart
import 'package:go_router/go_router.dart';
```

**Step 4: Verify**

```
/c/flutter/bin/flutter analyze lib/screens/workshop/daily_report_screen.dart
```

Expected: no errors

**Step 5: Commit**

```bash
git add lib/screens/workshop/daily_report_screen.dart
git commit -m "refactor: remove Scaffold from DailyReportScreen, reset form on submit"
```

---

### Task 4: Refactor QualityCheckScreen

**Files:**
- Modify: `lib/screens/workshop/quality_check_screen.dart`

**Step 1: Replace the build() method** — remove Scaffold + AppBar wrapper:

```dart
@override
Widget build(BuildContext context) {
  final productsAsync = ref.watch(productListProvider);

  return Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('检验类型',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            _TypeButton(
              label: '全检',
              selected: _inspectionType == 'full',
              onTap: () => setState(() => _inspectionType = 'full'),
            ),
            const SizedBox(width: 12),
            _TypeButton(
              label: '抽检',
              selected: _inspectionType == 'sample',
              onTap: () => setState(() => _inspectionType = 'sample'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const Text('产品（可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        productsAsync.maybeWhen(
          data: (products) => _ProductDropdown(
            products: products,
            value: _selectedProductId,
            onChanged: (id) =>
                setState(() => _selectedProductId = id),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        BigNumberField(label: '检验总数', controller: _totalCtrl),
        const SizedBox(height: 16),
        BigNumberField(
          label: '不良总数',
          controller: _defectCtrl,
          isRequired: false,
        ),
        const SizedBox(height: 16),

        const Text('不良描述（可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '描述不良现象...',
            hintStyle:
                const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF3B82F6), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '提交检验',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}
```

**Step 2: Update submit success handler**

Find:
```dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('检验记录提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
  context.pop();
}
```

Replace with:
```dart
if (mounted) {
  setState(() {
    _inspectionType = 'full';
    _selectedProductId = null;
    _totalCtrl.clear();
    _defectCtrl.text = '0';
    _notesCtrl.clear();
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('检验记录提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
}
```

**Step 3: Remove unused imports**

Remove:
```dart
import 'package:go_router/go_router.dart';
```

**Step 4: Verify + commit**

```bash
/c/flutter/bin/flutter analyze lib/screens/workshop/quality_check_screen.dart
git add lib/screens/workshop/quality_check_screen.dart
git commit -m "refactor: remove Scaffold from QualityCheckScreen, reset form on submit"
```

---

### Task 5: Refactor RepairLogScreen

**Files:**
- Modify: `lib/screens/workshop/repair_log_screen.dart`

**Step 1: Replace the build() method** — remove Scaffold + AppBar:

```dart
@override
Widget build(BuildContext context) {
  final productsAsync = ref.watch(productListProvider);

  return Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('产品（可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        productsAsync.maybeWhen(
          data: (products) => DropdownButtonFormField<String>(
            value: _selectedProductId,
            dropdownColor: const Color(0xFF1E293B),
            style:
                const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '选择产品',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF334155)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('-- 不关联产品 --',
                    style: TextStyle(color: Colors.white54)),
              ),
              ...products.map((p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(p.name),
                  )),
            ],
            onChanged: (id) =>
                setState(() => _selectedProductId = id),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        const Text('故障类型（可多选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kFaultTypes.map((type) {
            final selected = _selectedFaultTypes.contains(type);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedFaultTypes.remove(type);
                } else {
                  _selectedFaultTypes.add(type);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        const Text('维修措施 *',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _actionCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 4,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? '请填写维修措施' : null,
          decoration: InputDecoration(
            hintText: '描述维修过程和处理措施...',
            hintStyle:
                const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF3B82F6), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('维修时长（分钟，可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(
                color: Colors.white24, fontSize: 24),
            suffixText: '分钟',
            suffixStyle:
                const TextStyle(color: Colors.white54, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 12),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '提交记录',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}
```

**Step 2: Update submit success handler**

Find and replace in `_submit()`:
```dart
// OLD:
context.pop();

// NEW (add before the closing '}' of the success 'if (mounted)' block):
setState(() {
  _selectedProductId = null;
  _selectedFaultTypes.clear();
  _actionCtrl.clear();
  _durationCtrl.clear();
});
```

The full success block becomes:
```dart
if (mounted) {
  setState(() {
    _selectedProductId = null;
    _selectedFaultTypes.clear();
    _actionCtrl.clear();
    _durationCtrl.clear();
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('维修记录提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
}
```

**Step 3: Remove unused import**

Remove:
```dart
import 'package:go_router/go_router.dart';
```

**Step 4: Verify + commit**

```bash
/c/flutter/bin/flutter analyze lib/screens/workshop/repair_log_screen.dart
git add lib/screens/workshop/repair_log_screen.dart
git commit -m "refactor: remove Scaffold from RepairLogScreen, reset form on submit"
```

---

### Task 6: Refactor IncomingInspectionScreen

**Files:**
- Modify: `lib/screens/workshop/incoming_inspection_screen.dart`

**Step 1: Replace the build() method** — remove Scaffold + AppBar:

```dart
@override
Widget build(BuildContext context) {
  return Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('物料名称 *',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _materialCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? '请填写物料名称' : null,
          decoration: _inputDecoration('如：电机、电池、外壳...'),
        ),
        const SizedBox(height: 16),

        const Text('供应商（可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _supplierCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: _inputDecoration('供应商名称'),
        ),
        const SizedBox(height: 20),

        BigNumberField(label: '来料总数', controller: _totalCtrl),
        const SizedBox(height: 16),
        BigNumberField(
          label: '不良总数',
          controller: _defectCtrl,
          isRequired: false,
        ),
        const SizedBox(height: 16),

        const Text('不良描述（可选）',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 3,
          decoration:
              _inputDecoration('描述不良现象，如：外观划伤、尺寸偏差...'),
        ),
        const SizedBox(height: 20),

        const Text('检验结论',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            _ResultButton(
              label: '合格',
              value: 'pass',
              selected: _result == 'pass',
              color: const Color(0xFF10B981),
              onTap: () => setState(() => _result = 'pass'),
            ),
            const SizedBox(width: 8),
            _ResultButton(
              label: '条件接收',
              value: 'conditional',
              selected: _result == 'conditional',
              color: const Color(0xFFF59E0B),
              onTap: () => setState(() => _result = 'conditional'),
            ),
            const SizedBox(width: 8),
            _ResultButton(
              label: '不合格',
              value: 'fail',
              selected: _result == 'fail',
              color: const Color(0xFFEF4444),
              onTap: () => setState(() => _result = 'fail'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: Colors.white38, size: 20),
              SizedBox(width: 8),
              Text('拍照留证（Sprint 3 实现）',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '提交检验',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}
```

**Step 2: Update submit success handler**

Find:
```dart
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('来料检验提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
  context.pop();
}
```

Replace with:
```dart
if (mounted) {
  setState(() {
    _materialCtrl.clear();
    _supplierCtrl.clear();
    _totalCtrl.clear();
    _defectCtrl.text = '0';
    _descCtrl.clear();
    _result = 'pass';
    _formKey.currentState?.reset();
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('来料检验提交成功'),
      backgroundColor: Color(0xFF10B981),
    ),
  );
}
```

**Step 3: Remove unused import**

Remove:
```dart
import 'package:go_router/go_router.dart';
```

**Step 4: Verify + commit**

```bash
/c/flutter/bin/flutter analyze lib/screens/workshop/incoming_inspection_screen.dart
git add lib/screens/workshop/incoming_inspection_screen.dart
git commit -m "refactor: remove Scaffold from IncomingInspectionScreen, reset form on submit"
```

---

### Task 7: Full verification

**Step 1: Run flutter analyze on the whole project**

```
cd F:/编程/seuwu/smartfactory
/c/flutter/bin/flutter analyze 2>&1 | grep "^  error"
```

Expected: no output (zero errors)

**Step 2: Hot-restart the running app**

If `flutter run` is already running in another terminal, press `R` (capital) for hot restart.
Otherwise start fresh:

```
/c/flutter/bin/flutter run -d chrome --web-port 8088
```

**Step 3: Manual smoke test checklist**

- [ ] App opens → shows 生产报工 form directly (no tile home screen)
- [ ] Left sidebar visible on desktop (≥700px wide)
- [ ] Click 品质检验 in sidebar → form switches, sidebar stays
- [ ] Click 来料检验 → form switches
- [ ] Click 维修记录 → form switches
- [ ] Active sidebar item highlighted in blue
- [ ] Resize browser window narrow (<700px) → sidebar disappears, hamburger ☰ appears
- [ ] Open drawer → same nav items, tap one → navigates and drawer closes
- [ ] Submit a form → form resets to empty, SnackBar shows success (no pop/navigate away)

**Step 4: Final commit (if any fixups needed)**

```bash
git add -A
git commit -m "fix: post-integration fixups for workshop shell"
```
