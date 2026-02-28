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
