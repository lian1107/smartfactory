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
