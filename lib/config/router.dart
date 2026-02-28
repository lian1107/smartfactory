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
import 'package:smartfactory/widgets/workshop/workshop_shell.dart';

/// Roles that belong to the workshop (floor) experience.
const _workshopRoles = {'leader', 'qc', 'technician'};

bool _isWorkshopRole(String? role) =>
    role != null && _workshopRoles.contains(role);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    // ─── Global redirect ───────────────────────────────────────
    redirect: (context, state) {
      // While auth is loading don't redirect — prevents flicker
      if (authState.isLoading) return null;

      final session = authState.valueOrNull?.session;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;
      final isLoginPage = loc == '/login';

      // 1. Not logged in → always go to /login
      if (!isLoggedIn) {
        return isLoginPage ? null : '/login';
      }

      // 2. Logged in + on /login → role-based home
      if (isLoginPage) {
        final role = profileAsync.valueOrNull?.role;
        return _isWorkshopRole(role) ? '/workshop/daily-report' : '/';
      }

      // 3. Logged in + profile loaded + workshop role → ensure on /workshop tree
      //    (only redirect from the root dashboard, not from shared pages
      //     like /workspace or /projects that workshop users may also visit)
      if (loc == '/' || loc == '/workshop') {
        final role = profileAsync.valueOrNull?.role;
        if (_isWorkshopRole(role)) return '/workshop/daily-report';
      }

      return null; // let through
    },

    routes: [
      // ─── Auth ──────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

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

      // ─── Office / admin routes (wrapped in AppScaffold) ────
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

// ─── Inline Sprint 3 placeholders ─────────────────────────────

class _DefectCodesPlaceholder extends StatelessWidget {
  const _DefectCodesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sprint 3 开发中',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _RepairHistoryPlaceholder extends StatelessWidget {
  const _RepairHistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sprint 3 开发中',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
