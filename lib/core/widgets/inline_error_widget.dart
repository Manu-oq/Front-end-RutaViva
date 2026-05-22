import 'package:flutter/material.dart';

import 'app_feedback.dart';

class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppFeedbackType type;

  const InlineErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.type = AppFeedbackType.error,
  });

  @override
  Widget build(BuildContext context) {
    return AppFeedbackBanner(
      message: message,
      type: type,
      actionLabel: 'Reintentar',
      onAction: onRetry,
      compact: true,
    );
  }
}
