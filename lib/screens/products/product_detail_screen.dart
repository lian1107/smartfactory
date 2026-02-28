import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/models/document_link.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/widgets/common/confirm_dialog.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return productAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingState(),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(error: err),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorState(error: '产品不存在'),
          );
        }
        return _ProductDetailView(
          product: product,
          tabController: _tabController,
        );
      },
    );
  }
}

class _ProductDetailView extends ConsumerWidget {
  final Product product;
  final TabController tabController;

  const _ProductDetailView({
    required this.product,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (canEdit(profile?.role)) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/products/${product.id}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: '详情'),
            Tab(text: '文档'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _DetailsTab(product: product),
          _DocumentsTab(productId: product.id),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除产品',
      message: '确认删除产品"${product.name}"？此操作不可撤销。',
      confirmLabel: '删除',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      await ref.read(productListProvider.notifier).deleteProduct(product.id);
      if (context.mounted) context.go('/products');
    }
  }
}

class _DetailsTab extends StatelessWidget {
  final Product product;

  const _DetailsTab({required this.product});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: '产品编号', value: product.code),
                  _InfoRow(label: '产品名称', value: product.name),
                  if (product.category != null)
                    _InfoRow(label: '分类', value: product.category!),
                  _InfoRow(label: '单位', value: product.unit),
                  _InfoRow(
                    label: '状态',
                    value: product.isActive ? '在用' : '已停用',
                    valueColor:
                        product.isActive ? AppColors.success : AppColors.error,
                  ),
                  if (product.description != null)
                    _InfoRow(label: '描述', value: product.description!),
                  if (product.specification != null)
                    _InfoRow(label: '规格', value: product.specification!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsTab extends ConsumerWidget {
  final String productId;

  const _DocumentsTab({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<DocumentLink>>(
      future: ref.read(productRepositoryProvider).fetchDocuments(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              '暂无文档',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _DocumentTile(doc: docs[i]),
        );
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentLink doc;

  const _DocumentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.link, color: AppColors.primary),
      title: Text(doc.title),
      subtitle: Text(doc.docType),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () async {
        final uri = Uri.parse(doc.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
