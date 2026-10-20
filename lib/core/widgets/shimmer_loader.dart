import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

class ShimmerCardLoader extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const ShimmerCardLoader({
    super.key,
    this.height = 90.0,
    this.width = double.infinity,
    this.borderRadius = 14.0,
    this.margin = const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2EBE2),
        highlightColor: const Color(0xFFF1F8F1),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class ShimmerListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 96.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        return ShimmerCardLoader(height: itemHeight);
      },
    );
  }
}
