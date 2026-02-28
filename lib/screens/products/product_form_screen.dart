import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/utils/validators.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _specificationCtrl = TextEditingController();
  String _unit = 'pcs';
  bool _isLoading = false;
  Product? _existingProduct;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _specificationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final product = await ref
        .read(productRepositoryProvider)
        .fetchProduct(widget.productId!);
    if (product != null && mounted) {
      setState(() {
        _existingProduct = product;
        _nameCtrl.text = product.name;
        _codeCtrl.text = product.code;
        _descriptionCtrl.text = product.description ?? '';
        _categoryCtrl.text = product.category ?? '';
        _specificationCtrl.text = product.specification ?? '';
        _unit = product.unit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑产品' : '新建产品'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: '基本信息',
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: '产品名称 *'),
                    validator: (v) => Validators.required(v, '产品名称'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: '产品编号 *',
                      hintText: 'e.g. PROD-001',
                    ),
                    validator: Validators.productCode,
                    enabled: !_isEditing,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(labelText: '分类'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: '单位'),
                    items: const [
                      DropdownMenuItem(value: 'pcs', child: Text('件 (pcs)')),
                      DropdownMenuItem(value: 'set', child: Text('套 (set)')),
                      DropdownMenuItem(value: 'kg', child: Text('千克 (kg)')),
                      DropdownMenuItem(value: 'm', child: Text('米 (m)')),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '详细信息',
                children: [
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(labelText: '描述'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specificationCtrl,
                    decoration: const InputDecoration(labelText: '规格参数'),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? '保存修改' : '创建产品'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(supabaseClientProvider).auth.currentUser;
    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await ref.read(productListProvider.notifier).updateProduct(
          widget.productId!,
          {
            'name': _nameCtrl.text.trim(),
            'description': _descriptionCtrl.text.trim().isEmpty
                ? null
                : _descriptionCtrl.text.trim(),
            'category': _categoryCtrl.text.trim().isEmpty
                ? null
                : _categoryCtrl.text.trim(),
            'specification': _specificationCtrl.text.trim().isEmpty
                ? null
                : _specificationCtrl.text.trim(),
            'unit': _unit,
          },
        );
        if (mounted) context.go('/products/${widget.productId}');
      } else {
        final product =
            await ref.read(productListProvider.notifier).createProduct({
          'code': _codeCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'description': _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          'category': _categoryCtrl.text.trim().isEmpty
              ? null
              : _categoryCtrl.text.trim(),
          'specification': _specificationCtrl.text.trim().isEmpty
              ? null
              : _specificationCtrl.text.trim(),
          'unit': _unit,
          if (user != null) 'created_by': user.id,
        });
        if (mounted) context.go('/products/${product.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
