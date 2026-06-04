import 'package:flutter/material.dart';

class DaySelector extends StatefulWidget {
  final List<DateTime> days;
  final List<String> labels;

  const DaySelector({super.key, required this.days, required this.labels});

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final safeIndex = days.isEmpty
        ? 0
        : _selectedIndex.clamp(0, days.length - 1);
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14);
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrap = constraints.maxWidth >= 520 || textScale > 18;
        final chips = List<Widget>.generate(days.length, (index) {
          final selected = index == safeIndex;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => setState(() => _selectedIndex = index),
            label: Text(
              widget.labels[index],
              maxLines: useWrap ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            avatar: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
          );
        });

        if (useWrap) {
          return Wrap(spacing: 8, runSpacing: 8, children: chips);
        }

        final chipHeight = textScale.clamp(54.0, 72.0).toDouble();
        return SizedBox(
          height: chipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) => chips[index],
          ),
        );
      },
    );
  }
}
