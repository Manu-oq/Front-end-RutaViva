import 'package:flutter/material.dart';
import '../../../categories/presentation/category_style.dart';
import '../../domain/entities/message_entity.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isTyping;
  final String? evidenceLevel;
  final List<MessageAction> actions;
  final MessageItineraryCard? itineraryCard;
  final List<MessageCandidatePoi> candidatePois;
  final String? selectedActionId;
  final bool actionsLocked;
  final ValueChanged<MessageAction>? onAction;
  final ValueChanged<String>? onOpenItinerary;
  final ValueChanged<MessageCandidatePoi>? onOpenPoi;
  final ValueChanged<MessageCandidatePoi>? onShowPoiOnMap;
  final ValueChanged<MessageCandidatePoi>? onUseCandidate;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isTyping = false,
    this.evidenceLevel,
    this.actions = const [],
    this.itineraryCard,
    this.candidatePois = const [],
    this.selectedActionId,
    this.actionsLocked = false,
    this.onAction,
    this.onOpenItinerary,
    this.onOpenPoi,
    this.onShowPoiOnMap,
    this.onUseCandidate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 24),
          ),
          boxShadow: isUser
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTyping)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: _BubbleText(message: message, isUser: isUser),
                  ),
                ],
              )
            else
              _BubbleText(message: message, isUser: isUser),
            if (!isUser && evidenceLevel == 'inferred') ...[
              const SizedBox(height: 10),
              _EvidencePill(label: 'Recomendación estimada'),
            ],
            if (itineraryCard != null) ...[
              const SizedBox(height: 14),
              _ItineraryChatCard(
                card: itineraryCard!,
                onOpen: () => onOpenItinerary?.call(itineraryCard!.id),
              ),
            ],
            if (candidatePois.isNotEmpty) ...[
              const SizedBox(height: 14),
              _CandidatePoiList(
                candidates: candidatePois,
                actionsLocked: actionsLocked,
                onOpenPoi: onOpenPoi,
                onShowPoiOnMap: onShowPoiOnMap,
                onUseCandidate: onUseCandidate,
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map(
                      (action) => ActionChip(
                        label: Text(action.label),
                        avatar: _isSelected(action)
                            ? const Icon(Icons.check_rounded, size: 16)
                            : null,
                        onPressed: actionsLocked || onAction == null
                            ? null
                            : () => onAction!(action),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSelected(MessageAction action) {
    final selected = selectedActionId;
    if (selected == null || selected.isEmpty) {
      return false;
    }
    final id = action.id.trim();
    if (id.isNotEmpty) {
      return selected == id;
    }
    return selected == action.prompt;
  }
}

class _CandidatePoiList extends StatefulWidget {
  final List<MessageCandidatePoi> candidates;
  final bool actionsLocked;
  final ValueChanged<MessageCandidatePoi>? onOpenPoi;
  final ValueChanged<MessageCandidatePoi>? onShowPoiOnMap;
  final ValueChanged<MessageCandidatePoi>? onUseCandidate;

  const _CandidatePoiList({
    required this.candidates,
    required this.actionsLocked,
    this.onOpenPoi,
    this.onShowPoiOnMap,
    this.onUseCandidate,
  });

  @override
  State<_CandidatePoiList> createState() => _CandidatePoiListState();
}

class _CandidatePoiListState extends State<_CandidatePoiList> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = widget.candidates.take(3).toList(growable: false);
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.local_activity_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.candidates.length == 1
                          ? '1 opción recomendada'
                          : '${visible.length} opciones recomendadas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (widget.candidates.length > visible.length)
                    Text(
                      '${visible.length}/${widget.candidates.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _CandidatePoiCard(
                    candidate: visible[index],
                    actionsLocked: widget.actionsLocked,
                    onOpenPoi: widget.onOpenPoi,
                    onShowPoiOnMap: widget.onShowPoiOnMap,
                    onUseCandidate: widget.onUseCandidate,
                  ),
                  if (index != visible.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOut,
        ),
        if (!_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _CandidatePoiCompactPreview(
              candidate: visible.first,
              actionsLocked: widget.actionsLocked,
              onOpenPoi: widget.onOpenPoi,
              onShowPoiOnMap: widget.onShowPoiOnMap,
              onUseCandidate: widget.onUseCandidate,
            ),
          ),
      ],
    );
  }
}

