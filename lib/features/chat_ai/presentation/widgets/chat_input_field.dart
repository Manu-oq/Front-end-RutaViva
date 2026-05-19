import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/chat_provider.dart';

class ChatInputField extends ConsumerStatefulWidget {
  const ChatInputField({super.key});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  late final TextEditingController _controller;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    final today = DateTime.now();
    _startDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(const Duration(days: 1));
    _endDate = _startDate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier = ref.read(chatProvider.notifier);
    final created = await notifier.sendMessage(
      text,
      startDate: notifier.hasActiveSession ? null : _startDate,
      endDate: notifier.hasActiveSession ? null : _endDate,
    );
    _controller.clear();

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (!created) {
      return;
    }
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Fechas del viaje',
      saveText: 'Usar fechas',
    );
    if (picked == null) return;
    final days = picked.end.difference(picked.start).inDays + 1;
    if (days > 7) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El viaje puede tener máximo 7 días.')),
      );
      return;
    }
    setState(() {
      _startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(chatProvider);
    final chatUiState = ref.watch(chatUiStateProvider);

    final notifier = ref.read(chatProvider.notifier);
    final hasActiveSession = notifier.hasActiveSession;
    final inputLocked =
        _isSubmitting ||
        chatUiState == AraChatUiState.sendingMessage ||
        chatUiState == AraChatUiState.araTyping ||
        chatUiState == AraChatUiState.generatingItinerary ||
        chatUiState == AraChatUiState.pollingGeneration;
    final displayStart = hasActiveSession
        ? notifier.sessionStartDate ?? _startDate
        : _startDate;
    final displayEnd = hasActiveSession
        ? notifier.sessionEndDate ?? _endDate
        : _endDate;

    return GlassContainer(
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !inputLocked,
                    minLines: 1,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu deseo...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: inputLocked ? null : _submitMessage,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: inputLocked
                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                          : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: inputLocked
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Futura integración con notas de voz',
                  onPressed: inputLocked
                      ? null
                      : () =>
                            debugPrint('Futura integración con OpenAI Whisper'),
                  icon: Icon(
                    Icons.mic_none_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                hasActiveSession
                    ? Chip(
                        avatar: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(_dateRangeLabel(displayStart, displayEnd)),
                        visualDensity: VisualDensity.compact,
                      )
                    : ActionChip(
                        avatar: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(_dateRangeLabel(displayStart, displayEnd)),
                        visualDensity: VisualDensity.compact,
                        onPressed: inputLocked ? null : _pickDates,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateRangeLabel(DateTime start, DateTime end) {
    final startLabel = _shortDate(start);
    final endLabel = _shortDate(end);
    return startLabel == endLabel ? startLabel : '$startLabel — $endLabel';
  }

  String _shortDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}
