import 'package:flutter/material.dart';
import '../../../itinerary/data/models/itinerary_model.dart';
import '../providers/chat_provider.dart';

class ItineraryProgressSheet extends StatefulWidget {
  final TripProgressData? progress;
  final ItineraryModel? itinerary;

  const ItineraryProgressSheet({
    super.key,
    required this.progress,
    required this.itinerary,
  });

  static Future<void> show(
    BuildContext context, {
    required TripProgressData? progress,
    required ItineraryModel? itinerary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          ItineraryProgressSheet(progress: progress, itinerary: itinerary),
    );
  }

  @override
  State<ItineraryProgressSheet> createState() => _ItineraryProgressSheetState();
}

class _ItineraryProgressSheetState extends State<ItineraryProgressSheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final days = _days;
    final focusIndex = days.indexWhere((day) => day.isFocus);
    _selectedIndex = focusIndex >= 0 ? focusIndex : 0;
  }

  List<DayProgressData> get _days {
    final progressDays = widget.progress?.days ?? const <DayProgressData>[];
    if (progressDays.isNotEmpty) return progressDays;

    final itinerary = widget.itinerary;
    if (itinerary == null) return const [];

    final indexes =
        itinerary.steps.map((step) => step.dayIndex ?? 0).toSet().toList()
          ..sort();

    if (indexes.isEmpty) {
      return const [
        DayProgressData(
          label: 'Día 1',
          date: '',
          dayIndex: 0,
          status: 'pending',
          isFocus: true,
          steps: 0,
        ),
      ];
    }

    return [
      for (final entry in indexes.indexed)
        DayProgressData(
          label: 'Día ${entry.$1 + 1}',
          date: '',
          dayIndex: entry.$2,
          status: 'completed',
          isFocus: entry.$1 == 0,
          steps: itinerary.steps
              .where((step) => (step.dayIndex ?? 0) == entry.$2)
              .length,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _days;

    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_outlined,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay progreso visible',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando Ara empiece a completar días y slots, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final safeIndex = _selectedIndex.clamp(0, days.length - 1);
    final selectedDay = days[safeIndex];
    final visualSlots = _visualSlotsFor(selectedDay);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Itinerario en construcción',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vista solo de lectura del progreso que Ara va armando.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if ((widget.progress?.lodgingName ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _LodgingSummary(
                name: widget.progress!.lodgingName!,
                plan: widget.progress!.lodgingPlan,
              ),
            ],
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in days.indexed) ...[
                    if (entry.$1 > 0) const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(_dayPillLabel(entry.$2)),
                      selected: safeIndex == entry.$1,
                      onSelected: (_) => setState(() {
                        _selectedIndex = entry.$1;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _dayTitle(selectedDay),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (visualSlots.isEmpty)
              _PendingCard(day: selectedDay)
            else
              for (final entry in visualSlots.indexed)
                _SlotTile(
                  slot: entry.$2,
                  isLast: entry.$1 == visualSlots.length - 1,
                ),
          ],
        );
      },
    );
  }

  List<_VisualSlot> _visualSlotsFor(DayProgressData day) {
    final itinerarySlots = _itinerarySlotsFor(day);
    if (itinerarySlots.isNotEmpty) return itinerarySlots;

    if (day.slots.isNotEmpty) {
      return day.slots
          .map(
            (slot) => _VisualSlot(
              title: _slotTitle(slot),
              time: _formatRawTimeRange(slot.startTime, slot.endTime),
              isPending:
                  slot.status.toLowerCase() != 'filled' || slot.isGeneric,
              isMeal: _isMealSlot(slot),
              isGeneric: slot.isGeneric,
            ),
          )
          .toList(growable: false);
    }

    if (day.steps > 0) {
      return [
        for (var i = 0; i < day.steps; i++)
          _VisualSlot(
            title: 'Slot ${i + 1}',
            time: 'Pendiente',
            isPending: true,
          ),
      ];
    }

    return const [];
  }

  List<_VisualSlot> _itinerarySlotsFor(DayProgressData day) {
    final itinerary = widget.itinerary;
    if (itinerary == null || itinerary.steps.isEmpty) return const [];

    final daySteps = itinerary.steps.where((step) {
      final stepDayIndex = step.dayIndex;
      if (stepDayIndex == null) return day.dayIndex == 0;
      return stepDayIndex == day.dayIndex;
    }).toList()..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return daySteps
        .map(
          (step) => _VisualSlot(
            title: step.title,
            time: _formatStepTime(step),
            isPending: step.arrivalTime == null || step.isGeneric,
            isMeal: step.isGenericMeal,
            isGeneric: step.isGeneric,
          ),
        )
        .toList(growable: false);
  }

  String _slotTitle(DayProgressSlotData slot) {
    final title = slot.title.trim().isEmpty ? 'Pendiente' : slot.title.trim();
    final mealPrefix = _isMealSlot(slot) ? '🍽️ ' : '';
    final undefinedSuffix =
        slot.isGeneric && !title.toLowerCase().contains('sin definir')
        ? ' (sin definir)'
        : '';
    return '$mealPrefix$title$undefinedSuffix';
  }

  bool _isMealSlot(DayProgressSlotData slot) {
    final slotType = slot.slotType?.trim().toLowerCase();
    if (slotType != null && slotType.isNotEmpty) {
      return slotType == 'meal';
    }
    final title = slot.title.toLowerCase();
    return title.contains('desayuno') ||
        title.contains('almuerzo') ||
        title.contains('cena') ||
        title.contains('once');
  }

  String _dayPillLabel(DayProgressData day) {
    final parsed = DateTime.tryParse(day.date);
    if (parsed == null) return day.label.trim().isEmpty ? 'Día' : day.label;
    return const [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ][parsed.weekday - 1];
  }

  String _dayTitle(DayProgressData day) {
    final date = DateTime.tryParse(day.date);
    final label = day.label.trim().isEmpty ? 'Día' : day.label.trim();
    if (date == null) return label;
    return '$label · ${_dayPillLabel(day)} ${date.day}/${date.month}';
  }

  String _formatStepTime(ItineraryStepModel step) {
    return _formatRawTimeRange(
      _timeOfDay(step.arrivalTime),
      _timeOfDay(step.departureTime),
    );
  }

  String _formatRawTimeRange(String? start, String? end) {
    final cleanStart = _normalizeTime(start);
    final cleanEnd = _normalizeTime(end);
    if (cleanStart == null && cleanEnd == null) return 'Pendiente';
    if (cleanStart != null && cleanEnd != null) return '$cleanStart–$cleanEnd';
    return cleanStart ?? cleanEnd ?? 'Pendiente';
  }

  String? _timeOfDay(DateTime? date) {
    if (date == null) return null;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String? _normalizeTime(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return _timeOfDay(parsed);
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return value;
    return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!}';
  }
}

