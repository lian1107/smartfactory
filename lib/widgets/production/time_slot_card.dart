import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfactory/config/theme.dart';

class TimeSlotFormData {
  final int slotStart;
  final int slotEnd;
  final TextEditingController plannedCtrl;
  final TextEditingController actualCtrl;
  final TextEditingController defectCtrl;
  final TextEditingController noteCtrl;

  TimeSlotFormData({
    required this.slotStart,
    required this.slotEnd,
  })  : plannedCtrl = TextEditingController(),
        actualCtrl = TextEditingController(),
        defectCtrl = TextEditingController(text: '0'),
        noteCtrl = TextEditingController();

  void dispose() {
    plannedCtrl.dispose();
    actualCtrl.dispose();
    defectCtrl.dispose();
    noteCtrl.dispose();
  }

  Map<String, dynamic> toPayload() => {
        'slot_start': slotStart,
        'slot_end': slotEnd,
        'planned_qty': int.tryParse(plannedCtrl.text) ?? 0,
        'actual_qty': int.tryParse(actualCtrl.text) ?? 0,
        'defect_qty': int.tryParse(defectCtrl.text) ?? 0,
        if (noteCtrl.text.isNotEmpty) 'downtime_reason': noteCtrl.text,
      };
}

class TimeSlotCard extends StatelessWidget {
  final TimeSlotFormData data;

  const TimeSlotCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final label =
        '${data.slotStart.toString().padLeft(2, '0')}:00 — ${data.slotEnd.toString().padLeft(2, '0')}:00';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SlotNumberField(
                  label: '计划',
                  controller: data.plannedCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotNumberField(
                  label: '实际',
                  controller: data.actualCtrl,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotNumberField(
                  label: '不良',
                  controller: data.defectCtrl,
                  defaultValue: '0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: data.noteCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 1,
            decoration: InputDecoration(
              hintText: '停线原因 / 异常备注（可选）',
              hintStyle:
                  const TextStyle(color: AppColors.textDisabled, fontSize: 13),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                    color: Color(0xFF3B82F6), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? defaultValue;

  const _SlotNumberField({
    required this.label,
    required this.controller,
    this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: defaultValue ?? '-',
            hintStyle: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 22,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF3B82F6), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            isDense: true,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? '必填' : null,
        ),
      ],
    );
  }
}
