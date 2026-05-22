import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_colors.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppResponsive.cardPadding(context);
    final isMobile = AppResponsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 38 : 42,
                height: isMobile ? 38 : 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 20 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style:
                      (isMobile
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
