import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_durations.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/chat_provider.dart';

class IntentCheckpointCard extends ConsumerStatefulWidget {
  const IntentCheckpointCard({super.key});

  @override
  ConsumerState<IntentCheckpointCard> createState() =>
      _IntentCheckpointCardState();
}

class _IntentCheckpointCardState extends ConsumerState<IntentCheckpointCard> {
  bool _isEditing = false;
  bool _isSaving = false;
  late final TextEditingController _destinationController;
  late final TextEditingController _interestsController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController();
    _interestsController = TextEditingController();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkpoint = ref.watch(chatIntentCheckpointProvider);
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);

    if (checkpoint == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 20,
        0,
        isMobile ? 14 : 20,
        12,
      ),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: _isEditing
            ? _IntentCheckpointEditor(
                destinationController: _destinationController,
                interestsController: _interestsController,
                isSaving: _isSaving,
                error: _error,
                onCancel: _isSaving
                    ? null
                    : () => setState(() => _isEditing = false),
                onSave: _isSaving ? null : () => _save(checkpoint),
              )
            : _IntentCheckpointSummary(
                checkpoint: checkpoint,
                onEdit: () => _startEditing(checkpoint),
              ),
      ),
    );
  }

  void _startEditing(IntentCheckpointData checkpoint) {
    _destinationController.text = checkpoint.destination;
    _interestsController.text = checkpoint.interests.join(', ');
    setState(() {
      _error = null;
      _isEditing = true;
    });
  }

  Future<void> _save(IntentCheckpointData checkpoint) async {
    final destination = _destinationController.text.trim();
    final interests = _interestsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(10)
        .toList(growable: false);

    if (destination.isEmpty) {
      setState(() {
        _error = 'Indica un destino para actualizar lo que Ara entendió.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final updated = checkpoint.copyWith(
      destination: destination,
      startDate: checkpoint.startDate,
      endDate: checkpoint.endDate,
      pace: checkpoint.pace,
      interests: interests,
    );
    final ok = await ref
        .read(chatProvider.notifier)
        .updateIntentCheckpoint(updated);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = !ok;
      _error = ok ? null : 'No pude actualizar lo que Ara entendió.';
    });
  }
}

class _IntentCheckpointSummary extends StatelessWidget {
  final IntentCheckpointData checkpoint;
  final VoidCallback onEdit;

  const _IntentCheckpointSummary({
    required this.checkpoint,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fact_check_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esto entendió Ara',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(icon: Icons.place_rounded, label: checkpoint.destination),
            if (checkpoint.interests.isNotEmpty)
              _InfoChip(
                icon: Icons.interests_rounded,
                label: checkpoint.interests.join(', '),
              ),
          ],
        ),
      ],
    );
  }
}

class _IntentCheckpointEditor extends StatelessWidget {
  final TextEditingController destinationController;
  final TextEditingController interestsController;
  final bool isSaving;
  final String? error;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  const _IntentCheckpointEditor({
    required this.destinationController,
    required this.interestsController,
    required this.isSaving,
    required this.error,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajustar lo que Ara entendió',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: destinationController,
          enabled: !isSaving,
          decoration: const InputDecoration(labelText: 'Destino'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: interestsController,
          enabled: !isSaving,
          decoration: const InputDecoration(
            labelText: 'Intereses',
            helperText: 'Separados por coma, máximo 10.',
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: onCancel, child: const Text('Cancelar')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = label.trim().isEmpty ? 'Pendiente' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
