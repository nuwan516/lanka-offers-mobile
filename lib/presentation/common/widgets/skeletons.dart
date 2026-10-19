import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';

/// Placeholder shaped like an [OfferCard], shown while offers load.
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final block =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(96, 18),
          const SizedBox(height: 14),
          bar(180, 16),
          const SizedBox(height: 8),
          bar(double.infinity, 12),
          const SizedBox(height: 6),
          bar(220, 12),
          const SizedBox(height: 14),
          bar(120, 22),
          const SizedBox(height: 14),
          bar(150, 12),
        ],
      ),
    );
  }
}

/// A few skeleton cards. Does not scroll, so it can sit anywhere, including
/// inside a sliver.
class SkeletonFeed extends StatelessWidget {
  const SkeletonFeed({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.all(16),
  });

  final int count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final column = Padding(
      padding: padding,
      child: Column(
        children: [for (var i = 0; i < count; i++) const OfferCardSkeleton()],
      ),
    );
    return Semantics(
      label: 'Loading',
      child:
          reduceMotion
              ? column
              : Shimmer.fromColors(
                baseColor:
                    isDark ? const Color(0xFF263033) : const Color(0xFFEDECE7),
                highlightColor:
                    isDark ? const Color(0xFF30393C) : const Color(0xFFFAFAF7),
                child: column,
              ),
    );
  }
}

/// [SkeletonFeed] for use as a screen body: clipped, never scrolls.
class SkeletonBody extends StatelessWidget {
  const SkeletonBody({super.key});

  @override
  Widget build(BuildContext context) => const ClipRect(
    child: SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: SkeletonFeed(),
    ),
  );
}
