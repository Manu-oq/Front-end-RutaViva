import 'package:flutter/material.dart';

import '../../data/models/itinerary_model.dart';

class DragFlyingProxy extends StatefulWidget {
  final ItineraryStepModel step;

  const DragFlyingProxy({super.key, required this.step});

  @override
  State<DragFlyingProxy> createState() => _DragFlyingProxyState();
}

class _DragFlyingProxyState extends State<DragFlyingProxy> {
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _scale = 0.85);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      child: Material(
        elevation: 18,
        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.30),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minWidth: 280),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.58),
                width: 1.6,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.step.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (widget.step.poiName?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.step.poiName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
