import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton_container.dart';

class DestinationSkeleton extends StatelessWidget {
  const DestinationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const SkeletonContainer(height: 250, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            const SizedBox(height: 12),
            const SkeletonContainer(height: 20, width: 150),
            const SizedBox(height: 12),
            const SkeletonContainer(height: 60),
          ],
        ),
      ),
    );
  }
}