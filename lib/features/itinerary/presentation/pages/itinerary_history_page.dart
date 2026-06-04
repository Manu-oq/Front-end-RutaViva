import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';

class ItineraryHistoryPage extends ConsumerWidget {
  const ItineraryHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itineraries = ref.watch(itineraryHistoryProvider);
    final isMobile = AppResponsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRouteName: AppRouteNames.home),
        title: const Text('Mis itinerarios'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceContainerLow,
              theme.colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: itineraries.when(
          data: (items) {
            if (items.isEmpty) {
              return _EmptyItineraryHistory(
                onCreate: () => context.goNamed(AppRouteNames.home),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppResponsive.maxContentWidth(context),
                ),
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(itineraryHistoryProvider),
                  child: ListView.separated(
                  padding: AppResponsive.value<EdgeInsets>(
                    context,
                    mobile: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    tablet: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                    desktop: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  ),
                  itemBuilder: (context, index) {
                    final itinerary = items[index];
                    return _ItineraryCard(
                      itinerary: itinerary,
                      onDelete: () => _deleteItinerary(context, ref, itinerary),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemCount: items.length,
                ),
              ),
              ),
            );
          },
          loading: () => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: ListView.separated(
                padding: AppResponsive.value<EdgeInsets>(
                  context,
                  mobile: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  tablet: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                  desktop: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                ),
                itemBuilder: (context, index) => SkeletonContainer(
                  height: isMobile ? 128 : 142,
                  borderRadius: const BorderRadius.all(Radius.circular(26)),
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemCount: 4,
              ),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth(context),
              ),
              child: Padding(
                padding: AppResponsive.pagePadding(context),
                child: InlineErrorWidget(
                  message:
                      'No se pudo cargar el historial. Intenta nuevamente.',
                  onRetry: () => ref.invalidate(itineraryHistoryProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItinerary(
    BuildContext context,
    WidgetRef ref,
    ItineraryModel itinerary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar itinerario'),
        content: Text(
          '¿Quieres eliminar "${itinerary.title}"? Esta ruta dejará de aparecer en tu historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(itineraryRepositoryProvider).deleteItinerary(itinerary.id);
      ref.read(itineraryProvider.notifier).clearCurrentIfMatches(itinerary.id);
      ref.invalidate(itineraryHistoryProvider);
      ref.invalidate(itineraryDetailProvider(itinerary.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Itinerario eliminado.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException && error.statusCode == 409
                ? 'No pudimos eliminar este itinerario porque el servidor lo marcó como no editable.'
                : 'No pudimos eliminar el itinerario.',
          ),
        ),
      );
      if (error is ApiException && error.statusCode == 409) {
        ref.invalidate(itineraryHistoryProvider);
        ref.invalidate(itineraryDetailProvider(itinerary.id));
      }
    }
  }
}

class _ItineraryCard extends StatelessWidget {
  final ItineraryModel itinerary;
  final VoidCallback onDelete;

  const _ItineraryCard({required this.itinerary, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.ambientShadow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.pushNamedSafe(
          AppRouteNames.itineraryDetail,
          pathParameters: {'id': itinerary.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: const Icon(Icons.route, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_dateRange(itinerary)} • ${itinerary.steps.length} paradas',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!itinerary.isEditable) ...[
                        _ReadOnlyChip(isPast: itinerary.isPast),
                        const SizedBox(width: 6),
                      ],
                      PopupMenuButton<String>(
                        tooltip: 'Opciones de itinerario',
                        onSelected: (value) {
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded),
                                SizedBox(width: 8),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (itinerary.steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: itinerary.steps.take(4).map((step) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.42,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        step.poiName ?? 'Parada ${step.stepOrder}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange(ItineraryModel itinerary) {
    final start = itinerary.startDate;
    final end = itinerary.endDate;
    if (start == null || end == null) {
      return 'Sin fechas';
    }
    return '${_shortDate(start)} — ${_shortDate(end)}';
  }

  String _shortDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _ReadOnlyChip extends StatelessWidget {
  final bool isPast;

  const _ReadOnlyChip({required this.isPast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        isPast ? Icons.history_rounded : Icons.visibility_outlined,
        size: 16,
      ),
      label: Text(isPast ? 'Pasado' : 'Solo lectura'),
      visualDensity: VisualDensity.compact,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}

class _EmptyItineraryHistory extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyItineraryHistory({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppResponsive.maxContentWidth(context),
        ),
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: _HistoryStateCard(
            icon: Icons.route_outlined,
            title: 'Aún no tienes itinerarios guardados',
            text:
                'Genera una ruta desde Inicio o Ara Assistant y aparecerá aquí.',
            action: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar una ruta'),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Widget action;

  const _HistoryStateCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.primary,
            child: Icon(icon),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: isMobile
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: isMobile
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }
}
