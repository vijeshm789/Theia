import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerPriceCard extends StatelessWidget {
  const ShimmerPriceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 14,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 10,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 120,
              height: 28,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 14,
              color: Colors.white.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerNewsCard extends StatelessWidget {
  const ShimmerNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 12, color: Colors.white10),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white10,
                  ),
                  const SizedBox(height: 6),
                  Container(width: 200, height: 16, color: Colors.white10),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
