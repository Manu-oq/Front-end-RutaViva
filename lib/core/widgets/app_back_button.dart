import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

class AppBackButton extends StatelessWidget {
  final String fallbackRouteName;
  final Map<String, String> fallbackPathParameters;
  final Color? color;
  final String? tooltip;
  final bool usePop;

  const AppBackButton({
    super.key,
    this.fallbackRouteName = AppRouteNames.home,
    this.fallbackPathParameters = const {},
    this.color,
    this.tooltip,
    this.usePop = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip ?? 'Volver',
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () {
        if (usePop && context.canPop()) {
          context.pop();
          return;
        }

        context.goNamed(
          fallbackRouteName,
          pathParameters: fallbackPathParameters,
        );
      },
    );
  }
}
