import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/models/project_template.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/utils/validators.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedProductId;
  String? _selectedTemplateId;
  DateTime? _plannedEndDate;
  int _priority = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(projectTemplatesProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('新建项目')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Template selector
              templatesAsync.when(
                loading: () =>
                    const ShimmerCardList(count: 3, cardHeight: 80),
                error: (e, _) => const SizedBox(),
                data: (templates) => _TemplateSelector(
                  templates: templates,
                  selectedId: _selectedTemplateId,
                  onSelected: (id) =>
                      setState(() => _selectedTemplateId = id),
                ),
              ),
              const SizedBox(height: 16),

              // Basic info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '基本信息',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: '项目名称 *'),
                        validator: (v) => Validators.required(v, '项目名称'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionCtrl,
                        decoration: const InputDecoration(labelText: '项目描述'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Product linkage
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '关联产品（可选）',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      productsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('加载产品失败'),
                        data: (products) =>
                            DropdownButtonFormField<String?>(
                          value: _selectedProductId,
                          decoration:
                              const InputDecoration(labelText: '选择产品'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('不关联产品'),
                            ),
                            ...products.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.code} - ${p.name}'),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedProductId = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Schedule & priority
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '计划与优先级',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickEndDate,
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: '计划截止日期'),
                          child: Text(
                            _plannedEndDate != null
                                ? '${_plannedEndDate!.year}-${_plannedEndDate!.month.toString().padLeft(2, '0')}-${_plannedEndDate!.day.toString().padLeft(2, '0')}'
                                : '点击选择日期',
                            style: TextStyle(
                              color: _plannedEndDate != null
                                  ? null
                                  : AppColors.textDisabled,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '优先级',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _priority.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _priorityLabel(_priority),
                        onChanged: (v) =>
                            setState(() => _priority = v.round()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('创建项目'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(int p) {
    const labels = {1: '最低', 2: '低', 3: '中', 4: '高', 5: '最高'};
    return labels[p] ?? '$p';
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _plannedEndDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一个项目模板')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      final project = await ref
          .read(projectListProvider.notifier)
          .createProject(
            title: _titleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim().isEmpty
                ? null
                : _descriptionCtrl.text.trim(),
            productId: _selectedProductId,
            templateId: _selectedTemplateId,
            plannedEndDate: _plannedEndDate,
            priority: _priority,
          );

      // Create phases from template
      final templates = await ref.read(projectTemplatesProvider.future);
      final phaseTemplates = await ref.read(phaseTemplatesProvider.future);
      final template =
          templates.where((t) => t.id == _selectedTemplateId).firstOrNull;
      if (template != null) {
        await ref
            .read(projectRepositoryProvider)
            .createPhasesFromTemplate(project.id, template, phaseTemplates);
      }

      if (mounted) context.go('/projects/${project.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _TemplateSelector extends StatelessWidget {
  final List<ProjectTemplate> templates;
  final String? selectedId;
  final void Function(String id) onSelected;

  const _TemplateSelector({
    required this.templates,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择项目模板 *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...templates.map(
          (t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selectedId == t.id
                    ? AppColors.primary
                    : AppColors.border,
                width: selectedId == t.id ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Radio<String>(
                value: t.id,
                groupValue: selectedId,
                onChanged: (v) => onSelected(v!),
              ),
              title: Row(
                children: [
                  Text(t.name),
                  if (t.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '推荐',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: t.description != null ? Text(t.description!) : null,
              trailing: Text(
                '${t.phaseIds.length} 个阶段',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => onSelected(t.id),
            ),
          ),
        ),
      ],
    );
  }
}
