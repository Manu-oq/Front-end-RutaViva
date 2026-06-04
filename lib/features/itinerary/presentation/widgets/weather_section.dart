import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../weather/data/models/weather_forecast_model.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';

class WeatherSection extends StatefulWidget {
  final ItineraryModel itinerary;

  const WeatherSection({super.key, required this.itinerary});

  @override
  State<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<WeatherSection> {
  bool _showWeather = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeatherToggle(
          isOpen: _showWeather,
          onTap: () => setState(() => _showWeather = !_showWeather),
        ),
        if (_showWeather) ...[
          const SizedBox(height: 12),
          WeatherDashboard(itinerary: widget.itinerary),
        ],
      ],
    );
  }
}

class WeatherToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const WeatherToggle({super.key, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(isOpen ? Icons.expand_less_rounded : Icons.cloud_outlined),
      label: Text(isOpen ? 'Ocultar clima' : 'Revisar clima'),
    );
  }
}

class WeatherDashboard extends ConsumerWidget {
  final ItineraryModel itinerary;

  const WeatherDashboard({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isWeatherNotApplicable =
        itinerary.isPast ||
        itinerary.status == 'completed' ||
        itinerary.status == 'cancelled';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clima del viaje',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pronóstico diario actualizado, entregado por Ruta Viva.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (isWeatherNotApplicable)
            const WeatherStatusMessage(
              icon: Icons.history_rounded,
              message:
                  'El clima ya no se consulta para itinerarios finalizados o pasados.',
            )
          else
            ref
                .watch(itineraryWeatherProvider(itinerary.id))
                .when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const WeatherStatusMessage(
                        icon: Icons.cloud_off_outlined,
                        message: 'No se pudo cargar el clima en este momento.',
                      );
                    }
                    return AdaptiveItineraryWeatherCards(items: items);
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 3),
                  error: (error, stackTrace) => const WeatherStatusMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'No se pudo cargar el clima en este momento.',
                  ),
                ),
        ],
      ),
    );
  }
}

class AdaptiveItineraryWeatherCards extends StatelessWidget {
  final List<WeatherForecastDay> items;

  const AdaptiveItineraryWeatherCards({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardWidth = columns == 1
            ? availableWidth
            : (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: DayWeatherCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class DayWeatherCard extends StatelessWidget {
  final WeatherForecastDay item;

  const DayWeatherCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = item.summary != null || item.maxTempC != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasData
            ? theme.colorScheme.primary.withValues(alpha: 0.07)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasData
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _weatherIcon(item.summary ?? ''),
                color: hasData
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dayLabel(item),
                  style: theme.textTheme.labelLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasData) ...[
            if (item.summary != null && item.summary!.isNotEmpty)
              Text(
                item.summary!,
                style: theme.textTheme.bodyMedium,
              ),
            if (item.summary != null && item.summary!.isNotEmpty)
              const SizedBox(height: 4),
            Text(
              _temperatureLine(item),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else
            Text(
              'Datos del clima no disponibles',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }

  static String _dayLabel(WeatherForecastDay item) {
    if (item.label != null && item.label!.isNotEmpty) return item.label!;
    final day = item.date.day.toString().padLeft(2, '0');
    final month = item.date.month.toString().padLeft(2, '0');
    return '$day/$month/${item.date.year}';
  }

  static String _temperatureLine(WeatherForecastDay item) {
    final parts = <String>[];
    if (item.maxTempC != null) {
      if (item.minTempC != null) {
        parts.add('${item.minTempC!.round()}° – ${item.maxTempC!.round()}°C');
      } else {
        parts.add('${item.maxTempC!.round()}°C máx');
      }
    } else if (item.minTempC != null) {
      parts.add('${item.minTempC!.round()}°C mín');
    }
    if (item.precipitationProbability != null) {
      parts.add('${item.precipitationProbability}% precipitaciones');
    } else if (item.precipitationMm != null) {
      parts.add('${item.precipitationMm!.toStringAsFixed(1)} mm');
    }
    return parts.join(' • ');
  }

  static IconData _weatherIcon(String summary) {
    final lower = summary.toLowerCase();
    if (lower.contains('lluvia') || lower.contains('rain')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('nube') || lower.contains('cloud')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('sol') ||
        lower.contains('sun') ||
        lower.contains('clear')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.wb_cloudy_outlined;
  }
}

class WeatherStatusMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const WeatherStatusMessage({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
