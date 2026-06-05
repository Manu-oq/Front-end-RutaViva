import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../../core/widgets/skeleton_container.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

class ReviewsSection extends ConsumerStatefulWidget {
  final String poiId;

  const ReviewsSection({super.key, required this.poiId});

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  String? _feedbackMessage;
  AppFeedbackType _feedbackType = AppFeedbackType.error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final text = _controller.text.trim();
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .create(poiId: widget.poiId, ratingStars: _rating, textContent: text);
      _refreshReviews();
      _controller.clear();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Opinión enviada. Gracias por ayudar a otros viajeros.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo publicar la opinión.';
      _showFeedback(message, AppFeedbackType.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _editReview(ReviewModel review) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (context) => _ReviewEditDialog(review: review),
    );
    if (draft == null) {
      return;
    }

    try {
      await ref
          .read(reviewRepositoryProvider)
          .update(
            reviewId: review.id,
            ratingStars: draft.ratingStars,
            textContent: draft.textContent,
          );
      _refreshReviews();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opinión actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo actualizar la opinión.';
      _showFeedback(message, AppFeedbackType.error);
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar opinión'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(reviewRepositoryProvider).delete(review.id);
      _refreshReviews();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opinión eliminada.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo eliminar la opinión.';
      _showFeedback(message, AppFeedbackType.error);
    }
  }

  void _refreshReviews() {
    ref.invalidate(reviewsByPoiProvider(widget.poiId));
    ref.invalidate(reviewSummaryByPoiProvider(widget.poiId));
  }

  void _showFeedback(String message, AppFeedbackType type) {
    setState(() {
      _feedbackMessage = message;
      _feedbackType = type;
    });
  }

  void _dismissFeedback() {
    setState(() => _feedbackMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = ref.watch(reviewsByPoiProvider(widget.poiId));
    final summary = ref.watch(reviewSummaryByPoiProvider(widget.poiId));
    final currentUserId = ref.watch(authProvider).user?.id;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_feedbackMessage != null) ...[
            AppFeedbackBanner(
              message: _feedbackMessage!,
              type: _feedbackType,
              onDismiss: _dismissFeedback,
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'Comparte tu experiencia y revisa lo que otros viajeros recomiendan antes de ir.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          summary.when(
            data: (value) => _ReviewSummaryCard(summary: value),
            loading: () => const SkeletonContainer(height: 154),
            error: (error, stackTrace) => InlineErrorWidget(
              message: 'No se pudo cargar el resumen de opiniones.',
              onRetry: _refreshReviews,
            ),
          ),
          const SizedBox(height: 14),
          reviews.when(
            data: (items) {
              final ownReview = _findOwnReview(items, currentUserId);
              if (items.isEmpty) {
                return Column(
                  children: [
                    _ReviewForm(
                      controller: _controller,
                      rating: _rating,
                      isSubmitting: _isSubmitting,
                      onRatingChanged: (value) =>
                          setState(() => _rating = value),
                      onSubmit: _submitReview,
                    ),
                    const SizedBox(height: 18),
                    const _EmptyReviewsCard(),
                  ],
                );
              }

              return Column(
                children: [
                  if (ownReview == null) ...[
                    _ReviewForm(
                      controller: _controller,
                      rating: _rating,
                      isSubmitting: _isSubmitting,
                      onRatingChanged: (value) =>
                          setState(() => _rating = value),
                      onSubmit: _submitReview,
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    _OwnReviewNotice(onEdit: () => _editReview(ownReview)),
                    const SizedBox(height: 14),
                  ],
                  ...items.map((review) {
                    final canManage = review.touristId == currentUserId;
                    return _ReviewTile(
                      review: review,
                      canManage: canManage,
                      onEdit: () => _editReview(review),
                      onDelete: () => _deleteReview(review),
                    );
                  }),
                ],
              );
            },
            loading: () => Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                  child: const SkeletonContainer(height: 104),
                ),
              ),
            ),
            error: (error, stackTrace) => InlineErrorWidget(
              message: 'No se pudieron cargar las opiniones.',
              onRetry: _refreshReviews,
            ),
          ),
        ],
      ),
    );
  }

  ReviewModel? _findOwnReview(List<ReviewModel> items, String? currentUserId) {
    if (currentUserId == null) return null;
    for (final review in items) {
      if (review.touristId == currentUserId) return review;
    }
    return null;
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final ReviewSummaryModel summary;

  const _ReviewSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = summary.averageRating.toStringAsFixed(1);
    final total = summary.totalReviews;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            AppColors.sun.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 520;
          final ratingHeader = _RatingHeader(average: average, total: total);
          final distribution = Column(
            children: [
              for (var star = 5; star >= 1; star--)
                _RatingDistributionRow(
                  star: star,
                  count: summary.ratingDistribution[star] ?? 0,
                  total: total,
                ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 4, child: ratingHeader),
                const SizedBox(width: 22),
                Expanded(flex: 6, child: distribution),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ratingHeader, const SizedBox(height: 16), distribution],
          );
        },
      ),
    );
  }
}

