import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint ?? '0',
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
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
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
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
