import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AccountSettings extends ConsumerWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CONFIGURACIÓN', style: theme.textTheme.labelLarge),
          const SizedBox(height: 16),
          _SettingTile(
            icon: Icons.person_outline,
            title: 'Editar perfil',
            onTap: () => context.pushNamed(AppRouteNames.editProfile),
          ),
          _SettingTile(
            icon: Icons.route_outlined,
            title: 'Mis itinerarios',
            onTap: () => context.pushNamed(AppRouteNames.itineraryHistory),
          ),
          _SettingTile(
            icon: Icons.bookmark_border,
            title: 'Favoritos',
            onTap: () => context.pushNamed(AppRouteNames.bookmarks),
          ),
          _SettingTile(
            icon: Icons.add_location_alt_outlined,
            title: 'Crear POI',
            onTap: () => context.pushNamed(AppRouteNames.createPoi),
          ),
          _SettingTile(
            icon: Icons.storefront_outlined,
            title: 'Panel emprendedor',
            onTap: () => context.pushNamed(AppRouteNames.entrepreneur),
          ),
          const Divider(height: 32),
          _SettingTile(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            isDestructive: true,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) {
                return;
              }
              context.goNamed(AppRouteNames.login);
            },
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
