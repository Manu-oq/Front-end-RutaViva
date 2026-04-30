import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/interests_provider.dart';
import 'interest_tag.dart';

class InterestsSelector extends ConsumerWidget {
  const InterestsSelector({super.key});

  static const List<String> availableInterests = [
    "ComidaMapuche",
    "Senderismo",
    "Fotografía",
    "Artesanía",
    "Aves",
    "Termas",
    "Nieve",
    "Historia",
    "Ríos",
    "Silencio",
    "Aventura",
    "CulturaViva",
    "BosqueNativo",
    "ObservaciónDeEstrellas",
    "GastronomíaLocal",
    "Relajación",
    "VidaSilvestre",
    "Paisajes",
    "Cascadas",
    "PueblosOriginarios",
    "YogaAlAireLibre",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInterests = ref.watch(interestsProvider);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableInterests.map((interest) {
        final isSelected = selectedInterests.contains(interest);
        return InterestTag(
          label: interest,
          isSelected: isSelected,
          onTap: () =>
              ref.read(interestsProvider.notifier).toggleInterest(interest),
        );
      }).toList(),
    );
  }
}
