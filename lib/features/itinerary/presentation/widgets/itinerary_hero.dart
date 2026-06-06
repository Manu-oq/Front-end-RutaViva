import 'package:flutter/material.dart';
import '../../data/models/itinerary_model.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_colors.dart';

class ItineraryHero extends StatelessWidget {
  final ItineraryModel itinerary;
  final String dateLabel;
  final int? stepsCount;
  final VoidCallback onHistory;
  final VoidCallback onMap;

  const ItineraryHero({
    super.key,
    required this.itinerary,
    required this.dateLabel,
    this.stepsCount,
    required this.onHistory,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppResponsive.cardRadius(context) + 4,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: AppColors.liftedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              HeroPill(icon: Icons.calendar_today_outlined, label: dateLabel),
              HeroPill(
                icon: Icons.place_outlined,
                label: '${stepsCount ?? itinerary.steps.length} paradas',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            itinerary.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                (isMobile
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                      color: Colors.white,
                      fontSize: isMobile ? 28 : 40,
                    ),
          ),
          const SizedBox(height: 12),
          Text(
            'Una ruta armada para descubrir lugares, pausas y detalles locales a tu ritmo.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 24),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              if (isMobile)
                FilledButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir mapa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                )
              else
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Abrir mapa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 10 : 0),
              if (isMobile)
                OutlinedButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Ver historial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                )
              else
                IconButton.filledTonal(
                  tooltip: 'Ver historial',
                  onPressed: onHistory,
                  icon: const Icon(Icons.history),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const HeroPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
