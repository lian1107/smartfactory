import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/providers/report_providers.dart';
import 'package:smartfactory/widgets/production/big_number_field.dart';

class IncomingInspectionScreen extends ConsumerStatefulWidget {
  const IncomingInspectionScreen({super.key});

  @override
  ConsumerState<IncomingInspectionScreen> createState() =>
      _IncomingInspectionScreenState();
}

class _IncomingInspectionScreenState
    extends ConsumerState<IncomingInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _defectCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  String _result = 'pass';
  bool _submitting = false;

  @override
  void dispose() {
    _materialCtrl.dispose();
    _supplierCtrl.dispose();
    _totalCtrl.dispose();
    _defectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final total = int.tryParse(_totalCtrl.text) ?? 0;
    final defect = int.tryParse(_defectCtrl.text) ?? 0;

    if (defect > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不良数量不能大于来料总数'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(incomingInspectionsProvider.notifier).submit(
            date: DateTime.now(),
            materialName: _materialCtrl.text.trim(),
            supplier: _supplierCtrl.text.trim().isEmpty
                ? null
                : _supplierCtrl.text.trim(),
            totalQty: total,
            defectQty: defect,
            defectDescription: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            result: _result,
          );

      if (mounted) {
        setState(() {
          _materialCtrl.clear();
          _supplierCtrl.clear();
          _totalCtrl.clear();
          _defectCtrl.text = '0';
          _descCtrl.clear();
          _result = 'pass';
          _formKey.currentState?.reset();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('来料检验提交成功'),
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
    return Form(
      key: _formKey,
      child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('物料名称 *',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _materialCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写物料名称' : null,
              decoration: _inputDecoration('如：电机、电池、外壳...'),
            ),
            const SizedBox(height: 16),

            const Text('供应商（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _supplierCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDecoration('供应商名称'),
            ),
            const SizedBox(height: 20),

            BigNumberField(label: '来料总数', controller: _totalCtrl),
            const SizedBox(height: 16),
            BigNumberField(
              label: '不良总数',
              controller: _defectCtrl,
              isRequired: false,
            ),
            const SizedBox(height: 16),

            const Text('不良描述（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              decoration:
                  _inputDecoration('描述不良现象，如：外观划伤、尺寸偏差...'),
            ),
            const SizedBox(height: 20),

            const Text('检验结论',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ResultButton(
                  label: '合格',
                  value: 'pass',
                  selected: _result == 'pass',
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _result = 'pass'),
                ),
                const SizedBox(width: 8),
                _ResultButton(
                  label: '条件接收',
                  value: 'conditional',
                  selected: _result == 'conditional',
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _result = 'conditional'),
                ),
                const SizedBox(width: 8),
                _ResultButton(
                  label: '不合格',
                  value: 'fail',
                  selected: _result == 'fail',
                  color: const Color(0xFFEF4444),
                  onTap: () => setState(() => _result = 'fail'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.white38, size: 20),
                  SizedBox(width: 8),
                  Text('拍照留证（Sprint 3 实现）',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _ResultButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFF334155),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
