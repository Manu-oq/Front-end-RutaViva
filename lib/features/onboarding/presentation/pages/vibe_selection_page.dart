import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../widgets/vibe_card.dart';
import '../widgets/interests_selector.dart';

class VibeSelectionPage extends StatelessWidget {
  const VibeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Elige tu\nsendero espiritual.",
              style: theme.textTheme.displayLarge?.copyWith(height: 1.1),
            ),
            const SizedBox(height: 16),
            Text(
              "Más allá del mapa está el sentir. Selecciona la energía que llama a tu alma hoy.",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),

            VibeCard(
              category: "El sendero silencioso",
              title: "Silencio de los Bosques Antiguos",
              imagePath:
                  "https://images.unsplash.com/photo-1441974231531-c6227db76b6e",
              onTap: () {},
            ),
            VibeCard(
              category: "Energía Primordial",
              title: "Poder del Volcán",
              imagePath:
                  "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b",
              onTap: () {},
            ),
            VibeCard(
              category: "Cultura Mapuche",
              title: "Sabiduría Ancestral",
              imagePath:
                  "https://images.unsplash.com/photo-1505330622279-bf7d7fc918f4",
              onTap: () {},
            ),

            const SizedBox(height: 32),

            Text(
              "Refina tu búsqueda",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              "¿Qué te apasiona? Selecciona etiquetas para que Ara pueda personalizar tu ruta con mayor precisión.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            const InterestsSelector(),

            const SizedBox(height: 40),

            Center(
              child: Text(
                "Selecciona uno o más para comenzar tu curación.",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: "Continuar mi viaje",
              onPressed: () {
                context.goNamed(AppRouteNames.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
