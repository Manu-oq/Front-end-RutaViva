import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';

class ItineraryDetailSkeleton extends StatelessWidget {
  const ItineraryDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const SkeletonContainer(height: 28, width: 200),
                const SizedBox(height: 12),
                const SkeletonContainer(height: 14),
                const SizedBox(height: 40),
                ...List.generate(
                  4,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonContainer(height: 14, width: 140),
                        SizedBox(height: 12),
                        SkeletonContainer(
                          height: 90,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
