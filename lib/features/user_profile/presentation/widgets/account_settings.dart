import 'package:flutter/material.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CONFIGURACIÓN", style: theme.textTheme.labelLarge),
          const SizedBox(height: 16),
          const _SettingTile(
            icon: Icons.person_outline,
            title: "Editar Perfil",
          ),
          const _SettingTile(
            icon: Icons.email_outlined,
            title: "Cambiar Correo",
          ),
          const _SettingTile(
            icon: Icons.notifications_none,
            title: "Notificaciones",
          ),
          const _SettingTile(
            icon: Icons.security,
            title: "Privacidad y Seguridad",
          ),
          const Divider(height: 32),
          const _SettingTile(
            icon: Icons.logout,
            title: "Cerrar Sesión",
            isDestructive: true,
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

  const _SettingTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
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
      onTap: () {},
    );
  }
}
