import 'package:flutter/material.dart';
import '../utils/app_durations.dart';
import '../utils/responsive.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({super.key, required this.child, this.onError});

  @override
  Widget build(BuildContext context) {
    return _ErrorBoundaryBody(onError: onError, child: child);
  }
}

class _ErrorBoundaryBody extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? onError;

  const _ErrorBoundaryBody({required this.child, this.onError});

  @override
  State<_ErrorBoundaryBody> createState() => _ErrorBoundaryBodyState();
}

class _ErrorBoundaryBodyState extends State<_ErrorBoundaryBody> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      if (mounted) {
        setState(() => _error = details);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _CriticalErrorPage(onRetry: () => setState(() => _error = null));
    }
    return widget.child;
  }
}

class _CriticalErrorPage extends StatelessWidget {
  final VoidCallback onRetry;

  const _CriticalErrorPage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth(context),
            ),
            child: Padding(
              padding: AppResponsive.pagePadding(context),
              child: AnimatedSwitcher(
                duration: AppDurations.medium,
                child: Column(
                  key: const ValueKey('critical_error'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Algo salió mal',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ocurrió un problema inesperado en la aplicación. Intentá reiniciar.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
