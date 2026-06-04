import '../../features/itinerary/data/models/itinerary_model.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String weekdayName(DateTime date) {
  const names = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  return names[date.weekday - 1];
}

String shortWeekdayName(DateTime date) {
  const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return names[date.weekday - 1];
}

String shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

DateTime? stepDay(ItineraryStepModel step) {
  final explicitDay = step.dayDate;
  if (explicitDay != null) {
    return dateOnly(explicitDay);
  }
  final arrival = step.arrivalTime;
  if (arrival != null) {
    return dateOnly(arrival);
  }
  return null;
}

String dateRangeLabel(ItineraryModel itinerary) {
  if (itinerary.startDate == null || itinerary.endDate == null) {
    return 'ITINERARIO';
  }
  return '${shortDate(itinerary.startDate!)} — ${shortDate(itinerary.endDate!)}';
}

String? backendDayLabel(DateTime date, List<ItineraryStepModel> steps) {
  for (final step in steps) {
    final label = step.dayLabel?.trim();
    if (label == null || label.isEmpty) continue;
    final sDay = stepDay(step);
    if (sDay != null && isSameDay(sDay, date)) {
      return label;
    }
  }
  return null;
}

String fullDayLabel(DateTime date, List<ItineraryStepModel> steps) {
  final backendLabel = backendDayLabel(date, steps);
  if (backendLabel != null) {
    return backendLabel;
  }
  return '${weekdayName(date)} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

String dayChipLabel(DateTime date, List<ItineraryStepModel> steps) {
  final backendLabel = backendDayLabel(date, steps);
  if (backendLabel != null) {
    return backendLabel;
  }
  return '${shortWeekdayName(date)} ${date.day}';
}
