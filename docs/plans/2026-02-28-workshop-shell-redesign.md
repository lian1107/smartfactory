# Workshop Shell Redesign — Design Document

**Date:** 2026-02-28
**Status:** Approved

---

## Problem

The current workshop home screen (`WorkshopHomeScreen`) presents 4 large square tiles in a 2×2 grid. On desktop Chrome this looks like a "big-screen display" rather than a usable app. The two-step flow (home → tile → form) feels awkward.

## Goal

Replace the tile-grid home screen with a **persistent two-panel layout**: left sidebar navigation + right form content. One tap to reach any form. No intermediate home screen.

---

## Target Experience

### Wide screen (≥ 700 px)

```
┌──────────────┬──────────────────────────────┐
│  ⚙ SmartFac  │  生产报工                     │
│  ─────────── │  ──────────────────────────── │
│ ▶ 生产报工   │  班次: [早班][中班][晚班]      │
│   品质检验   │  产品: [选择产品 ▾]           │
│   来料检验   │  08:00—09:00                  │
│   维修记录   │    计划[___] 实际[___] 不良[0] │
│              │  ...                          │
│  ─────────── │                               │
│  张三 · 组长  │  [ 提交报工 ]                │
│  [退出]      │                               │
└──────────────┴──────────────────────────────┘
```

### Narrow screen (< 700 px)

```
┌──────────────────────────────┐
│ ☰  生产报工                  │
│ ──────────────────────────── │
│  [Form Content scrollable]   │
│  [ 提交报工 ]                │
└──────────────────────────────┘
```
Hamburger (☰) opens a Drawer with the same sidebar content.

---

## Architecture

### New file: `lib/widgets/workshop/workshop_shell.dart`

`WorkshopShell` is a `ConsumerWidget` that:
- Accepts `child` (the current route's content widget)
- Reads screen width via `MediaQuery`
- Wide: renders `Row(sidebar, VerticalDivider, Expanded(child))`
- Narrow: renders `Scaffold(drawer: sidebar, body: child)`
- Sidebar width: **220 px**
- Breakpoint: **700 px**

Sidebar content:
- Top: logo icon + "SmartFactory 车间端" + user name + role
- Menu items (4, all roles): 生产报工 / 品质检验 / 来料检验 / 维修记录
- Active item highlighted with `AppColors.primary` background
- Bottom: sign-out button
- Active detection via `GoRouterState.of(context).matchedLocation`

### Router changes: `lib/config/router.dart`

- Replace the `/workshop` `GoRoute` + sub-routes with a **`ShellRoute`** that uses `WorkshopShell` as builder
- Sub-routes remain: `daily-report`, `quality`, `repair`, `incoming`
- Add redirect: `/workshop` → `/workshop/daily-report`
- Remove `WorkshopHomeScreen` import and usage

### Form screen changes (all 4 files)

Files:
- `lib/screens/workshop/daily_report_screen.dart`
- `lib/screens/workshop/quality_check_screen.dart`
- `lib/screens/workshop/repair_log_screen.dart`
- `lib/screens/workshop/incoming_inspection_screen.dart`

Changes per file:
1. **Remove `Scaffold` wrapper** — return `ListView(...)` directly (or wrap in `SafeArea`)
2. **Remove `AppBar`** — the shell provides the title context via the active menu item
3. **Change submit success handler**: replace `context.pop()` with form reset + SnackBar

Form reset pattern:
```dart
// After successful submit:
setState(() {
  // Reset all controllers and state to initial values
  _formKey.currentState?.reset();
  _selectedXxx = initialValue;
  _controller.clear();
});
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('提交成功'), backgroundColor: Color(0xFF10B981)),
  );
}
```

### WorkshopHomeScreen

Keep the file but it becomes unreachable (no route points to it). Can be deleted in a future cleanup sprint.

---

## Menu Items

| Label    | Icon                      | Route                    |
|----------|---------------------------|--------------------------|
| 生产报工  | Icons.factory_rounded     | /workshop/daily-report   |
| 品质检验  | Icons.verified_rounded    | /workshop/quality        |
| 来料检验  | Icons.inventory_rounded   | /workshop/incoming       |
| 维修记录  | Icons.build_rounded       | /workshop/repair         |

All 4 items visible to all roles. Backend RLS handles permission enforcement.

---

## Out of Scope

- Role-based menu filtering (moved to backend RLS)
- Recent records list after submit
- Sprint 3 items (defect-codes, repair-history) — keep as stub routes but don't add to sidebar yet
