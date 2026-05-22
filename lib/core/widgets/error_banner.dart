import 'package:flutter/material.dart';

import 'app_feedback.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final AppFeedbackType type;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.type = AppFeedbackType.error,
  });

  @override
  Widget build(BuildContext context) {
    return AppFeedbackBanner(
      message: message,
      type: type,
      onDismiss: onDismiss,
    );
  }
}
