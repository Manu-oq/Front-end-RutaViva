import 'package:flutter/material.dart';

class AccessTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  static const _allowedValues = {'public', 'restricted', 'private'};

  const AccessTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = _allowedValues.contains(value) ? value : 'public';

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: const InputDecoration(
        labelText: 'Tipo de acceso',
        prefixIcon: Icon(Icons.door_front_door_outlined),
      ),
      items: const [
        DropdownMenuItem(
          value: 'public',
          child: Text('Público — acceso libre'),
        ),
        DropdownMenuItem(
          value: 'restricted',
          child: Text('Restringido — requiere permiso o pago'),
        ),
        DropdownMenuItem(
          value: 'private',
          child: Text('Privado — acceso privado'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
