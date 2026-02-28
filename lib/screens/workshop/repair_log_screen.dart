import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/report_providers.dart';

const _kFaultTypes = [
  '电气故障',
  '机械故障',
  '外观损伤',
  '软件/固件',
  '物料问题',
  '操作失误',
  '其他',
];

class RepairLogScreen extends ConsumerStatefulWidget {
  const RepairLogScreen({super.key});

  @override
  ConsumerState<RepairLogScreen> createState() => _RepairLogScreenState();
}

class _RepairLogScreenState extends ConsumerState<RepairLogScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  final Set<String> _selectedFaultTypes = {};
  final _actionCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _actionCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFaultTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一种故障类型'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(repairRecordsProvider.notifier).submit(
            date: DateTime.now(),
            productId: _selectedProductId,
            faultTypes: _selectedFaultTypes.toList(),
            repairAction: _actionCtrl.text,
            durationMinutes: int.tryParse(_durationCtrl.text),
          );

      if (mounted) {
        setState(() {
          _selectedProductId = null;
          _selectedFaultTypes.clear();
          _actionCtrl.clear();
          _durationCtrl.clear();
        });
        _formKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('维修记录提交成功'),
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
            const Text('产品（可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            productsAsync.maybeWhen(
              data: (products) => DropdownButtonFormField<String>(
                value: _selectedProductId,
                dropdownColor: const Color(0xFF1E293B),
                style:
                    const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '选择产品',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF334155)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('-- 不关联产品 --',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  ...products.map((p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name),
                      )),
                ],
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            const Text('故障类型（可多选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kFaultTypes.map((type) {
                final selected = _selectedFaultTypes.contains(type);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedFaultTypes.remove(type);
                    } else {
                      _selectedFaultTypes.add(type);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('维修措施 *',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _actionCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写维修措施' : null,
              decoration: InputDecoration(
                hintText: '描述维修过程和处理措施...',
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3B82F6), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('维修时长（分钟，可选）',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(
                    color: Colors.white24, fontSize: 24),
                suffixText: '分钟',
                suffixStyle:
                    const TextStyle(color: Colors.white54, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFF3B82F6), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
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
                        '提交记录',
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
