import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ProfileHeader extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final String supportingText;
  final List<String> interests;
  final String accountStatus;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.supportingText,
    this.interests = const [],
    this.accountStatus = 'Cuenta activa',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().substring(0, 1).toUpperCase()
        : 'R';
    final visibleInterests = interests.take(4).toList();
    final isMobile = AppResponsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppResponsive.cardRadius(context) + 4,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepForest, AppColors.forest, AppColors.moss],
        ),
        boxShadow: AppColors.liftedShadow,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -34,
            top: -44,
            child: _DecorativeOrb(size: 150, opacity: 0.12),
          ),
          const Positioned(
            left: -46,
            bottom: -58,
            child: _DecorativeOrb(size: 130, opacity: 0.08),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 64 : 74,
                    height: isMobile ? 64 : 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (isMobile) const SizedBox(height: 12) else const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.sun,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          accountStatus,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Hola, $displayName',
                style:
                    (isMobile
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.displaySmall)
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
              ),
              const SizedBox(height: 10),
              Text(
                '$subtitle · $supportingText',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (visibleInterests.isEmpty)
                    const _InterestPill(label: 'Explorando intereses')
                  else
                    ...visibleInterests.map(
                      (item) => _InterestPill(label: item),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestPill extends StatelessWidget {
  final String label;

  const _InterestPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeOrb({required this.size, required this.opacity});

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