class _VisualSlot {
  final String title;
  final String time;
  final bool isPending;
  final bool isMeal;
  final bool isGeneric;

  const _VisualSlot({
    required this.title,
    required this.time,
    required this.isPending,
    this.isMeal = false,
    this.isGeneric = false,
  });
}

class _SlotTile extends StatelessWidget {
  final _VisualSlot slot;
  final bool isLast;

  const _SlotTile({required this.slot, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = slot.isPending
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final displayTitle = slot.isMeal && !slot.title.startsWith('🍽️')
        ? '🍽️ ${slot.title}'
        : slot.title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              slot.isPending
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.check_circle_rounded,
              color: statusColor,
              size: 20,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 46,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.isPending ? 'Falta completar' : slot.time,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(displayTitle, style: theme.textTheme.bodyLarge),
                    if (slot.isPending && slot.time != 'Pendiente') ...[
                      const SizedBox(height: 2),
                      Text(
                        slot.time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  final DayProgressData day;

  const _PendingCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        'Pendiente: Ara todavía no completa slots para este día.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LodgingSummary extends StatelessWidget {
  final String name;
  final String? plan;

  const _LodgingSummary({required this.name, this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanPlan = plan?.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.hotel_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cleanPlan == null || cleanPlan.isEmpty
                  ? name
                  : '$name · $cleanPlan',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
