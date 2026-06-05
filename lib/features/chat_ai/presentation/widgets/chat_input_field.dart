import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
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
  String? _feedbackMessage;

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
      startDate: notifier.hasActiveSession
          ? notifier.sessionStartDate
          : _startDate,
      endDate: notifier.hasActiveSession ? notifier.sessionEndDate : _endDate,
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
    final result = await showDialog<_DatePickResult>(
      context: context,
      builder: (ctx) =>
          _DatePickDialog(initialStart: _startDate, initialEnd: _endDate),
    );
    if (result == null) return;
    await _applyDateRange(result.start, result.end);
  }

  Future<void> _applyDateRange(DateTime start, DateTime end) async {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    final days = endDate.difference(startDate).inDays + 1;
    if (days > 7) {
      setState(() {
        _feedbackMessage = 'El viaje puede tener máximo 7 días.';
      });
      return;
    }
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _feedbackMessage = null;
    });

    final notifier = ref.read(chatProvider.notifier);
    if (!notifier.hasActiveSession) {
      return;
    }

    setState(() => _isSubmitting = true);
    await notifier.sendMessage(
      'Voy a ir del ${_shortDate(startDate)} al ${_shortDate(endDate)}',
      startDate: startDate,
      endDate: endDate,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);
    ref.watch(chatProvider);
    final notifier = ref.read(chatProvider.notifier);
    final chatUiState = notifier.uiState;
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
    final canPickDates =
        !hasActiveSession ||
        notifier.sessionStartDate == null ||
        notifier.sessionEndDate == null;

    return GlassContainer(
      borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 14,
          12,
          isMobile ? 12 : 14,
          10,
        ),
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
                      hintText:
                          '¿Qué quieres hacer? Dime tu destino y preferencias',
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
                    width: 48,
                    height: 48,
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
                !canPickDates
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
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 10),
              AppFeedbackBanner(
                message: _feedbackMessage!,
                type: AppFeedbackType.warning,
                compact: true,
                onDismiss: () => setState(() => _feedbackMessage = null),
              ),
            ],
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

class _DatePickResult {
  final DateTime start;
  final DateTime end;

  const _DatePickResult({required this.start, required this.end});
}

class _DatePickDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;

  const _DatePickDialog({required this.initialStart, required this.initialEnd});

  @override
  State<_DatePickDialog> createState() => _DatePickDialogState();
}

class _DatePickDialogState extends State<_DatePickDialog> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  void _addDays(int days) {
    setState(() {
      if (days > 0) {
        _end = _start.add(Duration(days: days));
      } else {
        _start = DateTime.now().add(const Duration(days: 1));
        _end = _start;
      }
    });
  }

  void _selectWeekend() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var friday = today;
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }
    final sunday = friday.add(const Duration(days: 2));
    setState(() {
      _start = friday.isBefore(today)
          ? today.add(const Duration(days: 1))
          : friday;
      _end = sunday;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayCount = _end.difference(_start).inDays;

    return AlertDialog(
      title: const Text('Fechas del viaje'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatRange(_start, _end),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayCount == 0 ? '1 día' : '${dayCount + 1} días',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.today_rounded, size: 18),
                  label: const Text('Mañana'),
                  onPressed: () {
                    final t = DateTime.now().add(const Duration(days: 1));
                    setState(() {
                      _start = DateTime(t.year, t.month, t.day);
                      _end = _start;
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(
                    Icons.calendar_view_week_rounded,
                    size: 18,
                  ),
                  label: const Text('Finde'),
                  onPressed: _selectWeekend,
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('7 días'),
                  onPressed: () => _addDays(6),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: DateTimeRange(start: _start, end: _end),
                  helpText: 'Fechas del viaje',
                  saveText: 'Usar fechas',
                );
                if (picked == null) return;
                setState(() {
                  _start = DateTime(
                    picked.start.year,
                    picked.start.month,
                    picked.start.day,
                  );
                  _end = DateTime(
                    picked.end.year,
                    picked.end.month,
                    picked.end.day,
                  );
                });
              },
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Abrir calendario'),
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
          onPressed: () => Navigator.of(
            context,
          ).pop(_DatePickResult(start: _start, end: _end)),
          child: const Text('Usar fechas'),
        ),
      ],
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    return _short(start) == _short(end)
        ? _short(start)
        : '${_short(start)} — ${_short(end)}';
  }

  String _short(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}
