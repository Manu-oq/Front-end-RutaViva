import 'package:flutter/material.dart';
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

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(34),
                boxShadow: AppColors.liftedShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 300,
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
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
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
                                  style: theme.textTheme.headlineLarge
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
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: theme.textTheme.bodyLarge,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: onSetRoute,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Ver en mapa'),
                                ),
                              ),
                              const SizedBox(width: 12),
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
