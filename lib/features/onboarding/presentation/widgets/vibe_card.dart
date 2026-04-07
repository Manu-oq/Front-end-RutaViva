import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VibeCard extends StatelessWidget {
  final String category;
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const VibeCard({
    super.key,
    required this.category,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 400,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: DecorationImage(
            image: NetworkImage(imagePath), 
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.volcanicObsidian.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white.withValues(alpha: 0.2), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.toUpperCase(), style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(title, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}