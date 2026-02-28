import 'package:flutter/material.dart';
import 'package:smartfactory/config/theme.dart';

enum Shift { early, mid, late }

extension ShiftExt on Shift {
  String get label {
    switch (this) {
      case Shift.early:
        return '早班';
      case Shift.mid:
        return '中班';
      case Shift.late:
        return '晚班';
    }
  }

  String get value {
    switch (this) {
      case Shift.early:
        return 'early';
      case Shift.mid:
        return 'mid';
      case Shift.late:
        return 'late';
    }
  }

  String get timeRange {
    switch (this) {
      case Shift.early:
        return '08:00-12:00';
      case Shift.mid:
        return '13:00-17:00';
      case Shift.late:
        return '18:00-21:00';
    }
  }

  /// 返回该班次的时段列表，每项为 [start, end] 小时数
  List<List<int>> get slots {
    switch (this) {
      case Shift.early:
        return [
          [8, 9],
          [9, 10],
          [10, 11],
          [11, 12]
        ];
      case Shift.mid:
        return [
          [13, 14],
          [14, 15],
          [15, 16],
          [16, 17]
        ];
      case Shift.late:
        return [
          [18, 19],
          [19, 20],
          [20, 21]
        ];
    }
  }
}

class ShiftSelector extends StatelessWidget {
  final Shift selected;
  final ValueChanged<Shift> onChanged;

  const ShiftSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Shift.values.map((shift) {
        final isSelected = shift == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(shift),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFF334155),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      shift.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.timeRange,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
