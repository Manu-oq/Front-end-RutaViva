import 'package:flutter/material.dart';

class AccessTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const AccessTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Tipo de acceso',
        prefixIcon: Icon(Icons.door_front_door_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'public', child: Text('Público')),
        DropdownMenuItem(value: 'private', child: Text('Privado')),
        DropdownMenuItem(value: 'reservation', child: Text('Con reserva')),
        DropdownMenuItem(value: 'paid', child: Text('Pagado')),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
