enum StepType { activity, insight, spotlight, ritual }

class ItineraryStep {
  final String time;
  final String title;
  final String description;
  final String? imageUrl;
  final String? quote;
  final StepType type;

  ItineraryStep({
    required this.time,
    required this.title,
    required this.description,
    this.imageUrl,
    this.quote,
    required this.type,
  });
}
