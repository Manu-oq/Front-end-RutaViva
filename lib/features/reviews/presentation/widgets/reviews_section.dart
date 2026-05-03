import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) {
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
            'Review enviada. Ara actualizará tu perfil en segundo plano.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo crear la review.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
        const SnackBar(content: Text('Review actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo actualizar la review.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar review'),
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
      ).showSnackBar(const SnackBar(content: Text('Review eliminada.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo eliminar la review.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _refreshReviews() {
    ref.invalidate(reviewsByPoiProvider(widget.poiId));
    ref.invalidate(reviewSummaryByPoiProvider(widget.poiId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = ref.watch(reviewsByPoiProvider(widget.poiId));
    final summary = ref.watch(reviewSummaryByPoiProvider(widget.poiId));
    final currentUserId = ref.watch(authProvider).user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 12),
        summary.when(
          data: (value) => _ReviewSummaryCard(summary: value),
          loading: () => SkeletonContainer(height: 140),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                Text(
                  'No se pudo cargar el resumen de reviews.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => _refreshReviews(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ReviewForm(
          controller: _controller,
          rating: _rating,
          isSubmitting: _isSubmitting,
          onRatingChanged: (value) => setState(() => _rating = value),
          onSubmit: _submitReview,
        ),
        const SizedBox(height: 24),
        reviews.when(
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'Aún no hay opiniones para este lugar.',
                style: theme.textTheme.bodyMedium,
              );
            }

            return Column(
              children: items.map((review) {
                final canManage = review.touristId == currentUserId;
                return _ReviewTile(
                  review: review,
                  canManage: canManage,
                  onEdit: () => _editReview(review),
                  onDelete: () => _deleteReview(review),
                );
              }).toList(),
            );
          },
          loading: () => Column(
            children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonContainer(height: 80),
            )),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Text(
                  'No se pudieron cargar las reviews.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: () => _refreshReviews(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final ReviewSummaryModel summary;

  const _ReviewSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text('${summary.totalReviews} reviews'),
            ],
          ),
          const SizedBox(height: 12),
          for (var star = 5; star >= 1; star--)
            _RatingDistributionRow(
              star: star,
              count: summary.ratingDistribution[star] ?? 0,
              total: summary.totalReviews,
            ),
        ],
      ),
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
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$star★')),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: Colors.black12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 24, child: Text('$count')),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: isSubmitting ? null : () => onRatingChanged(value),
                icon: Icon(
                  value <= rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: controller,
            enabled: !isSubmitting,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Comparte tu experiencia y ayuda a personalizar tus rutas...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(isSubmitting ? 'Enviando...' : 'Enviar review'),
            ),
          ),
        ],
      ),
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
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < review.ratingStars ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                );
              }),
              const Spacer(),
              Text(
                _shortDate(review.createdAt),
                style: theme.textTheme.labelSmall,
              ),
              if (canManage) ...[
                const SizedBox(width: 4),
                PopupMenuButton<_ReviewAction>(
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
          const SizedBox(height: 8),
          Text(review.textContent, style: theme.textTheme.bodyMedium),
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
      title: const Text('Editar review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(border: OutlineInputBorder()),
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
            if (text.isEmpty) {
              return;
            }
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
