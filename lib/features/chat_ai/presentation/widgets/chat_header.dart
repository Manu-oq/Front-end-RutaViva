import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_back_button.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const AppBackButton(fallbackRouteName: AppRouteNames.home),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ara Assistant',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                Text(
                  'Tu guía para rutas e ideas de viaje',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.outlined(
            tooltip: 'Mis rutas',
            onPressed: () => context.goNamed(AppRouteNames.itineraryHistory),
            icon: const Icon(Icons.route_outlined),
          ),
        ],
      ),
    );
  }
}
