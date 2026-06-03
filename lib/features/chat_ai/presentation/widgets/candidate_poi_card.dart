import 'package:flutter/material.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../categories/presentation/category_style.dart';
import '../../domain/entities/message_entity.dart';

class CandidatePoiCard extends StatelessWidget {
  final MessageCandidatePoi candidate;
  final bool actionsLocked;
  final ValueChanged<MessageCandidatePoi>? onOpenPoi;
  final ValueChanged<MessageCandidatePoi>? onShowPoiOnMap;
  final ValueChanged<MessageCandidatePoi>? onUseCandidate;
  final int? currentDayFocus;

  const CandidatePoiCard({
    super.key,
    required this.candidate,
    required this.actionsLocked,
    this.onOpenPoi,
    this.onShowPoiOnMap,
    this.onUseCandidate,
    this.currentDayFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = categoryStyleFor(
      candidate.categoryIds.isEmpty ? null : candidate.categoryIds.first,
      theme.colorScheme,
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenPoi == null ? null : () => onOpenPoi!(candidate),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CandidatePoiImage(candidate: candidate, color: style.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      candidate.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _CandidateMetaPill(
                          icon: style.icon,
                          label: _categoryLabel(candidate.categoryIds),
                          color: style.color,
                        ),
                        if (candidate.distanceMeters != null)
                          _CandidateMetaPill(
                            icon: Icons.near_me_rounded,
                            label: _distanceLabel(candidate.distanceMeters!),
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: actionsLocked || onUseCandidate == null
                                ? null
                                : () => onUseCandidate!(candidate),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              _candidatePrimaryActionLabel(currentDayFocus),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _CandidateSecondaryMenu(
                          candidate: candidate,
                          onOpenPoi: onOpenPoi,
                          onShowPoiOnMap: onShowPoiOnMap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(List<int> ids) {
    if (ids.isEmpty) return 'Lugar';
    return switch (ids.first) {
      1 => 'Naturaleza',
      2 => 'Gastronomía',
      3 => 'Turismo',
      4 => 'Alojamiento',
      5 => 'Cultura',
      6 => 'Trekking/Senderismo',
      7 => 'Lagos/Ríos/Playas',
      8 => 'Montañas/Volcanes/Miradores',
      9 => 'Termas/Bienestar',
      10 => 'Parques/Reservas',
      11 => 'Museos/Patrimonio',
      12 => 'Aventura/Deportes',
      13 => 'Servicios turísticos/Información',
      14 => 'Transporte/Accesos',
      15 => 'Artesanía/Compras locales',
      _ => 'Lugar',
    };
  }

  String _distanceLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _CandidateSecondaryMenu extends StatelessWidget {
  final MessageCandidatePoi candidate;
  final ValueChanged<MessageCandidatePoi>? onOpenPoi;
  final ValueChanged<MessageCandidatePoi>? onShowPoiOnMap;

  const _CandidateSecondaryMenu({
    required this.candidate,
    this.onOpenPoi,
    this.onShowPoiOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CandidateSecondaryAction>(
      tooltip: 'Más opciones',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        switch (action) {
          case _CandidateSecondaryAction.detail:
            onOpenPoi?.call(candidate);
          case _CandidateSecondaryAction.map:
            onShowPoiOnMap?.call(candidate);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CandidateSecondaryAction.detail,
          enabled: onOpenPoi != null,
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18),
              SizedBox(width: 8),
              Text('Ver detalle'),
            ],
          ),
        ),
        if (candidate.hasCoordinates)
          PopupMenuItem(
            value: _CandidateSecondaryAction.map,
            enabled: onShowPoiOnMap != null,
            child: const Row(
              children: [
                Icon(Icons.map_rounded, size: 18),
                SizedBox(width: 8),
                Text('Ver en mapa'),
              ],
            ),
          ),
      ],
    );
  }
}

enum _CandidateSecondaryAction { detail, map }

String _candidatePrimaryActionLabel(int? currentDayFocus) {
  final day = currentDayFocus;
  if (day != null && day > 0) return 'Agregar al Día $day';
  return 'Agregar al itinerario';
}

class _CandidatePoiImage extends StatelessWidget {
  final MessageCandidatePoi candidate;
  final Color color;

  const _CandidatePoiImage({required this.candidate, required this.color});

  @override
  Widget build(BuildContext context) {
    final imageUrl = candidate.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 62,
        height: 62,
        color: color.withValues(alpha: 0.14),
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(Icons.place_rounded, color: color, size: 30)
            : AuthenticatedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context) =>
                    Icon(Icons.place_rounded, color: color, size: 30),
              ),
      ),
    );
  }
}

class _CandidateMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CandidateMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
