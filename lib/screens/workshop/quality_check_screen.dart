import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/report_providers.dart';
import 'package:smartfactory/widgets/production/big_number_field.dart';

class QualityCheckScreen extends ConsumerStatefulWidget {
  const QualityCheckScreen({super.key});

  @override
  ConsumerState<QualityCheckScreen> createState() =>
      _QualityCheckScreenState();
}

class _QualityCheckScreenState extends ConsumerState<QualityCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  String _inspectionType = 'full';
  String? _selectedProductId;
  final _totalCtrl = TextEditingController();
  final _defectCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _totalCtrl.dispose();
    _defectCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final total = int.tryParse(_totalCtrl.text) ?? 0;
    final defect = int.tryParse(_defectCtrl.text) ?? 0;

    if (defect > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不良数量不能大于检验总数'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(qualityRecordsProvider.notifier).submit(
            date: DateTime.now(),
            inspectionType: _inspectionType,
            productId: _selectedProductId,
            totalQty: total,
            defectQty: defect,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          );

      if (mounted) {
        setState(() {
          _inspectionType = 'full';
          _selectedProductId = null;
          _totalCtrl.clear();
          _defectCtrl.text = '0';
          _notesCtrl.clear();
        });
        _formKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('检验记录提交成功'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);

    return Form(
      key: _formKey,
      child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('检验类型',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeButton(
                  label: '全检',
                  selected: _inspectionType == 'full',
                  onTap: () => setState(() => _inspectionType = 'full'),
                ),
                const SizedBox(width: 12),
                _TypeButton(
                  label: '抽检',
                  selected: _inspectionType == 'sample',
                  onTap: () => setState(() => _inspectionType = 'sample'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('产品（可选）',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            productsAsync.maybeWhen(
              data: (products) => _ProductDropdown(
                products: products,
                value: _selectedProductId,
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            BigNumberField(label: '检验总数', controller: _totalCtrl),
            const SizedBox(height: 16),
            BigNumberField(
              label: '不良总数',
              controller: _defectCtrl,
              isRequired: false,
            ),
            const SizedBox(height: 16),

            const Text('不良描述（可选）',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述不良现象...',
                hintStyle:
                    const TextStyle(color: AppColors.textDisabled, fontSize: 13),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3B82F6), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '提交检验',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3B82F6)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3B82F6)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDropdown extends StatelessWidget {
  final List<Product> products;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ProductDropdown({
    required this.products,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: '不选则不关联产品',
        hintStyle: const TextStyle(color: AppColors.textDisabled),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('-- 不关联产品 --',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ...products.map((p) => DropdownMenuItem<String>(
              value: p.id,
              child: Text(p.name),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
