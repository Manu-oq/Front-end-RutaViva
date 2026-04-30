import 'package:flutter/material.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ara Assistant",
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
              Row(
                children: [
                  Text("SEÑAL 98%", style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.sensors,
                    size: 12,
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=ara'),
          ),
        ],
      ),
    );
  }
}
