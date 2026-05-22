import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton_container.dart';

class DestinationSkeleton extends StatelessWidget {
  const DestinationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            SkeletonContainer(
              height: 250,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            SizedBox(height: 12),
            SkeletonContainer(height: 20, width: 150),
            SizedBox(height: 12),
            SkeletonContainer(height: 60),
          ],
        ),
      ),
    );
  }
}
