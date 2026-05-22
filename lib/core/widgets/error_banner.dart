import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: error.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: error,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Cerrar mensaje',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: error, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
