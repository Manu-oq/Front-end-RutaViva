import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DestinationHeroCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final VoidCallback onSetRoute;
  final VoidCallback onDetails;

  const DestinationHeroCard({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.onSetRoute,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _SmallButton(
                          label: "Establecer Ruta",
                          isPrimary: true,
                          onTap: onSetRoute,
                        ),
                        const SizedBox(width: 12),
                        _SmallButton(
                          label: "Detalles",
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
