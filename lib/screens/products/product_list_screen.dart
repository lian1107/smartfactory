import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/widgets/common/empty_state.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('产品管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(productListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('新建产品'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索产品名称或编号...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(productListProvider.notifier)
                              .setFilter(search: '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                ref
                    .read(productListProvider.notifier)
                    .setFilter(search: value);
              },
            ),
          ),
          // List
          Expanded(
            child: productsAsync.when(
              loading: () => const ShimmerCardList(),
              error: (err, _) => ErrorState(
                error: err,
                onRetry: () =>
                    ref.read(productListProvider.notifier).refresh(),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    message: '暂无产品',
                    subMessage: '点击右下角按钮创建第一个产品',
                    icon: Icons.inventory_2_outlined,
                    action: ElevatedButton(
                      onPressed: () => context.go('/products/new'),
                      child: const Text('新建产品'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(productListProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) =>
                        _ProductCard(product: products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/products/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (!product.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textDisabled.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '已停用',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.code,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              if (product.category != null) ...[
                const SizedBox(height: 6),
                Text(
                  product.category!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
