import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/product.dart';
import 'package:smartfactory/providers/project_providers.dart';
import 'package:smartfactory/providers/report_providers.dart';
import 'package:smartfactory/widgets/production/shift_selector.dart';
import 'package:smartfactory/widgets/production/time_slot_card.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  Shift _shift = Shift.early;
  String? _selectedProductId;
  List<TimeSlotFormData> _slots = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rebuildSlots(Shift.early);
  }

  void _rebuildSlots(Shift shift) {
    for (final s in _slots) {
      s.dispose();
    }
    _slots = shift.slots
        .map((pair) =>
            TimeSlotFormData(slotStart: pair[0], slotEnd: pair[1]))
        .toList();
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(dailyReportsProvider.notifier).submit(
            date: DateTime.now(),
            shift: _shift.value,
            productId: _selectedProductId,
            slots: _slots.map((s) => s.toPayload()).toList(),
          );

      if (mounted) {
        setState(() {
          _shift = Shift.early;
          _selectedProductId = null;
          _rebuildSlots(Shift.early);
        });
        _formKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报工提交成功'),
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
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 班次选择
            const Text('选择班次',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            ShiftSelector(
              selected: _shift,
              onChanged: (s) {
                setState(() {
                  _shift = s;
                  _rebuildSlots(s);
                });
              },
            ),
            const SizedBox(height: 20),

            // 产品选择
            const Text('选择产品（可选）',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            productsAsync.when(
              loading: () => const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6), strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (products) => _ProductDropdown(
                products: products,
                value: _selectedProductId,
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              ),
            ),
            const SizedBox(height: 24),

            // 时段卡片
            const Text(
              '各时段产量',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._slots.map((s) => TimeSlotCard(data: s)),
            const SizedBox(height: 24),

            // 提交按钮
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
                        '提交报工',
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

  String _formatDate(DateTime d) {
    const weekdays = ['', '一', '二', '三', '四', '五', '六', '日'];
    return '${d.year}年${d.month}月${d.day}日  周${weekdays[d.weekday]}';
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
