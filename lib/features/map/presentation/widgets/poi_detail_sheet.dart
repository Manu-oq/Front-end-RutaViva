import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../domain/entities/map_point.dart';

class PoiDetailSheet extends ConsumerWidget {
  final MapPoint point;
  const PoiDetailSheet({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = ref.watch(categoriesByIdProvider);
    final hasImage = point.imageUrl != null &&
        point.imageUrl!.isNotEmpty &&
        (point.imageUrl!.startsWith('http') ||
            point.imageUrl!.startsWith('https') ||
            point.imageUrl!.startsWith('/'));

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: AppColors.liftedShadow,
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasImage
                          ? AuthenticatedNetworkImage(
                              imageUrl: point.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_) => const _SheetImageFallback(),
                            )
                          : const _SheetImageFallback(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.48),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SheetPill(
                              label: point.categoryLabel(names).toUpperCase(),
                            ),
                            if (point.distanceMeters != null)
                              _SheetPill(
                                label:
                                    '${(point.distanceMeters! / 1000).toStringAsFixed(1)} km',
                                icon: Icons.near_me_outlined,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(point.name, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(
                point.description ??
                    'Un lugar por descubrir. Visítalo para conocer su historia de primera mano.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: point.description == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final rootContext = Navigator.of(
                          context,
                          rootNavigator: true,
                        ).context;
                        context.pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!rootContext.mounted) {
                            return;
                          }
                          rootContext.pushNamedSafe(
                            AppRouteNames.poiDetail,
                            pathParameters: {'id': point.id},
                          );
                        });
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Ver detalle'),
                    ),
                  ),
                  if (point.phone != null) ...[
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Llamar',
                      onPressed: () =>
                          UrlLauncherHelper.launchPhone(context, point.phone!),
                      icon: const Icon(Icons.phone_outlined),
                    ),
                  ],
                  if (point.email != null) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Enviar correo',
                      onPressed: () => UrlLauncherHelper.launchEmail(
                        context,
                        point.email!,
                        subject: 'Consulta desde Ruta Viva',
                      ),
                      icon: const Icon(Icons.email_outlined),
                    ),
                  ],
                ],
              ),
              if (point.phone == null && point.email == null) ...[
                const SizedBox(height: 14),
                Text(
                  'Este lugar no tiene contacto publicado todavía.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SheetPill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _SheetPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetImageFallback extends StatelessWidget {
  const _SheetImageFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.landscape_outlined, size: 64, color: Colors.white70),
      ),
    );
  }
}
