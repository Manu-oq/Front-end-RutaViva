import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';

class AIInputBar extends StatelessWidget {
  const AIInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "¿A dónde quiere ir tu corazón?",
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