class _CandidatePoiCompactPreview extends StatelessWidget {
  final MessageCandidatePoi candidate;
  final bool actionsLocked;
  final ValueChanged<MessageCandidatePoi>? onOpenPoi;
  final ValueChanged<MessageCandidatePoi>? onShowPoiOnMap;
  final ValueChanged<MessageCandidatePoi>? onUseCandidate;

  const _CandidatePoiCompactPreview({
    required this.candidate,
    required this.actionsLocked,
    this.onOpenPoi,
    this.onShowPoiOnMap,
    this.onUseCandidate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = categoryStyleFor(
      candidate.categoryIds.isEmpty ? null : candidate.categoryIds.first,
      theme.colorScheme,
    );
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: actionsLocked || onUseCandidate == null
            ? null
            : () => onUseCandidate!(candidate),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(style.icon, color: style.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  candidate.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Detalle',
                visualDensity: VisualDensity.compact,
                onPressed: onOpenPoi == null
                    ? null
                    : () => onOpenPoi!(candidate),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
              ),
              if (candidate.hasCoordinates)
                IconButton(
                  tooltip: 'Mapa',
                  visualDensity: VisualDensity.compact,
                  onPressed: onShowPoiOnMap == null
                      ? null
                      : () => onShowPoiOnMap!(candidate),
                  icon: const Icon(Icons.map_rounded, size: 18),
                ),
              IconButton(
                tooltip: 'Elegir',
                visualDensity: VisualDensity.compact,
                onPressed: actionsLocked || onUseCandidate == null
                    ? null
                    : () => onUseCandidate!(candidate),
                icon: const Icon(Icons.touch_app_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidatePoiCard extends StatelessWidget {
  final MessageCandidatePoi candidate;
  final bool actionsLocked;
  final ValueChanged<MessageCandidatePoi>? onOpenPoi;
  final ValueChanged<MessageCandidatePoi>? onShowPoiOnMap;
  final ValueChanged<MessageCandidatePoi>? onUseCandidate;

  const _CandidatePoiCard({
    required this.candidate,
    required this.actionsLocked,
    this.onOpenPoi,
    this.onShowPoiOnMap,
    this.onUseCandidate,
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
        onTap: actionsLocked || onUseCandidate == null
            ? null
            : () => onUseCandidate!(candidate),
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: actionsLocked || onUseCandidate == null
                              ? null
                              : () => onUseCandidate!(candidate),
                          icon: const Icon(Icons.touch_app_rounded, size: 16),
                          label: Text(
                            candidate.actionValue?.trim().isNotEmpty == true
                                ? 'Usar'
                                : 'Elegir',
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onOpenPoi == null
                              ? null
                              : () => onOpenPoi!(candidate),
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                          ),
                          label: const Text('Detalle'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              !candidate.hasCoordinates ||
                                  onShowPoiOnMap == null
                              ? null
                              : () => onShowPoiOnMap!(candidate),
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Mapa'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
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
      6 => 'Trekking',
      7 => 'Lagos y ríos',
      8 => 'Miradores',
      9 => 'Termas',
      10 => 'Parques',
      11 => 'Patrimonio',
      12 => 'Aventura',
      13 => 'Servicios',
      14 => 'Transporte',
      15 => 'Artesanía',
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
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
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
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidencePill extends StatelessWidget {
  final String label;

  const _EvidencePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.tertiary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItineraryChatCard extends StatelessWidget {
  final MessageItineraryCard card;
  final VoidCallback onOpen;

  const _ItineraryChatCard({required this.card, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.route_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('${card.stepsCount} paradas sugeridas'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleText extends StatelessWidget {
  final String message;
  final bool isUser;

  const _BubbleText({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        height: 1.4,
      ),
    );
  }
}
