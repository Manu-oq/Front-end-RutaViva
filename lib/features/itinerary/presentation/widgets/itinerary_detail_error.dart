import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_colors.dart';

class ItineraryDetailError extends StatelessWidget {
  final Object error;

  const ItineraryDetailError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
        title: const Text('Itinerario'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.maxContentWidth(context),
          ),
          child: Padding(
            padding: AppResponsive.pagePadding(context),
            child: EmptyStateCard(
              icon: Icons.warning_amber_rounded,
              title: 'No se pudo cargar el itinerario',
              text: '$error',
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.primary,
            child: Icon(icon),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: isMobile
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: isMobile
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class NoItineraryState extends StatelessWidget {
  const NoItineraryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(
          fallbackRouteName: AppRouteNames.itineraryHistory,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.maxContentWidth(context),
          ),
          child: Padding(
            padding: AppResponsive.pagePadding(context),
            child: const EmptyStateCard(
              icon: Icons.route_outlined,
              title: 'Aún no hay una ruta generada',
              text:
                  'Escribe una intención desde Inicio o Ara Assistant para generar un itinerario.',
            ),
          ),
        ),
      ),
    );
  }
}
