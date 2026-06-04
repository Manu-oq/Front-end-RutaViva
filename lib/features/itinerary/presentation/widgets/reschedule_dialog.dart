import 'package:flutter/material.dart';

class RescheduleResult {
  final TimeOfDay time;

  const RescheduleResult({required this.time});
}

class RescheduleDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final TextEditingController durationController;

  const RescheduleDialog({
    super.key,
    required this.initialTime,
    required this.durationController,
  });

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cambiar horario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.access_time_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text('${_time.format(context)} hs'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: const Text('Cambiar'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duracion (minutos, opcional)',
                hintText: 'Ej: 60',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(RescheduleResult(time: _time)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
