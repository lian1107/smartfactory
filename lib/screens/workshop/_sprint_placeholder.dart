import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartfactory/config/theme.dart';

/// Shared placeholder widget for Sprint 3 workshop sub-screens
class _SprintPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String sprint;
  final String description;

  const _SprintPlaceholder({
    required this.title,
    required this.icon,
    required this.color,
    required this.sprint,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/workshop'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Icon(icon, color: color, size: 44),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Text(
                  '开发中 · $sprint',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
