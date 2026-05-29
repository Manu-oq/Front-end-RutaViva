import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/authenticated_network_image.dart';

class VibeCard extends StatelessWidget {
  final String category;
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const VibeCard({
    super.key,
    required this.category,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardHeight = (availableWidth * (isMobile ? 1.0 : 0.62))
            .clamp(240.0, 420.0)
            .toDouble();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: cardHeight,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(32)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AuthenticatedNetworkImage(
                  imageUrl: imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_) => ColoredBox(
                    color: AppColors.forest.withValues(alpha: 0.22),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.volcanicObsidian.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: isMobile ? 16 : 24,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 18 : 24),
                      color: Colors.white.withValues(alpha: 0.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: isMobile ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
