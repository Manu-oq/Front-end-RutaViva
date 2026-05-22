import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../providers/interests_provider.dart';
import '../widgets/interests_selector.dart';
import '../widgets/vibe_card.dart';

class VibeSelectionPage extends ConsumerStatefulWidget {
  const VibeSelectionPage({super.key});

  @override
  ConsumerState<VibeSelectionPage> createState() => _VibeSelectionPageState();
}

class _VibeSelectionPageState extends ConsumerState<VibeSelectionPage> {
  bool _isSearching = false;
  String? _selectedVibeQuery;
  String? _errorMessage;

  Future<void> _searchAndOpenMap(String query) async {
    if (_isSearching) {
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedVibeQuery = query;
      _errorMessage = null;
    });

    await ref.read(mapProvider.notifier).semanticSearch(query: query);

    if (!mounted) {
      return;
    }

    setState(() => _isSearching = false);
    final error = ref.read(mapProvider).errorMessage;
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    context.goNamed(AppRouteNames.map);
  }

  Future<void> _continueWithInterests() async {
    final selected = ref.read(interestsProvider);
    if (selected.isEmpty) {
      context.goNamed(AppRouteNames.home);
      return;
    }

    await _searchAndOpenMap(selected.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedInterests = ref.watch(interestsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        padding: AppResponsive.value<EdgeInsets>(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige tu\nsendero de búsqueda.',
              style: theme.textTheme.displayLarge?.copyWith(height: 1.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Cada selección ayuda a Ara a encontrar lugares que calcen con tu forma de viajar.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            if (_errorMessage != null) ...[
              AppFeedbackBanner(
                message: _errorMessage!,
                type: AppFeedbackType.error,
                onDismiss: () => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 16),
            ],
            VibeCard(
              category: 'Naturaleza y silencio',
              title: 'Bosques, cascadas y senderos tranquilos',
              imagePath:
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e',
              onTap: () => _searchAndOpenMap(
                'bosque nativo cascadas senderismo silencio naturaleza',
              ),
            ),
            VibeCard(
              category: 'Aventura volcánica',
              title: 'Volcanes, miradores y energía outdoor',
              imagePath:
                  'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
              onTap: () => _searchAndOpenMap(
                'volcan mirador aventura trekking nieve naturaleza',
              ),
            ),
            VibeCard(
              category: 'Cultura viva',
              title: 'Gastronomía, artesanía e historia local',
              imagePath:
                  'https://images.unsplash.com/photo-1505330622279-bf7d7fc918f4',
              onTap: () => _searchAndOpenMap(
                'cultura mapuche gastronomía artesanía historia turismo',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Refina tu búsqueda',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'Selecciona etiquetas y Ruta Viva hará una búsqueda semántica real con esos intereses.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const InterestsSelector(),
            const SizedBox(height: 24),
            if (_selectedVibeQuery != null)
              Text(
                'Última búsqueda: $_selectedVibeQuery',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 24),
            CustomButton(
              text: selectedInterests.isEmpty
                  ? 'Continuar al inicio'
                  : 'Buscar ${selectedInterests.length} intereses en mapa',
              isLoading: _isSearching,
              onPressed: _continueWithInterests,
            ),
          ],
        ),
      ),
    );
  }
}
