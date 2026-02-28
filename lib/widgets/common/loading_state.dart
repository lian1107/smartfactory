import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smartfactory/config/theme.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Shimmer skeleton for card lists
class ShimmerCardList extends StatelessWidget {
  final int count;
  final double cardHeight;

  const ShimmerCardList({
    super.key,
    this.count = 4,
    this.cardHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for kanban columns
class ShimmerKanban extends StatelessWidget {
  const ShimmerKanban({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white,
      child: Row(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 16 : 8,
              right: 8,
              top: 16,
              bottom: 16,
            ),
            child: SizedBox(
              width: 280,
              child: Column(
                children: [
                  // Column header
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cards
                  ...List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
