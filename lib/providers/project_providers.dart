import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/models/project.dart';
import 'package:smartfactory/models/project_phase.dart';
import 'package:smartfactory/models/project_template.dart';
import 'package:smartfactory/models/phase_template.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/repositories/project_repository.dart';
import 'package:smartfactory/repositories/product_repository.dart';
import 'package:smartfactory/providers/auth_provider.dart';

// ─── Repositories ───────────────────────────────────────────
final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(ref.watch(supabaseClientProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(supabaseClientProvider)),
);

// ─── Project list ───────────────────────────────────────────
class _ProjectListNotifier extends AsyncNotifier<List<Project>> {
  String _statusFilter = '';
  String _search = '';

  @override
  Future<List<Project>> build() => _fetch();

  Future<List<Project>> _fetch() =>
      ref.read(projectRepositoryProvider).fetchProjects(
            status: _statusFilter.isEmpty ? null : _statusFilter,
            search: _search.isEmpty ? null : _search,
          );

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setFilter({String? status, String? search}) {
    if (status != null) _statusFilter = status;
    if (search != null) _search = search;
    ref.invalidateSelf();
  }

  Future<Project> createProject({
    required String title,
    String? description,
    String? productId,
    String? templateId,
    DateTime? plannedEndDate,
    int priority = 3,
  }) async {
    final project = await ref.read(projectRepositoryProvider).createProject({
      'title': title,
      if (description != null) 'description': description,
      if (productId != null) 'product_id': productId,
      if (templateId != null) 'template_id': templateId,
      if (plannedEndDate != null)
        'planned_end_date': plannedEndDate.toIso8601String().substring(0, 10),
      'priority': priority,
    });
    ref.invalidateSelf();
    return project;
  }
}

final projectListProvider =
    AsyncNotifierProvider<_ProjectListNotifier, List<Project>>(
  _ProjectListNotifier.new,
);

// ─── Single project ──────────────────────────────────────────
final projectDetailProvider =
    FutureProvider.family<Project?, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).fetchProject(projectId);
});

// ─── Project phases ─────────────────────────────────────────
class _ProjectPhasesNotifier
    extends FamilyAsyncNotifier<List<ProjectPhase>, String> {
  @override
  Future<List<ProjectPhase>> build(String arg) =>
      ref.watch(projectRepositoryProvider).fetchPhases(arg);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(projectRepositoryProvider).fetchPhases(arg),
    );
  }

  Future<void> updatePhase(
    String phaseId,
    Map<String, dynamic> updates,
  ) async {
    await ref.read(projectRepositoryProvider).updatePhase(phaseId, updates);
    ref.invalidateSelf();
  }
}

final projectPhasesProvider = AsyncNotifierProvider.family<
    _ProjectPhasesNotifier, List<ProjectPhase>, String>(
  _ProjectPhasesNotifier.new,
);

// ─── Templates ───────────────────────────────────────────────
final projectTemplatesProvider = FutureProvider<List<ProjectTemplate>>(
  (ref) => ref.watch(projectRepositoryProvider).fetchProjectTemplates(),
);

final phaseTemplatesProvider = FutureProvider<List<PhaseTemplate>>(
  (ref) => ref.watch(projectRepositoryProvider).fetchPhaseTemplates(),
);

// ─── Product list ───────────────────────────────────────────
class _ProductListNotifier extends AsyncNotifier<List<Product>> {
  String _search = '';
  String _category = '';

  @override
  Future<List<Product>> build() => _fetch();

  Future<List<Product>> _fetch() =>
      ref.read(productRepositoryProvider).fetchProducts(
            search: _search.isEmpty ? null : _search,
            category: _category.isEmpty ? null : _category,
            isActive: true,
          );

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setFilter({String? search, String? category}) {
    if (search != null) _search = search;
    if (category != null) _category = category;
    ref.invalidateSelf();
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final product =
        await ref.read(productRepositoryProvider).createProduct(payload);
    ref.invalidateSelf();
    return product;
  }

  Future<Product> updateProduct(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final product =
        await ref.read(productRepositoryProvider).updateProduct(id, updates);
    ref.invalidateSelf();
    return product;
  }

  Future<void> deleteProduct(String id) async {
    await ref.read(productRepositoryProvider).deleteProduct(id);
    ref.invalidateSelf();
  }
}

final productListProvider =
    AsyncNotifierProvider<_ProductListNotifier, List<Product>>(
  _ProductListNotifier.new,
);

// ─── Single product ─────────────────────────────────────────
final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).fetchProduct(productId);
});
