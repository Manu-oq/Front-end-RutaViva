import 'package:flutter/material.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  void _showEmergencyDialog(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("NÚMEROS DE EMERGENCIA", style: theme.textTheme.labelLarge),
            const SizedBox(height: 24),
            _buildEmergencyTile(
              context,
              "CONAF (Incendios)",
              "130",
              Icons.local_fire_department,
            ),
            _buildEmergencyTile(
              context,
              "Carabineros",
              "133",
              Icons.local_police,
            ),
            _buildEmergencyTile(
              context,
              "Ambulancia",
              "131",
              Icons.medical_services,
            ),
            const SizedBox(height: 20),
            Text(
              "Tu ubicación actual será compartida al llamar.",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTile(
    BuildContext context,
    String title,
    String number,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title),
      trailing: Text(
        number,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      elevation: 0,
      backgroundColor: Colors.redAccent.shade200,
      onPressed: () => _showEmergencyDialog(context),
      child: const Icon(Icons.sos, color: Colors.white),
    );
  }
}
