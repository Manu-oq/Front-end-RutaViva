import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalLoadingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() {
    if (state > 0) state--;
  }
}

final globalLoadingProvider = NotifierProvider<GlobalLoadingNotifier, int>(
  GlobalLoadingNotifier.new,
);

class GlobalLoadingOverlay extends ConsumerWidget {
  const GlobalLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(globalLoadingProvider);

    if (count == 0) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