class _RatingHeader extends StatelessWidget {
  final String average;
  final int total;

  const _RatingHeader({required this.average, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.sun.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: AppColors.earth,
            size: 34,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                total == 1 ? '1 opinión' : '$total opiniones',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RatingDistributionRow extends StatelessWidget {
  final int star;
  final int count;
  final int total;

  const _RatingDistributionRow({
    required this.star,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '$star ★',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.outlineVariant,
                color: AppColors.sun,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final TextEditingController controller;
  final int rating;
  final bool isSubmitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _ReviewForm({
    required this.controller,
    required this.rating,
    required this.isSubmitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.24,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deja tu opinión',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu comentario ayuda a otros viajeros a decidir mejor.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _RatingPicker(
            rating: rating,
            enabled: !isSubmitting,
            onChanged: onRatingChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !isSubmitting,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'Comentario opcional: cuenta qué te gustó o qué deberían saber antes de ir...',
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(isSubmitting ? 'Enviando...' : 'Enviar opinión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnReviewNotice extends StatelessWidget {
  final VoidCallback onEdit;

  const _OwnReviewNotice({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ya dejaste una opinión para este lugar. Si cambiaste de idea, puedes editarla.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Editar')),
        ],
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final int rating;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _RatingPicker({
    required this.rating,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFC857)
        : AppColors.sun;
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Wrap(
      spacing: 4,
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton.filledTonal(
          onPressed: enabled ? () => onChanged(value) : null,
          icon: Icon(
            value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: value <= rating ? selectedColor : unselectedColor,
          ),
          tooltip: '$value estrellas',
        );
      }),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            canManage
                                ? 'Tu opinión'
                                : review.authorName ?? 'Viajero Ruta Viva',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _shortDate(review.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(children: [_Stars(value: review.ratingStars)]),
                    if (review.textContent.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.textContent,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 4),
                PopupMenuButton<_ReviewAction>(
                  tooltip: 'Opciones de opinión',
                  onSelected: (action) {
                    switch (action) {
                      case _ReviewAction.edit:
                        onEdit();
                        break;
                      case _ReviewAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ReviewAction.edit,
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: _ReviewAction.delete,
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _Stars extends StatelessWidget {
  final int value;

  const _Stars({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFC857)
        : AppColors.sun;
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < value ? Icons.star_rounded : Icons.star_border_rounded,
          size: 17,
          color: index < value ? selectedColor : unselectedColor,
          shadows: const [
            Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 1)),
          ],
        );
      }),
    );
  }
}

class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.rate_review_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aún no hay opiniones. Sé la primera persona en contar cómo fue la experiencia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ReviewAction { edit, delete }

class _ReviewDraft {
  final int ratingStars;
  final String textContent;

  const _ReviewDraft({required this.ratingStars, required this.textContent});
}

class _ReviewEditDialog extends StatefulWidget {
  final ReviewModel review;

  const _ReviewEditDialog({required this.review});

  @override
  State<_ReviewEditDialog> createState() => _ReviewEditDialogState();
}

class _ReviewEditDialogState extends State<_ReviewEditDialog> {
  late final TextEditingController _controller;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.review.textContent);
    _rating = widget.review.ratingStars;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar opinión'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RatingPicker(
              rating: _rating,
              enabled: true,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Actualiza tu experiencia...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            Navigator.of(
              context,
            ).pop(_ReviewDraft(ratingStars: _rating, textContent: text));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
