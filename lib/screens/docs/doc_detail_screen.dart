import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smartfactory/config/constants.dart';
import 'package:smartfactory/config/theme.dart';
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
                  onPressed: () => context.go('/docs/${doc.id}/edit'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
            const Row(
              children: [
                Icon(Icons.open_in_new,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
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
