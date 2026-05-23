import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_network_image.dart';

class DestinationHeroCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String? imageUrl;
  final String? distanceLabel;
  final VoidCallback onSetRoute;
  final VoidCallback onDetails;

  const DestinationHeroCard({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    this.imageUrl,
    this.distanceLabel,
    required this.onSetRoute,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final isMobile = AppResponsive.isMobile(context);
    final radius = AppResponsive.cardRadius(context) + 4;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 12 : 18,
        isMobile ? 16 : 24,
        isMobile ? 14 : 18,
      ),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth(context),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: AppColors.liftedShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: isMobile ? 220 : 300,
                      child: Semantics(
                        excludeSemantics: true,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            hasImage
                                ? AuthenticatedNetworkImage(
                                    imageUrl: imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_) =>
                                        const _DestinationImageFallback(),
                                  )
                                : const _DestinationImageFallback(),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.05),
                                    Colors.black.withValues(alpha: 0.62),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: isMobile ? 16 : 20,
                              right: isMobile ? 16 : 20,
                              bottom: isMobile ? 16 : 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _Pill(label: category.toUpperCase()),
                                      if (distanceLabel != null)
                                        _Pill(
                                          label: distanceLabel!,
                                          icon: Icons.near_me_outlined,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    title,
                                    style:
                                        (isMobile
                                                ? theme.textTheme.headlineSmall
                                                : theme.textTheme.headlineLarge)
                                            ?.copyWith(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: isMobile
                                ? theme.textTheme.bodyMedium
                                : theme.textTheme.bodyLarge,
                            maxLines: isMobile ? 3 : 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isMobile ? 16 : 22),
                          Flex(
                            direction: isMobile
                                ? Axis.vertical
                                : Axis.horizontal,
                            crossAxisAlignment: isMobile
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.center,
                            children: [
                              if (isMobile)
                                FilledButton.icon(
                                  onPressed: onSetRoute,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Ver en mapa'),
                                )
                              else
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: onSetRoute,
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('Ver en mapa'),
                                  ),
                                ),
                              SizedBox(
                                width: isMobile ? 0 : 12,
                                height: isMobile ? 10 : 0,
                              ),
                              if (isMobile)
                                OutlinedButton.icon(
                                  onPressed: onDetails,
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Ver detalles'),
                                )
                              else
                                IconButton.outlined(
                                  tooltip: 'Ver detalles',
                                  onPressed: onDetails,
                                  icon: const Icon(Icons.arrow_forward),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationImageFallback extends StatelessWidget {
  const _DestinationImageFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.landscape_outlined, size: 78, color: Colors.white70),
      ),
    );
  }
}
