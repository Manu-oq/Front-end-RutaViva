import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/global_loading_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const RutaVivaApp(),
    ),
  );
}

class RutaVivaApp extends ConsumerWidget {
  const RutaVivaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      builder: (context, child) => Stack(
        children: [
          child!,
          const GlobalLoadingOverlay(),
        ],
      ),
      title: 'Ruta Viva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
