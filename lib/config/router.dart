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
import 'package:smartfactory/screens/docs/doc_list_screen.dart';
import 'package:smartfactory/screens/docs/doc_form_screen.dart';
import 'package:smartfactory/screens/docs/doc_detail_screen.dart';
import 'package:smartfactory/screens/ai/ai_screen.dart';
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
            builder: (_, __) => const AiScreen(),
          ),
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
            routes: [
              GoRoute(
                path: 'edit',
                name: 'doc-edit',
                builder: (_, state) => DocFormScreen(
                  docId: state.pathParameters['id'],
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

