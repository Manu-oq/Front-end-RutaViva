import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/skeleton_container.dart';

class DestinationSkeleton extends StatelessWidget {
  const DestinationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    return SliverPadding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            SkeletonContainer(
              height: isMobile ? 210 : 250,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            const SizedBox(height: 12),
            const SkeletonContainer(height: 20, width: 150),
            const SizedBox(height: 12),
            SkeletonContainer(height: isMobile ? 52 : 60),
          ],
        ),
      ),
    );
  }
}
