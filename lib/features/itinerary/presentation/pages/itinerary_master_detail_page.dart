import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../data/models/itinerary_model.dart';
import '../../data/repositories/itinerary_repository.dart';
import '../providers/itinerary_provider.dart';
import 'itinerary_detail_page.dart';
import 'itinerary_history_page.dart';

class ItineraryMasterDetailPage extends ConsumerStatefulWidget {
  const ItineraryMasterDetailPage({super.key});

  @override
  ConsumerState<ItineraryMasterDetailPage> createState() =>
      _ItineraryMasterDetailPageState();
}

class _ItineraryMasterDetailPageState
    extends ConsumerState<ItineraryMasterDetailPage> {
  String? _selectedItineraryId;

  @override
  Widget build(BuildContext context) {
    if (AppResponsive.isMobile(context) && !AppResponsive.isLandscape(context)) {
      return const ItineraryHistoryPage();
    }

    ref.listen<ItineraryState>(itineraryProvider, (previous, next) {
      final nextId = next.current?.id;
      if (nextId == null || nextId == previous?.current?.id) return;
      setState(() => _selectedItineraryId = nextId);
    });

    final history = ref.watch(itineraryHistoryProvider);
    final currentId = ref.watch(itineraryProvider).current?.id;
    final theme = Theme.of(context);

    return history.when(
      data: (items) {
        final selectedId = _effectiveSelectedId(items, currentId);
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: Material(
                  color: theme.colorScheme.surface,
                  child: ItineraryHistoryPage(
                    embedded: true,
                    selectedItineraryId: selectedId,
                    onItinerarySelected: (itinerary) =>
                        setState(() => _selectedItineraryId = itinerary.id),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: selectedId == null
                  ? const _NoItinerarySelectedPane()
                  : ItineraryDetailPage(
                      key: ValueKey('itinerary-detail-$selectedId'),
                      itineraryId: selectedId,
                    ),
            ),
          ],
        );
      },
      loading: () => const Row(
        children: [
          Expanded(flex: 2, child: ItineraryHistoryPage(embedded: true)),
          Expanded(flex: 3, child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: InlineErrorWidget(
            message: 'No se pudo cargar el historial de itinerarios.',
            onRetry: () => ref.invalidate(itineraryHistoryProvider),
          ),
        ),
      ),
    );
  }

  String? _effectiveSelectedId(List<ItineraryModel> items, String? currentId) {
    if (items.isEmpty) return null;
    final selectedId = _selectedItineraryId;
    if (selectedId != null && items.any((item) => item.id == selectedId)) {
      return selectedId;
    }
    if (currentId != null && items.any((item) => item.id == currentId)) {
      return currentId;
    }
    return items.first.id;
  }
}

class _NoItinerarySelectedPane extends StatelessWidget {
  const _NoItinerarySelectedPane();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                size: 56,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Selecciona un itinerario para ver el detalle.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
