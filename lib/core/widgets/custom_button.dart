import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;

  const CustomButton({
    super.key, 
    required this.text, 
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56, 
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
          elevation: 0,
          shape: const StadiumBorder(), 
        ),
        child: isLoading 
          ? const CircularProgressIndicator(strokeWidth: 2) 
          : Text(
              text, 
              style: theme.textTheme.labelLarge?.copyWith(
                color: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                fontSize: 16
              )
            ),
      ),
    );
  }
}