import 'package:flutter/material.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';

class PoiGalleryHeader extends StatelessWidget {
  final String? imageUrl;
  final String heroTag;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  const PoiGalleryHeader({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 390,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.deepForest,
      foregroundColor: Colors.white,
      leading: const AppBackButton(
        fallbackRouteName: AppRouteNames.map,
        color: Colors.white,
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              child: trailing!,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsets.fromLTRB(72, 0, 20, 12),
        title: title == null
            ? null
            : _PoiHeaderCollapsedTitle(title: title!, subtitle: subtitle),
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? Hero(
                    tag: heroTag,
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _PoiImagePlaceholder(),
                    ),
                  )
                : const _PoiImagePlaceholder(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.05),
                    AppColors.deepForest.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoiHeaderCollapsedTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PoiHeaderCollapsedTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: SizedBox(
        height: subtitle == null ? 22 : 38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Flexible(
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 9.5,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoiImagePlaceholder extends StatelessWidget {
  const _PoiImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepForest, AppColors.forest, AppColors.leaf],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -36,
            top: -28,
            child: _Orb(size: 160, opacity: 0.12),
          ),
          const Positioned(
            left: -46,
            bottom: 48,
            child: _Orb(size: 130, opacity: 0.08),
          ),
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(
                Icons.landscape_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final double opacity;

  const _Orb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
