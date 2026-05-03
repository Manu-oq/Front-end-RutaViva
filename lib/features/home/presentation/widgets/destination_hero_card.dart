import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppColors.ambientShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _DestinationImageFallback(),
                      )
                    : const _DestinationImageFallback(),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.toUpperCase(),
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        if (distanceLabel != null)
                          Text(
                            distanceLabel!,
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SmallButton(
                          label: 'Ver en mapa',
                          isPrimary: true,
                          onTap: onSetRoute,
                        ),
                        _SmallButton(
                          label: 'Detalles',
                          isPrimary: false,
                          onTap: onDetails,
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
    );
  }
}

class _DestinationImageFallback extends StatelessWidget {
  const _DestinationImageFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 250,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Icon(
        Icons.landscape_outlined,
        size: 72,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
