import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Pre-configured Category Circle Shimmer
  static Widget categoryItem() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          ShimmerLoader(width: 64, height: 64, borderRadius: 32),
          SizedBox(height: 8),
          ShimmerLoader(width: 50, height: 12, borderRadius: 4),
        ],
      ),
    );
  }

  // Pre-configured Product Card Shimmer
  static Widget productCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(width: double.infinity, height: 140, borderRadius: 16),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(width: 80, height: 10, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerLoader(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerLoader(width: 60, height: 14, borderRadius: 4),
                    ShimmerLoader(width: 32, height: 32, borderRadius: 16),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
