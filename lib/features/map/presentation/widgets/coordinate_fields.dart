import 'package:flutter/material.dart';

class CoordinateFields extends StatelessWidget {
  final TextEditingController latController;
  final TextEditingController lonController;
  final String? Function(String?) validator;
  final VoidCallback onPick;

  const CoordinateFields({
    super.key,
    required this.latController,
    required this.lonController,
    required this.validator,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_pin, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${latController.text}, ${lonController.text}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onPick,
                icon: const Icon(Icons.map_rounded),
                label: const Text('Elegir en mapa'),
              ),
            ],
          ),
        ),
        Offstage(
          child: Column(
            children: [
              TextFormField(
                key: const ValueKey('coordinate_lat_field'),
                controller: latController,
                validator: validator,
              ),
              TextFormField(
                key: const ValueKey('coordinate_lon_field'),
                controller: lonController,
                validator: validator,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
