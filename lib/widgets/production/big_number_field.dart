import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfactory/config/theme.dart';

/// 大字号数字输入框，适合车间手机操作
class BigNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool isRequired;

  const BigNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint ?? '0',
            hintStyle: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? '请填写$label' : null
              : null,
        ),
      ],
    );
  }
}
