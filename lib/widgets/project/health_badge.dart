import 'package:flutter/material.dart';
import 'package:smartfactory/utils/format_utils.dart';

class HealthBadge extends StatelessWidget {
  final String health;
  final bool showLabel;

  const HealthBadge({
    super.key,
    required this.health,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = FormatUtils.healthColor(health);
    final label = FormatUtils.healthLabel(health);

    if (!showLabel) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
